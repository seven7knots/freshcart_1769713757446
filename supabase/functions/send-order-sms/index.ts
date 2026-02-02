const TWILIO_ACCOUNT_SID = Deno.env.get('TWILIO_ACCOUNT_SID');
const TWILIO_AUTH_TOKEN = Deno.env.get('TWILIO_AUTH_TOKEN');
const TWILIO_PHONE_NUMBER = Deno.env.get('TWILIO_PHONE_NUMBER');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': '*'
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { to, orderNumber, status, estimatedTime } = await req.json();

    if (!to || !orderNumber || !status) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: to, orderNumber, status' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Generate status-specific message
    let message = '';
    switch (status) {
      case 'accepted':
        message = `Order ${orderNumber} confirmed! Your order is being prepared. ${estimatedTime ? `Estimated delivery: ${estimatedTime}` : ''}`;
        break;
      case 'picked_up':
        message = `Order ${orderNumber} is out for delivery! Your order is on its way. Track your delivery in real-time.`;
        break;
      case 'delivered':
        message = `Order ${orderNumber} delivered! Thank you for choosing us. Enjoy your order!`;
        break;
      case 'cancelled':
        message = `Order ${orderNumber} has been cancelled. If you have questions, please contact support.`;
        break;
      default:
        message = `Order ${orderNumber} status update: ${status}`;
    }

    // Send SMS via Twilio
    const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;
    const credentials = btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`);
    const formData = new URLSearchParams({
      To: to,
      From: TWILIO_PHONE_NUMBER,
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
        JSON.stringify({ error: 'Failed to send SMS', details: data }),
        { status: response.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('SMS sent successfully:', data.sid);
    return new Response(
      JSON.stringify({ success: true, messageSid: data.sid, status: data.status }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error sending SMS:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});