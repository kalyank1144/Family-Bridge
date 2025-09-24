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
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')

    if (!supabaseUrl || !supabaseServiceRoleKey || !stripeSecretKey) {
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

    const body = await req.json().catch(() => ({}))
    const amount = Number(body.amount)
    if (!amount || amount <= 0) {
      return new Response(JSON.stringify({ error: 'Invalid amount' }), { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
    }

    // Ensure stripe customer exists
    const { data: profile } = await admin
      .from('user_profiles')
      .select('user_id, stripe_customer_id')
      .eq('user_id', user.id)
      .maybeSingle()

    let stripeCustomerId = profile?.stripe_customer_id as string | null
    if (!stripeCustomerId) {
      const customer = await stripe.customers.create({
        email: user.email ?? undefined,
        metadata: { user_id: user.id }
      })
      stripeCustomerId = customer.id
      await admin.from('user_profiles').upsert({ user_id: user.id, stripe_customer_id: customer.id }, { onConflict: 'user_id' })
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency: 'usd',
      customer: stripeCustomerId,
      automatic_payment_methods: { enabled: true },
      metadata: { source: 'family_bridge_app', user_id: user.id }
    })

    return new Response(JSON.stringify({
      id: paymentIntent.id,
      client_secret: paymentIntent.client_secret,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
      customer_id: stripeCustomerId
    }), { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
  } catch (error) {
    console.error('stripe-create-payment-intent error:', error)
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
  }
})
