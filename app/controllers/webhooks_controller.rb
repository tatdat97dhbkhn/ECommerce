# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_forgery_protection

  def stripe
    stripe_secret_key = Rails.application.credentials.dig(:stripe, :secret_key)
    Stripe.api_key = stripe_secret_key
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)
    event = nil

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError
      status 400
      return
    rescue Stripe::SignatureVerificationError
      Rails.logger.debug 'Webhook signature verification failed.'
      status 400
      return
    end

    case event.type
    when 'checkout.session.completed'
      session = event.data.object
      shipping_details = session['shipping_details']
      Rails.logger.debug { "Session: #{session}" }
      if shipping_details
        line1 = shipping_details['address']['line1']
        city = shipping_details['address']['city']
        state = shipping_details['address']['state']
        postal_code = shipping_details['address']['postal_code']
        address = "#{line1} #{city}, #{state} #{postal_code}"
      else
        address = ''
      end
      order = Order.create!(
        customer_email: session['customer_details']['email'],
        total: session['amount_total'],
        address:,
        fulfilled: false,
      )
      full_session = Stripe::Checkout::Session.retrieve({
                                                          id: session.id,
                                                          expand: ['line_items'],
                                                        })
      line_items = full_session.line_items
      line_items['data'].each do |item|
        product = Stripe::Product.retrieve(item['price']['product'])
        product_id = product['metadata']['product_id'].to_i
        OrderProduct.create!(order:, product_id:, quantity: item['quantity'], size: product['metadata']['size'])
        Stock.find(product['metadata']['product_stock_id']).decrement!(:amount, item['quantity']) # rubocop:disable Rails/SkipsModelValidations
      end
    else
      Rails.logger.debug { "Unhandled event type: #{event.type}" }
    end

    render json: { message: 'success' }
  end
end
