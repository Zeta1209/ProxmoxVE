# Vaultwarden Hardening Guide (Alpine Linux LXC)

## Prerequisites

This guide is for a Vaultwarden Alpine Linux LXC installation provided by the Proxmox VE Helper Scripts available at: 

https://community-scripts.github.io/ProxmoxVE/scripts?id=vaultwarden

**Important:** When using the installation script, make sure to choose the **Alpine Linux** option on the webpage.

**Note:** If you want to set up and manage this configuration via SSH on the machine, see the [SSH Setup on Alpine Linux](#ssh-setup-on-alpine-linux) section below.

## 1. Generate a Secure Argon2id Admin Token

Create a cryptographically secure admin token hash:

```bash
vaultwarden hash
```

When prompted, enter a strong password. Vaultwarden will output an Argon2id hash like:

```
$argon2id$v=19$m=65536,t=3,p=4$xxxx$yyyy
```

**Important:** Copy this entire hash - you'll need it in the next step.

## 2. Open the Vaultwarden config file
```bash
nano /etc/conf.d/vaultwarden
```

## 3. Add or modify these lines inside the file

```bash
export SIGNUPS_ALLOWED=false
export ADMIN_TOKEN='$argon2id$v=19$m=65536,t=3,p=4$xxxxxx$yyyyyy'
export INVITATIONS_ALLOWED=false
```

**Critical:** Use single quotes `' '` around the `ADMIN_TOKEN` to prevent shell interpretation of the `$` symbols.

### What each setting does

- **`SIGNUPS_ALLOWED=false`** - Disables public account creation. Nobody can register from the login page.
- **`ADMIN_TOKEN='$argon2id$...'`** - Enables the hidden `/admin` panel using a secure Argon2id hashed token. You'll use your plain password (not the hash) to access the admin panel.
- **`INVITATIONS_ALLOWED=false`** - Disables user invitations. This also removes the "Create Account" link when email isn't configured.

### Combined effect

Together, these settings lock Vaultwarden into a private mode where:
- No one can create an account on their own
- Only you (via the admin panel) can add new users
- The UI no longer shows any signup options
- Your admin token is cryptographically protected (even if someone reads the config file, they cannot derive your password)

## 4. Save and exit the file

Save your changes in the editor and close it.

## 5. Restart the Vaultwarden service
```bash
rc-service vaultwarden restart
```

## 6. Verify the changes

- Public signups are disabled
- The `/admin` page is accessible using your **plain password** (not the hash)
- The "Create Account" button is no longer visible
- Only administrator-created accounts are allowed

Your Vaultwarden instance is now secured and private.

---

## SSH Setup on Alpine Linux

This section explains how to enable SSH access on your Alpine Linux container and create a user with administrative privileges.

### 1. Install OpenSSH and doas
```bash
apk add openssh doas
```

### 2. Create a new user

Replace `username` with your desired username:
```bash
adduser username
```

You'll be prompted to set a password and optionally fill in user information.

### 3. Configure doas (sudo alternative for Alpine)

Edit the doas configuration file:
```bash
nano /etc/doas.conf
```

Add the following line (replace `username` with your actual username):
```bash
permit nopass keepenv username as root
```

This configuration allows:
- `permit` - Grants permission
- `nopass` - No password required for elevated privileges
- `keepenv` - Preserves environment variables
- `username` - Your specific user
- `as root` - Can execute commands as root

### 4. Configure SSH

Edit the SSH configuration file:
```bash
nano /etc/ssh/sshd_config
```

Recommended security settings to modify or add:
```bash
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
```

**Note:** Once you set up SSH keys, you can disable password authentication for better security.

### 5. Enable and start SSH service
```bash
rc-update add sshd
rc-service sshd start
```

### 6. (Optional) Set up SSH key authentication

On your local machine, generate an SSH key pair if you don't have one:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Then copy your public key to the Alpine server:
```bash
ssh-copy-id username@your-server-ip
```

After verifying key-based login works, you can disable password authentication by editing `/etc/ssh/sshd_config`:
```bash
PasswordAuthentication no
```

Then restart the SSH service:
```bash
rc-service sshd restart
```

### 7. Test your setup

From your local machine:
```bash
ssh username@your-server-ip
```

Once logged in, test doas access:
```bash
doas apk update
```

You now have SSH access to your Alpine Linux container with a user that has administrative privileges via doas.
