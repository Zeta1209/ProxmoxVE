# Homelab HTTPS Setup with NGINX Proxy Manager, Pi-hole, Cloudflare, and UniFi

## Overview

This guide explains how to set up local-only HTTPS access to your homelab services using:
- **NGINX Proxy Manager (NPM)** for reverse proxy + SSL
- **Cloudflare DNS** for DNS-01 validation (no port forwarding required)
- **Pi-hole** for local DNS overrides
- **UniFi** for network-level DNS settings (or any router that you can choose your DNS settings)

You will end up with:
- `https://service.yourdomain.com` (valid SSL)
- No internet exposure
- No certificate installation needed on devices
- Fully local access

---

## 1. Requirements

You must have:
- A domain hosted on Cloudflare
- Pi-hole running as your LAN DNS server
- UniFi network controller
- Proxmox VE for running NGINX Proxy Manager

---

## 2. Configure UniFi DNS

In UniFi Controller:

**Settings → Internet → WAN → Advanced → DNS Servers**

Set:
- Primary DNS = your Pi-hole IP
- Secondary DNS = 1.1.1.1 (Cloudflare)

Save settings.

---

## 3. Create Cloudflare API Token

Go to **Cloudflare Dashboard → Profile → API Tokens**:

1. Click **Create Token**
2. Choose template **Edit zone DNS**
3. Permissions:
   - Zone → DNS → Edit
4. Scope:
   - Select your domain (`yourdomain.com`)
5. Create token
6. Copy and save it (for NPM)
<img width="1891" height="771" alt="image" src="https://github.com/user-attachments/assets/212388b2-c3ed-448d-b765-e696748bfaf2" />

---

## 4. Deploy NGINX Proxy Manager (Proxmox VE)

Using the Proxmox VE Community Helper Script:

1. Open the shell on your Proxmox node
2. Run the following command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/nginxproxymanager.sh)"
```

3. Follow the script prompts to configure your container
4. Once deployed, access the NPM UI:

```
http://<container-ip>:81
```

Default login:
- Email: admin@example.com
- Password: changeme

For more details, visit: https://community-scripts.github.io/ProxmoxVE/scripts?id=nginxproxymanager

---

## 5. Configure Cloudflare DNS Challenge in NPM

1. Go to **SSL Certificates**
2. Click **Add SSL Certificate**
3. Choose **Let's Encrypt**
4. Enable **DNS Challenge**
5. Select **Cloudflare**
6. Paste your API token
7. Set Propagation Seconds → **120**
8. Save
<img width="532" height="721" alt="image" src="https://github.com/user-attachments/assets/50950936-478c-4d24-a0a2-cf17a4e6498b" />

NPM is now capable of generating valid HTTPS certificates.

---

## 6. Add Local DNS Records in Pi-hole

In Pi-hole:

**Settings → Local DNS Records → Add**

Create A records for each of your services pointing to their local IPs. For example:

| Domain | IP |
|--------|-----|
| service1.yourdomain.com | 192.168.x.x |
| service2.yourdomain.com | 192.168.x.x |
| service3.yourdomain.com | 192.168.x.x |
<img width="236" height="324" alt="image" src="https://github.com/user-attachments/assets/c8820959-feb7-42c7-9f5f-a9ac0029a120" />

---

## 7. Add Services to NGINX Proxy Manager

Example: **Home Assistant**

1. Go to **Hosts → Proxy Hosts → Add Proxy Host**

2. Domain:
   ```
   ha.yourdomain.com
   ```

3. Scheme: `http`

4. Forward Hostname/IP: HA's LAN IP

5. Forward Port: `8123`

6. Enable:
   - Block Common Exploits
   - Websockets

7. In SSL tab:
   - Select **Request a new certificate**
   - Enable **Force SSL**
   - Enable **HTTP/2**
   - Enable **HSTS**

Repeat for each service with their respective ports:
- Proxmox (port 8006)
- Pi-hole (port 80)
- Overseerr (port 5055)
- NAS (port 443/8080)
- Any other services you have
<img width="539" height="640" alt="image" src="https://github.com/user-attachments/assets/6e31d709-1d0a-4505-b924-f60ca3408d2a" /> 

---

## 8. Troubleshooting Browser "Not Secure"

If you encounter "Not Secure" warnings in your browser:

**Quick Fix:**
- Try opening the site in a different browser
- If it works in the other browser, fully close your original browser (all windows) and reopen it
- The certificate should now be trusted

**Additional troubleshooting if needed:**
- Ensure you're navigating to **https://** not cached http://
- Clear browser cache and cookies for the domain
- Check for mixed content in Dev Tools (F12 → Console)
- If issues persist, add this to NPM **Advanced** tab:

```nginx
proxy_set_header X-Forwarded-Proto https;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Real-IP $remote_addr;

proxy_redirect http:// https://;
```

---

## Result

You now have:
- Fully trusted HTTPS
- Local-only access
- No exposed ports
- Clean subdomains for every service

This is the ideal homelab setup for privacy, security, and convenience.
