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
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')!
    const defaultPriceId = Deno.env.get('STRIPE_PRICE_ID_PREMIUM')!

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

    const url = new URL(req.url)
    const body = req.method === 'POST' ? await req.json().catch(() => ({})) : {}
    const action = (url.searchParams.get('action') || body.action || 'status') as string

    // Ensure stripe customer exists
    const { data: profile } = await admin
      .from('user_profiles')
      .select('user_id, stripe_customer_id, stripe_subscription_id, subscription_status, trial_started_at, trial_ends_at, subscription_current_period_end')
      .eq('user_id', user.id)
      .maybeSingle()

    let stripeCustomerId = profile?.stripe_customer_id as string | null
    if (!stripeCustomerId) {
      const customer = await stripe.customers.create({ email: user.email ?? undefined, metadata: { user_id: user.id } })
      stripeCustomerId = customer.id
      await admin.from('user_profiles').upsert({ user_id: user.id, stripe_customer_id: customer.id }, { onConflict: 'user_id' })
    }

    if (action === 'create') {
      const priceId = (body.price_id as string) || defaultPriceId

      // Create subscription; assume default payment method is already saved
      const subscription = await stripe.subscriptions.create({
        customer: stripeCustomerId!,
        items: [{ price: priceId }],
        collection_method: 'charge_automatically',
        payment_behavior: 'allow_incomplete',
        expand: ['latest_invoice.payment_intent']
      })

      // Optimistically write subscription ID/status; webhook is source of truth
      await admin.from('user_profiles').update({
        stripe_subscription_id: subscription.id,
        subscription_status: subscription.status,
        subscription_current_period_end: subscription.current_period_end
          ? new Date(subscription.current_period_end * 1000).toISOString()
          : null
      }).eq('user_id', user.id)

      return new Response(JSON.stringify({
        subscription_id: subscription.id,
        status: subscription.status,
        latest_invoice_payment_intent_client_secret: (subscription.latest_invoice as any)?.payment_intent?.client_secret ?? null
      }), { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
    }

    if (action === 'cancel') {
      const subscriptionId = (body.subscription_id as string) || profile?.stripe_subscription_id
      if (!subscriptionId) {
        return new Response(JSON.stringify({ error: 'No subscription to cancel' }), { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
      }

      const cancelled = await stripe.subscriptions.cancel(subscriptionId as string)

      await admin.from('user_profiles').update({
        subscription_status: 'cancelled',
        stripe_subscription_id: cancelled.id
      }).eq('user_id', user.id)

      return new Response(JSON.stringify({ cancelled: true, subscription_id: cancelled.id }), { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
    }

    if (action === 'set_default_payment_method') {
      const paymentMethodId = body.payment_method_id as string
      if (!paymentMethodId) {
        return new Response(JSON.stringify({ error: 'payment_method_id required' }), { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
      }

      // Attach to customer
      await stripe.paymentMethods.attach(paymentMethodId, { customer: stripeCustomerId! })
      // Set as default
      await stripe.customers.update(stripeCustomerId!, {
        invoice_settings: { default_payment_method: paymentMethodId }
      })

      // Fetch PM to store card details
      const pm = await stripe.paymentMethods.retrieve(paymentMethodId)
      if (pm.type === 'card' && pm.card) {
        await admin.from('payment_methods').upsert({
          user_id: user.id,
          stripe_payment_method_id: pm.id,
          card_last_four: pm.card.last4 || null,
          card_brand: pm.card.brand || null,
          card_exp_month: pm.card.exp_month || null,
          card_exp_year: pm.card.exp_year || null,
          is_default: true,
          is_active: true
        }, { onConflict: 'stripe_payment_method_id' })
        // Mark others non-default
        await admin.from('payment_methods')
          .update({ is_default: false })
          .eq('user_id', user.id)
          .neq('stripe_payment_method_id', pm.id)
      }

      return new Response(JSON.stringify({ updated: true }), { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
    }

    // default: status
    const status = {
      stripe_customer_id: stripeCustomerId,
      stripe_subscription_id: profile?.stripe_subscription_id ?? null,
      subscription_status: profile?.subscription_status ?? 'trial',
      current_period_end: profile?.subscription_current_period_end ?? null,
      trial_started_at: (profile as any)?.trial_started_at ?? null,
      trial_ends_at: (profile as any)?.trial_ends_at ?? null
    }

    return new Response(JSON.stringify(status), { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
  } catch (error) {
    console.error('stripe-manage-subscription error:', error)
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } })
  }
})
