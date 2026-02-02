# Marketplace Phase 9 - External Setup Guide

## Twilio WhatsApp Configuration

To enable WhatsApp notifications for service bookings, you need to configure Twilio:

### 1. Get Twilio Credentials

1. Sign up at https://www.twilio.com/
2. Navigate to Console Dashboard
3. Copy your **Account SID** and **Auth Token**

### 2. Enable WhatsApp Sandbox

1. Go to Messaging → Try it out → Send a WhatsApp message
2. Follow instructions to connect your WhatsApp to Twilio sandbox
3. Copy your **WhatsApp-enabled phone number** (format: whatsapp:+14155238886)

### 3. Add Environment Variables

Add these to your environment configuration:

```
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_WHATSAPP_NUMBER=whatsapp:+14155238886
```

### 4. Deploy Edge Function

Deploy the Twilio notification function to Supabase:

```bash
supabase functions deploy send-booking-notification
```

### 5. Test Notifications

When a service booking is created, the system will send WhatsApp notifications with:
- Booking number
- Status updates
- Scheduled time

## Marketplace Features Available

### Services Tab
- 🚕 Taxi
- 🚗 Towing
- 💧 Water Delivery
- ⛽ Diesel Delivery
- 👨‍🍳 Private Chef
- 🏋️ Personal Trainer
- 🚘 Private Driver

### Products Tab
- User-to-user marketplace
- Multi-image upload (up to 5 images)
- Category filtering
- Condition filtering
- Price negotiation toggle

### Navigation
- Home screen → Marketplace icon in app bar
- Profile screen → Marketplace and My Bookings menu items

## Database Tables

All marketplace tables are already created:
- `services` - Service providers and offerings
- `service_bookings` - Service reservations
- `marketplace_listings` - User product listings
- `marketplace-images` storage bucket - Product images

## Payment Integration

Bookings support:
- Cash payment
- Wallet payment (using existing wallet system)

No additional payment gateway setup required.