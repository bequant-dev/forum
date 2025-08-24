# BeQuant Forum - Railway Pre-Deploy Setup

This repository contains the pre-deploy configuration for deploying Discourse on Railway using the Bitnami Discourse template.

## 🚀 Overview

This setup uses Railway's pre-deploy script feature to automatically:
1. Clone the `discourse-oauth2-basic` plugin for Clerk SSO integration
2. Clone a private configuration repository (optional)
3. Install additional plugins from a plugins list
4. Set up all necessary configuration files

## 📁 Repository Structure

```
forum/
├── pre-deploy.sh          # Main pre-deploy script
├── config/
│   ├── discourse.conf     # Discourse configuration template
│   ├── site_settings.yml  # Site settings template
│   └── plugins.txt        # List of additional plugins
└── README.md              # This file
```

## 🔧 Railway Setup Instructions

### Step 1: Deploy Discourse Template

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click "New Project" → "Deploy from Template"
3. Search for "Discourse" and select the Bitnami Discourse template
4. Railway will create the necessary services (Discourse, Sidekiq, PostgreSQL, Redis)

### Step 2: Configure Pre-Deploy Script

In your Railway project settings:

1. Go to the **Discourse** service
2. Navigate to **Settings** → **Deploy**
3. In the **Pre-Deploy Command** field, enter:

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/bequant/main/forum/pre-deploy.sh | bash
```

Replace `YOUR_USERNAME` with your actual GitHub username.

### Step 3: Set Environment Variables

Add these environment variables to your **Discourse** service:

#### Required Variables
```env
# Basic Configuration
DISCOURSE_HOSTNAME=forum.bequant.dev
DISCOURSE_DEVELOPER_EMAILS=rajat@bequant.dev,1997.rajatjain@gmail.com

# Database (Railway will auto-generate these)
DATABASE_HOST=${DATABASE_HOST}
DATABASE_NAME=${DATABASE_NAME}
DATABASE_USERNAME=${DATABASE_USERNAME}
DATABASE_PASSWORD=${DATABASE_PASSWORD}

# Redis (Railway will auto-generate these)
REDIS_HOST=${REDIS_HOST}
REDIS_PORT=${REDIS_PORT}
REDIS_PASSWORD=${REDIS_PASSWORD}

# SMTP Configuration (Gmail)
DISCOURSE_SMTP_USER_NAME=your-email@gmail.com
DISCOURSE_SMTP_PASSWORD=your-app-password

# Clerk OAuth2 Configuration
CLERK_OAUTH2_CLIENT_ID=your-clerk-oauth-client-id
CLERK_OAUTH2_CLIENT_SECRET=your-clerk-oauth-client-secret
```

#### Optional Variables
```env
# Private Config Repository (if using)
CONFIG_REPO_URL=git@github.com:your-username/your-private-config-repo.git
GITHUB_DEPLOY_KEY=-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----
```

### Step 4: Configure Sidekiq Service

For the **Sidekiq** service, add the same environment variables but reference the Discourse service:

```env
# Inherit all variables from Discourse service
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
```

Also set the same pre-deploy command for Sidekiq.

## 🔐 Private Configuration Repository (Optional)

If you want to use a private repository for configuration:

1. Create a private GitHub repository with this structure:
```
your-private-config-repo/
├── discourse.conf
├── site_settings.yml
└── plugins.txt
```

2. Generate a GitHub deploy key:
```bash
ssh-keygen -t rsa -b 4096 -C "railway-discourse@bequant.dev" -f ~/.ssh/railway_deploy_key
```

3. Add the public key to your private repository's deploy keys
4. Add the private key content to Railway as `GITHUB_DEPLOY_KEY`
5. Set `CONFIG_REPO_URL` to your private repository's SSH URL

## 🎯 What the Pre-Deploy Script Does

1. **Environment Check**: Verifies it's running in Bitnami Discourse
2. **Directory Setup**: Creates necessary plugin and config directories
3. **OAuth2 Plugin**: Clones the `discourse-oauth2-basic` plugin
4. **SSH Setup**: Configures GitHub deploy key if provided
5. **Config Repository**: Clones and processes private config repo if specified
6. **Plugin Installation**: Installs additional plugins from `plugins.txt`
7. **Permissions**: Sets correct file ownership for Bitnami user

## 🔍 Troubleshooting

### Pre-Deploy Script Fails
- Check Railway logs for the exact error
- Verify the script URL is accessible
- Ensure all required environment variables are set

### OAuth2 Plugin Not Working
- Verify `CLERK_OAUTH2_CLIENT_ID` and `CLERK_OAUTH2_CLIENT_SECRET` are set
- Check that Clerk OAuth2 application is configured correctly
- Review Discourse admin logs for OAuth2 errors

### Configuration Not Applied
- Check that `discourse.conf` and `site_settings.yml` are in the correct format
- Verify environment variable interpolation is working
- Restart the Discourse service after configuration changes

## 📝 Customization

### Adding More Plugins
Edit `config/plugins.txt` and add GitHub repository URLs, one per line.

### Modifying Configuration
Update `config/discourse.conf` and `config/site_settings.yml` as needed. The files use environment variable interpolation with `${VARIABLE_NAME}` syntax.

### Custom Pre-Deploy Logic
Modify `pre-deploy.sh` to add custom setup steps like:
- Installing system packages
- Setting up SSL certificates
- Configuring custom themes
- Running database migrations

## 🔄 Updates

To update the configuration:
1. Modify the files in this repository
2. Push changes to GitHub
3. Redeploy the Railway service (the pre-deploy script will pull the latest version)

## 📞 Support

For issues with this setup:
1. Check Railway deployment logs
2. Verify all environment variables are set correctly
3. Test the pre-deploy script locally if possible
4. Review Discourse documentation for configuration options 