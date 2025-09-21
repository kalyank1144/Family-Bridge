import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.5'
import Stripe from 'https://esm.sh/stripe@13.11.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, stripe-signature',
}

interface Database {
  public: {
    Tables: {
      user_profiles: {
        Row: {
          id: string
          stripe_customer_id?: string
          stripe_subscription_id?: string
          subscription_status?: string
          subscription_current_period_end?: string
          trial_end_date?: string
        }
        Update: {
          stripe_customer_id?: string
          stripe_subscription_id?: string
          subscription_status?: string
          subscription_current_period_end?: string
          trial_end_date?: string
        }
      }
      subscription_events: {
        Insert: {
          user_id: string
          stripe_event_id: string
          event_type: string
          event_data: any
        }
      }
      billing_history: {
        Insert: {
          user_id: string
          stripe_invoice_id: string
          amount_paid: number
          status: string
          billing_reason: string
        }
      }
      failed_payment_attempts: {
        Insert: {
          user_id: string
          stripe_invoice_id: string
          failure_reason: string
          attempt_count: number
        }
      }
    }
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Stripe with secret key
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')
    const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!stripeSecretKey || !webhookSecret || !supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error('Missing required environment variables')
    }

    const stripe = new Stripe(stripeSecretKey, {
      apiVersion: '2023-10-16',
    })

    // Initialize Supabase client with service role key
    const supabase = createClient<Database>(supabaseUrl, supabaseServiceRoleKey)

    // Get the signature from headers
    const signature = req.headers.get('stripe-signature')
    if (!signature) {
      throw new Error('Missing stripe-signature header')
    }

    // Get the raw body
    const body = await req.text()

    // Verify the webhook signature
    let event: Stripe.Event
    try {
      event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
    } catch (err) {
      console.error('Webhook signature verification failed:', err)
      return new Response(`Webhook Error: ${err.message}`, { 
        status: 400,
        headers: corsHeaders 
      })
    }

    console.log('Processing Stripe webhook event:', event.type, event.id)

    // Process the event based on type
    let processedSuccessfully = false

    switch (event.type) {
      case 'customer.subscription.created':
        processedSuccessfully = await handleSubscriptionCreated(supabase, event)
        break

      case 'customer.subscription.updated':
        processedSuccessfully = await handleSubscriptionUpdated(supabase, event)
        break

      case 'customer.subscription.deleted':
        processedSuccessfully = await handleSubscriptionDeleted(supabase, event)
        break

      case 'invoice.payment_succeeded':
        processedSuccessfully = await handlePaymentSucceeded(supabase, event)
        break

      case 'invoice.payment_failed':
        processedSuccessfully = await handlePaymentFailed(supabase, event)
        break

      case 'customer.subscription.trial_will_end':
        processedSuccessfully = await handleTrialWillEnd(supabase, event)
        break

      case 'payment_method.attached':
        processedSuccessfully = await handlePaymentMethodAttached(supabase, event)
        break

      case 'payment_method.detached':
        processedSuccessfully = await handlePaymentMethodDetached(supabase, event)
        break

      default:
        console.log('Unhandled event type:', event.type)
        processedSuccessfully = true // Don't fail for unhandled events
    }

    // Log the event regardless of processing outcome
    await logWebhookEvent(supabase, event)

    if (!processedSuccessfully) {
      throw new Error(`Failed to process ${event.type} event`)
    }

    return new Response('Webhook processed successfully', { 
      status: 200,
      headers: corsHeaders 
    })

  } catch (error) {
    console.error('Webhook processing error:', error)
    return new Response(`Webhook Error: ${error.message}`, { 
      status: 500,
      headers: corsHeaders 
    })
  }
})

async function handleSubscriptionCreated(
  supabase: any,
  event: Stripe.Event
): Promise<boolean> {
  try {
    const subscription = event.data.object as Stripe.Subscription
    const customerId = subscription.customer as string

    // Find user by Stripe customer ID
    const { data: user, error: userError } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('stripe_customer_id', customerId)
      .single()

    if (userError) {
      console.error('Error finding user for subscription created:', userError)
      return false
    }

    // Update user subscription status
    const { error: updateError } = await supabase
      .from('user_profiles')
      .update({
        stripe_subscription_id: subscription.id,
        subscription_status: subscription.status,
        subscription_current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
      })
      .eq('id', user.id)

    if (updateError) {
      console.error('Error updating user subscription:', updateError)
      return false
    }

    console.log('Subscription created for user:', user.id)
    return true
  } catch (error) {
    console.error('Error handling subscription created:', error)
    return false
  }
}

async function handleSubscriptionUpdated(
  supabase: any,
  event: Stripe.Event
): Promise<boolean> {
  try {
    const subscription = event.data.object as Stripe.Subscription
    const customerId = subscription.customer as string

    // Find user by Stripe customer ID
    const { data: user, error: userError } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('stripe_customer_id', customerId)
      .single()

    if (userError) {
      console.error('Error finding user for subscription updated:', userError)
      return false
    }

    // Update user subscription details
    const { error: updateError } = await supabase
      .from('user_profiles')
      .update({
        subscription_status: subscription.status,
        subscription_current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
      })
      .eq('id', user.id)

    if (updateError) {
      console.error('Error updating user subscription:', updateError)
      return false
    }

    console.log('Subscription updated for user:', user.id)
    return true
  } catch (error) {
    console.error('Error handling subscription updated:', error)
    return false
  }
}

async function handleSubscriptionDeleted(
  supabase: any,
  event: Stripe.Event
): Promise<boolean> {
  try {
    const subscription = event.data.object as Stripe.Subscription
    const customerId = subscription.customer as string

    // Find user by Stripe customer ID
    const { data: user, error: userError } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('stripe_customer_id', customerId)
      .single()

    if (userError) {
      console.error('Error finding user for subscription deleted:', userError)
      return false
    }

    // Update user subscription status to cancelled
    const { error: updateError } = await supabase
      .from('user_profiles')
      .update({
        subscription_status: 'cancelled',
        stripe_subscription_id: null,
      })
      .eq('id', user.id)

    if (updateError) {
      console.error('Error updating user subscription:', updateError)
      return false
    }

    console.log('Subscription cancelled for user:', user.id)
    return true
  } catch (error) {
    console.error('Error handling subscription deleted:', error)
    return false
  }
}

async function handlePaymentSucceeded(
  supabase: any,
  event: Stripe.Event
): Promise<boolean> {
  try {
    const invoice = event.data.object as Stripe.Invoice
    const customerId = invoice.customer as string
    
    // Find user by Stripe customer ID
    const { data: user, error: userError } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('stripe_customer_id', customerId)
      .single()

    if (userError) {
      console.error('Error finding user for payment succeeded:', userError)
      return false
    }

    // Add to billing history
    const { error: billingError } = await supabase
      .from('billing_history')
      .insert({
        user_id: user.id,
        stripe_invoice_id: invoice.id,
        amount_paid: invoice.amount_paid / 100, // Convert from cents
        status: 'paid',
        billing_reason: invoice.billing_reason || 'subscription_cycle',
      })

    if (billingError) {
      console.error('Error adding billing history:', billingError)
      return false
    }

    // If this was a subscription payment, ensure user status is active
    if (invoice.subscription) {
      const { error: statusError } = await supabase
        .from('user_profiles')
        .update({ subscription_status: 'active' })
        .eq('id', user.id)

      if (statusError) {
        console.error('Error updating subscription status:', statusError)
        return false
      }
    }

    console.log('Payment succeeded for user:', user.id, 'Amount:', invoice.amount_paid / 100)
    return true
  } catch (error) {
    console.error('Error handling payment succeeded:', error)
    return false
  }
}

async function handlePaymentFailed(
  supabase: any,
  event: Stripe.Event
): Promise<boolean> {
  try {
    const invoice = event.data.object as Stripe.Invoice
    const customerId = invoice.customer as string
    
    // Find user by Stripe customer ID
    const { data: user, error: userError } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('stripe_customer_id', customerId)
      .single()

    if (userError) {
      console.error('Error finding user for payment failed:', userError)
      return false
    }

    // Get failure reason
    const failureReason = invoice.last_finalization_error?.message || 'Unknown payment failure'

    // Record failed payment attempt
    const { error: attemptError } = await supabase
      .from('failed_payment_attempts')
      .insert({
        user_id: user.id,
        stripe_invoice_id: invoice.id,
        failure_reason: failureReason,
        attempt_count: invoice.attempt_count || 1,
      })

    if (attemptError) {
      console.error('Error recording failed payment attempt:', attemptError)
    }

    // Update user subscription status if this is a subscription payment
    if (invoice.subscription) {
      const newStatus = invoice.attempt_count && invoice.attempt_count >= 3 ? 'cancelled' : 'past_due'
      
      const { error: statusError } = await supabase
        .from('user_profiles')
        .update({ subscription_status: newStatus })
        .eq('id', user.id)

      if (statusError) {
        console.error('Error updating subscription status:', statusError)
        return false
      }
    }

    console.log('Payment failed for user:', user.id, 'Reason:', failureReason)
    return true
  } catch (error) {
    console.error('Error handling payment failed:', error)
    return false
  }
}

async function handleTrialWillEnd(
  supabase: any,
  event: Stripe.Event
): Promise<boolean> {
  try {
    const subscription = event.data.object as Stripe.Subscription
    const customerId = subscription.customer as string

    // Find user by Stripe customer ID
    const { data: user, error: userError } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('stripe_customer_id', customerId)
      .single()

    if (userError) {
      console.error('Error finding user for trial will end:', userError)
      return false
    }

    // Update trial end date if needed
    if (subscription.trial_end) {
      const { error: updateError } = await supabase
        .from('user_profiles')
        .update({
          trial_end_date: new Date(subscription.trial_end * 1000).toISOString(),
        })
        .eq('id', user.id)

      if (updateError) {
        console.error('Error updating trial end date:', updateError)
      }
    }

    console.log('Trial will end for user:', user.id)
    return true
  } catch (error) {
    console.error('Error handling trial will end:', error)
    return false
  }
}

async function handlePaymentMethodAttached(
  supabase: any,
  event: Stripe.Event
): Promise<boolean> {
  try {
    const paymentMethod = event.data.object as Stripe.PaymentMethod
    const customerId = paymentMethod.customer as string

    if (!customerId) {
      console.log('Payment method attached but no customer ID')
      return true
    }

    // Find user by Stripe customer ID
    const { data: user, error: userError } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('stripe_customer_id', customerId)
      .single()

    if (userError) {
      console.error('Error finding user for payment method attached:', userError)
      return false
    }

    // Add payment method to database if it's a card
    if (paymentMethod.type === 'card' && paymentMethod.card) {
      const { error: pmError } = await supabase
        .from('payment_methods')
        .upsert({
          user_id: user.id,
          stripe_payment_method_id: paymentMethod.id,
          card_last_four: paymentMethod.card.last4,
          card_brand: paymentMethod.card.brand,
          is_default: false, // Will be updated separately if needed
        }, {
          onConflict: 'stripe_payment_method_id'
        })

      if (pmError) {
        console.error('Error saving payment method:', pmError)
        return false
      }
    }

    console.log('Payment method attached for user:', user.id)
    return true
  } catch (error) {
    console.error('Error handling payment method attached:', error)
    return false
  }
}

async function handlePaymentMethodDetached(
  supabase: any,
  event: Stripe.Event
): Promise<boolean> {
  try {
    const paymentMethod = event.data.object as Stripe.PaymentMethod

    // Remove payment method from database
    const { error: deleteError } = await supabase
      .from('payment_methods')
      .delete()
      .eq('stripe_payment_method_id', paymentMethod.id)

    if (deleteError) {
      console.error('Error removing payment method:', deleteError)
      return false
    }

    console.log('Payment method detached:', paymentMethod.id)
    return true
  } catch (error) {
    console.error('Error handling payment method detached:', error)
    return false
  }
}

async function logWebhookEvent(
  supabase: any,
  event: Stripe.Event
): Promise<void> {
  try {
    // Try to find associated user
    let userId: string | null = null

    // Extract customer ID from various event types
    const eventObject = event.data.object as any
    const customerId = eventObject.customer || eventObject.subscription?.customer

    if (customerId) {
      const { data: user } = await supabase
        .from('user_profiles')
        .select('id')
        .eq('stripe_customer_id', customerId)
        .single()

      userId = user?.id || null
    }

    // Log the event
    await supabase
      .from('subscription_events')
      .insert({
        user_id: userId || '00000000-0000-0000-0000-000000000000', // Default UUID for system events
        stripe_event_id: event.id,
        event_type: event.type,
        event_data: event.data,
      })

    console.log('Webhook event logged:', event.id, event.type)
  } catch (error) {
    console.error('Error logging webhook event:', error)
    // Don't fail the webhook processing for logging errors
  }
}