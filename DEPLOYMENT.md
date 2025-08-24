# Railway Discourse Deployment Guide

This guide walks you through deploying Discourse on Railway using a two-stage pre-deploy approach with Clerk OAuth2 integration.

## 🚀 Quick Start

### Step 1: Deploy Discourse Template

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click "New Project" → "Deploy from Template"
3. Search for "Discourse" and select the Bitnami Discourse template
4. Railway will create: Discourse, Sidekiq, PostgreSQL, Redis services

### Step 2: Set Up GitHub Deploy Key

Since your repository is private, we need to set up a deploy key for Railway to access it.

1. **Generate SSH Key Pair** (run on your local machine):
   ```bash
   ssh-keygen -t rsa -b 4096 -C "railway-discourse@bequant.dev" -f ~/.ssh/railway_deploy_key
   cat ~/.ssh/railway_deploy_key.pub  # Copy this for GitHub
   cat ~/.ssh/railway_deploy_key      # Copy this for Railway
   ```

2. **Add Public Key to GitHub**:
   - Go to your repo: `https://github.com/rajatjain/bequant`
   - **Settings** → **Deploy keys** → **Add deploy key**
   - Title: `Railway Discourse Deploy`
   - Key: Paste the public key content
   - ✅ Check "Allow write access"

3. **Add Private Key to Railway**:
   - Go to **Discourse** service → **Variables**
   - Add: `GITHUB_DEPLOY_KEY` = Your private key content

### Step 3: Host Public Bootstrap Script

You need to host the `public-pre-deploy.sh` script publicly so Railway can fetch it.

**Option A: GitHub Gist (Recommended)**
1. Go to [gist.github.com](https://gist.github.com)
2. Create a new gist with the content of `public-pre-deploy.sh`
3. Make it public
4. Get the raw URL: `https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/public-pre-deploy.sh`

**Option B: GitHub Raw Content**
1. Create a public repository for just this script
2. Use the raw GitHub URL: `https://raw.githubusercontent.com/YOUR_USERNAME/REPO_NAME/main/public-pre-deploy.sh`

### Step 4: Configure Pre-Deploy Script

For both **Discourse** and **Sidekiq** services:

1. Go to **Settings** → **Deploy**
2. In **Pre-Deploy Command**, enter:
```bash
curl -sSL YOUR_PUBLIC_SCRIPT_URL | bash
```

Replace `YOUR_PUBLIC_SCRIPT_URL` with the URL from Step 3.

### Step 5: Set Environment Variables

Add these to your **Discourse** service:

```env
# Basic Configuration
DISCOURSE_HOSTNAME=forum.bequant.dev
DISCOURSE_DEVELOPER_EMAILS=rajat@bequant.dev,1997.rajatjain@gmail.com

# Database (Railway auto-generates)
DATABASE_HOST=${DATABASE_HOST}
DATABASE_NAME=${DATABASE_NAME}
DATABASE_USERNAME=${DATABASE_USERNAME}
DATABASE_PASSWORD=${DATABASE_PASSWORD}

# Redis (Railway auto-generates)
REDIS_HOST=${REDIS_HOST}
REDIS_PORT=${REDIS_PORT}
REDIS_PASSWORD=${REDIS_PASSWORD}

# SMTP (Gmail)
DISCOURSE_SMTP_USER_NAME=your-email@gmail.com
DISCOURSE_SMTP_PASSWORD=your-app-password

# Clerk OAuth2 Configuration
CLERK_OAUTH2_CLIENT_ID=your-clerk-oauth-client-id
CLERK_OAUTH2_CLIENT_SECRET=your-clerk-oauth-client-secret

# GitHub Deploy Key (for private repo access)
GITHUB_DEPLOY_KEY=-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----
```

### Step 6: Configure Sidekiq

For **Sidekiq** service, add the same variables but reference Discourse:

```env
DISCOURSE_HOSTNAME=${{Discourse.DISCOURSE_HOSTNAME}}
DISCOURSE_DEVELOPER_EMAILS=${{Discourse.DISCOURSE_DEVELOPER_EMAILS}}
DATABASE_HOST=${{Discourse.DATABASE_HOST}}
DATABASE_NAME=${{Discourse.DATABASE_NAME}}
DATABASE_USERNAME=${{Discourse.DATABASE_USERNAME}}
DATABASE_PASSWORD=${{Discourse.DATABASE_PASSWORD}}
REDIS_HOST=${{Discourse.REDIS_HOST}}
REDIS_PORT=${{Discourse.REDIS_PORT}}
REDIS_PASSWORD=${{Discourse.REDIS_PASSWORD}}
DISCOURSE_SMTP_USER_NAME=${{Discourse.DISCOURSE_SMTP_USER_NAME}}
DISCOURSE_SMTP_PASSWORD=${{Discourse.DISCOURSE_SMTP_PASSWORD}}
CLERK_OAUTH2_CLIENT_ID=${{Discourse.CLERK_OAUTH2_CLIENT_ID}}
CLERK_OAUTH2_CLIENT_SECRET=${{Discourse.CLERK_OAUTH2_CLIENT_SECRET}}
GITHUB_DEPLOY_KEY=${{Discourse.GITHUB_DEPLOY_KEY}}
```

### Step 7: Deploy

1. Railway will automatically start building
2. The public bootstrap script will run and set up SSH
3. It will clone your private repository and run the main pre-deploy script
4. Wait for deployment to complete (5-10 minutes)

## 🔧 Two-Stage Pre-Deploy Process

### Stage 1: Public Bootstrap Script
1. ✅ Fetched from public URL (GitHub Gist or raw content)
2. ✅ Sets up SSH key from `GITHUB_DEPLOY_KEY` environment variable
3. ✅ Clones your private repository
4. ✅ Calls the main pre-deploy script

### Stage 2: Private Pre-Deploy Script
1. ✅ Clones `discourse-oauth2-basic` plugin for Clerk SSO
2. ✅ Creates necessary directories
3. ✅ Sets up configuration files
4. ✅ Installs additional plugins (if specified)
5. ✅ Sets proper permissions

## 🔐 Clerk OAuth2 Setup

### Why OAuth2 Instead of Direct Integration?

Discourse is a server-side Ruby on Rails application that cannot directly use Clerk's client-side components like `<SignIn />` and `<SignUp />`. Therefore, we need to use OAuth2 to integrate Clerk as an authentication provider.

### 1. Create OAuth2 Application in Clerk

1. Go to [Clerk Dashboard](https://dashboard.clerk.com)
2. Navigate to **JWT Templates** → **OAuth2**
3. Create new OAuth2 application
4. Set redirect URLs:
   - `https://forum.bequant.dev/auth/oauth2_basic/callback`
   - `https://your-railway-url.railway.app/auth/oauth2_basic/callback`

### 2. Configure Discourse

The OAuth2 plugin will be automatically installed. In Discourse admin:

1. Go to **Admin** → **Plugins**
2. Enable "OAuth2 Basic"
3. Go to **Admin** → **Site Settings**
4. Search for "oauth2" and configure:
   - `oauth2_enabled`: true
   - `oauth2_client_id`: Your Clerk OAuth2 Client ID
   - `oauth2_client_secret`: Your Clerk OAuth2 Client Secret
   - `oauth2_authorize_url`: `https://clerk.bequant.dev/oauth/authorize`
   - `oauth2_token_url`: `https://clerk.bequant.dev/oauth/token`
   - `oauth2_user_info_url`: `https://clerk.bequant.dev/oauth/userinfo`

### 3. User Experience

Users will:
1. Click "Login with Clerk" on the forum
2. Be redirected to Clerk's OAuth2 authorization page
3. Authenticate with their existing Clerk account
4. Be redirected back to Discourse and logged in

## 📧 Email Setup

### Gmail Configuration

1. Enable 2-factor authentication on Gmail
2. Generate app password: **Google Account** → **Security** → **App passwords**
3. Use the app password in `DISCOURSE_SMTP_PASSWORD`

## 🎨 Customization

### Adding Plugins

Edit `config/plugins.txt` in this repository and add GitHub URLs:

```
https://github.com/discourse/discourse-math.git
https://github.com/discourse/discourse-solved.git
```

### Modifying Configuration

Update `config/discourse.conf` and `config/site_settings.yml` as needed.

## 🔍 Troubleshooting

### Pre-Deploy Script Issues

- Check Railway logs for exact error
- Verify GitHub deploy key is set correctly
- Ensure all environment variables are set
- Check that deploy key has access to your repository
- Verify the public script URL is accessible

### OAuth2 Not Working

- Verify Clerk OAuth2 application is configured
- Check redirect URLs match your domain
- Review Discourse admin logs
- Ensure OAuth2 plugin is enabled

### Email Issues

- Verify Gmail app password is correct
- Check SMTP settings in Discourse admin
- Test email from Discourse admin panel

## 📞 Support

For issues:
1. Check Railway deployment logs
2. Verify environment variables
3. Test configuration locally if possible
4. Review Discourse documentation 