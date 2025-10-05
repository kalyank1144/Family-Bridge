import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'
import Stripe from 'stripe'

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')

    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey || !stripeSecretKey) {
      return new Response(JSON.stringify({ error: 'Missing environment configuration' }), { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
    }
    const accessToken = authHeader.replace('Bearer ', '')

    const admin = createClient(supabaseUrl, supabaseServiceRoleKey)

    const { data: userResp, error: userErr } = await admin.auth.getUser(accessToken)
    if (userErr || !userResp.user) {
      return new Response(JSON.stringify({ error: 'Invalid or expired token' }), { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
    }
    const user = userResp.user

    const stripe = new Stripe(stripeSecretKey, { apiVersion: '2023-10-16' })

    // Ensure user profile exists
    const { data: profile, error: profileErr } = await admin
      .from('user_profiles')
      .select('user_id, stripe_customer_id')
      .eq('user_id', user.id)
      .maybeSingle()

    if (profileErr) {
      return new Response(JSON.stringify({ error: 'Failed to fetch user profile' }), { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
    }

    let stripeCustomerId = profile?.stripe_customer_id as string | null

    if (!stripeCustomerId) {
      // Get additional user info for customer creation
      const { data: basic, error: basicErr } = await admin
        .from('users')
        .select('name')
        .eq('id', user.id)
        .maybeSingle()

      if (basicErr) {
        // non-fatal, proceed with defaults
      }

      const customer = await stripe.customers.create({
        email: user.email ?? undefined,
        name: (basic?.name as string | undefined) ?? undefined,
        metadata: {
          user_id: user.id
        }
      })

      stripeCustomerId = customer.id

      await admin
        .from('user_profiles')
        .upsert({
          user_id: user.id,
          stripe_customer_id: customer.id
        }, { onConflict: 'user_id' })
    }

    // Create setup intent to collect a new payment method
    const setupIntent = await stripe.setupIntents.create({
      customer: stripeCustomerId!,
      usage: 'off_session',
      payment_method_types: ['card']
    })

    return new Response(
      JSON.stringify({
        client_secret: setupIntent.client_secret,
        setup_intent_id: setupIntent.id,
        customer_id: stripeCustomerId
      }),
      { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    )
  } catch (error) {
    console.error('stripe-create-setup-intent error:', error)
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
  }
})
