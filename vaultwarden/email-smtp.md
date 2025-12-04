# Vaultwarden Gmail SMTP Setup Guide (Alpine Linux)

## Overview
Complete guide for configuring Gmail SMTP on Vaultwarden v1.25+ running on Alpine Linux.

## Prerequisites
- Vaultwarden v1.25 or newer
- Gmail account with 2-Step Verification enabled

## Step 1: Generate Google App Password

Since Gmail no longer supports standard passwords for SMTP authentication:

1. Navigate to **Google Account → Security**
2. Enable **2-Step Verification** (if not already enabled)
3. Go to **App Passwords**
4. Create a new app password:
   - Select "Mail" or "Other" as the app type
   - Google generates a 16-character password (format: `abcd efgh ijkl mnop`)
5. Save this password — you'll need it for SMTP configuration

> **Note:** Spaces in the app password are optional when entering it.

## Step 2: Configure SMTP Environment Variables

Vaultwarden v1.25+ uses `SMTP_SECURITY` instead of the deprecated `SMTP_SSL` or `SMTP_EXPLICIT_TLS` variables.

### Required Configuration

```bash
export SMTP_HOST="smtp.gmail.com"
export SMTP_FROM="your.email@gmail.com"
export SMTP_FROM_NAME="Vaultwarden"
export SMTP_PORT=587
export SMTP_SECURITY="starttls"
export SMTP_USERNAME="your.email@gmail.com"
export SMTP_PASSWORD="your_16_char_google_app_password"
export SMTP_AUTH_MECHANISM="Plain"
```

### Optional (Recommended)

```bash
export DOMAIN="https://vault.yourdomain.com"
```

Setting the `DOMAIN` ensures invite and password reset links are correctly formatted.

## Step 3: Restart Vaultwarden

### Alpine Linux (OpenRC)
```bash
sudo rc-service vaultwarden restart
```

### Other Distributions (systemd)
```bash
sudo systemctl restart vaultwarden
```

## Step 4: Test Email Delivery

### Standalone Installation
```bash
vaultwarden send-test-email
```

### Docker Installation
```bash
docker exec -it vaultwarden /vaultwarden send-test-email
```

## Troubleshooting

### Common Issues
- **Authentication failed:** Double-check your app password (no regular password)
- **Connection timeout:** Port 587 may be blocked by your ISP
- **Wrong SMTP variable:** Ensure you're using `SMTP_SECURITY` (not `SMTP_SSL` or `SMTP_EXPLICIT_TLS`)

### Alternative SMTP Providers
If Gmail SMTP proves unreliable, consider:
- SendGrid
- Mailjet
- Mailgun
- Amazon SES

## Success Criteria

✅ SMTP connectivity test returns `0`  
✅ Test email arrives in inbox  
✅ User invites and password resets work correctly  

## Next Steps
- Add multiple users via the admin panel
- Test invite emails
- Configure backup SMTP provider (optional)

---

**Created:** December 2025  
**Vaultwarden Version:** v1.25+  
**OS:** Alpine Linux
