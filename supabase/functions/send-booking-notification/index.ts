const TWILIO_ACCOUNT_SID = Deno.env.get('TWILIO_ACCOUNT_SID');
const TWILIO_AUTH_TOKEN = Deno.env.get('TWILIO_AUTH_TOKEN');
const TWILIO_WHATSAPP_NUMBER = Deno.env.get('TWILIO_WHATSAPP_NUMBER');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': '*'
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { type, to, orderNumber, bookingNumber, status, scheduledTime, total, storeName, message: customMessage } = body;

    let message = '';
    let recipientPhone = to;

    // Build message based on notification type
    switch (type) {
      case 'order_status_update':
        message = `📦 Order Update\n\n`;
        if (orderNumber) message += `Order: ${orderNumber}\n`;
        if (status) message += `Status: ${status.toUpperCase()}\n`;
        if (customMessage) message += `\n${customMessage}\n`;
        message += `\nTrack your order in the app!`;
        break;

      case 'merchant_new_order':
        message = `🔔 NEW ORDER ALERT\n\n`;
        if (orderNumber) message += `Order: ${orderNumber}\n`;
        if (total) message += `Total: $${total}\n`;
        message += `\nPlease confirm and prepare the order.`;
        break;

      case 'driver_delivery_assignment':
        message = `🚗 NEW DELIVERY ASSIGNMENT\n\n`;
        if (orderNumber) message += `Order: ${orderNumber}\n`;
        if (storeName) message += `Pickup from: ${storeName}\n`;
        message += `\nPlease accept and start delivery.`;
        break;

      case 'service_booking_update':
        message = `Service Booking Update\n\n`;
        if (bookingNumber) message += `Booking: ${bookingNumber}\n`;
        if (status) message += `Status: ${status.toUpperCase()}\n`;
        if (scheduledTime) message += `Scheduled: ${scheduledTime}\n`;
        message += `\nThank you for using our service!`;
        break;

      default:
        message = customMessage || 'You have a new notification.';
    }

    if (!recipientPhone) {
      return new Response(
        JSON.stringify({ error: 'Missing recipient phone number' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Send WhatsApp message via Twilio
    const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;
    const credentials = btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`);
    const formData = new URLSearchParams({
      To: `whatsapp:${recipientPhone}`,
      From: TWILIO_WHATSAPP_NUMBER,
      Body: message
    });

    const response = await fetch(twilioUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${credentials}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: formData
    });

    const data = await response.json();

    if (!response.ok) {
      console.error('Twilio API error:', data);
      return new Response(
        JSON.stringify({ error: 'Failed to send WhatsApp message', details: data }),
        { status: response.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('WhatsApp message sent:', data.sid);
    return new Response(
      JSON.stringify({ success: true, messageSid: data.sid, status: data.status }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error sending WhatsApp:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});