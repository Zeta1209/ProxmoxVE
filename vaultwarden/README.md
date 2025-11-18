# Vaultwarden Hardening Guide (Alpine / ProxmoxVE Script)

## 1. Open the Vaultwarden config file
```bash
nano /etc/conf.d/vaultwarden
```

## 2. Add or modify these lines inside the file
```bash
export SIGNUPS_ALLOWED=false
export ADMIN_TOKEN="your_secure_admin_token_here"
export INVITATIONS_ALLOWED=false
```

### What each setting does

- **`SIGNUPS_ALLOWED=false`** - Disables public account creation. Nobody can register from the login page.
- **`ADMIN_TOKEN="your_secure_admin_token_here"`** - Enables the hidden `/admin` panel using this token. This is required so you can manually create users.
- **`INVITATIONS_ALLOWED=false`** - Disables user invitations. This also removes the "Create Account" link when email isn't configured.

### Combined effect

Together, these settings lock Vaultwarden into a private mode where:
- No one can create an account on their own
- Only you (via the admin panel) can add new users
- The UI no longer shows any signup options

## 3. Save and exit the file

Save your changes in the editor and close it.

## 4. Restart the Vaultwarden service
```bash
rc-service vaultwarden restart
```

## 5. Verify the changes

- Public signups are disabled
- The `/admin` page is accessible using your admin token
- The "Create Account" button is no longer visible
- Only administrator-created accounts are allowed

Your Vaultwarden instance is now secured and private.