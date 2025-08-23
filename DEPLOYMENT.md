# BeQuant Forum - Railway Deployment Guide

This guide walks you through deploying the BeQuant Community Forum using Discourse on Railway.

## 🚀 Quick Start

### Step 1: Prepare Railway Account

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Sign up/login with your GitHub account
3. Ensure you have a Railway plan (Discourse requires resources)

### Step 2: Create New Project

1. Click "New Project" in Railway dashboard
2. Select "Deploy from GitHub repo"
3. Choose this repository (`bequant-forum`)
4. Railway will automatically detect the Dockerfile

### Step 3: Add Required Services

Railway will need these services for Discourse:

1. **PostgreSQL Database**
   - Click "New Service" → "Database" → "PostgreSQL"
   - Railway will automatically provision

2. **Redis Cache**
   - Click "New Service" → "Database" → "Redis"
   - Railway will automatically provision

### Step 4: Configure Environment Variables

In your Railway project, go to "Variables" tab and add:

```env
# Discourse Basic Configuration
DISCOURSE_HOSTNAME=forum.bequant.com
DISCOURSE_DEVELOPER_EMAILS=admin@bequant.com

# Database (Railway will auto-generate these)
DATABASE_HOST=${DATABASE_HOST}
DATABASE_NAME=${DATABASE_NAME}
DATABASE_USERNAME=${DATABASE_USERNAME}
DATABASE_PASSWORD=${DATABASE_PASSWORD}

# Redis (Railway will auto-generate these)
REDIS_HOST=${REDIS_HOST}
REDIS_PORT=${REDIS_PORT}
REDIS_PASSWORD=${REDIS_PASSWORD}

# Email Configuration (Gmail recommended)
DISCOURSE_SMTP_ADDRESS=smtp.gmail.com
DISCOURSE_SMTP_PORT=587
DISCOURSE_SMTP_USER_NAME=your-email@gmail.com
DISCOURSE_SMTP_PASSWORD=your-app-password
DISCOURSE_SMTP_ENABLE_START_TLS=true
DISCOURSE_SMTP_DOMAIN=bequant.com

# Clerk SSO Integration
CLERK_SSO_URL=https://your-clerk-instance.clerk.accounts.dev/sso
CLERK_SSO_SECRET=your-sso-secret

# Analytics (Optional)
GOOGLE_ANALYTICS_ID=GA_MEASUREMENT_ID
GOOGLE_TAG_MANAGER_ID=GTM_CONTAINER_ID
```

### Step 5: Deploy

1. Railway will automatically start building and deploying
2. Monitor the deployment logs
3. Wait for the build to complete (5-10 minutes)

### Step 6: Initial Setup

1. Visit your Railway-provided URL
2. Complete the Discourse setup wizard
3. Create your admin account
4. Configure basic settings

## 🔧 Post-Deployment Configuration

### 1. Domain Setup

1. In Railway, go to your project settings
2. Add custom domain: `forum.bequant.com`
3. Configure DNS records as instructed
4. Wait for SSL certificate (automatic)

### 2. Email Configuration

#### Gmail Setup (Recommended)

1. Enable 2-factor authentication on Gmail
2. Go to Google Account settings → Security
3. Generate app password
4. Use app password in `DISCOURSE_SMTP_PASSWORD`

#### Test Email

1. Go to Discourse admin panel
2. Navigate to Admin → Email → Test
3. Send test email to verify configuration

### 3. Clerk SSO Integration

#### Configure Clerk

1. Go to [Clerk Dashboard](https://dashboard.clerk.com)
2. Add your forum domain to allowed origins
3. Configure SSO settings
4. Get SSO URL and secret

#### Configure Discourse SSO

1. In Discourse admin, go to Admin → Settings → SSO
2. Enable SSO
3. Set SSO URL and secret
4. Test SSO login

### 4. Categories Setup

Create these initial categories:

1. **Interview Prep**
   - Color: #2563eb
   - Description: Get ready for quant trading interviews

2. **Trading Strategies**
   - Color: #10b981
   - Description: Share and discuss quantitative strategies

3. **Career Advice**
   - Color: #8b5cf6
   - Description: Career guidance and mentorship

4. **General Discussion**
   - Color: #6b7280
   - Description: General quantitative finance topics

### 5. Theme Customization

#### Create Custom Theme

1. Go to Admin → Customize → Themes
2. Create new theme
3. Upload custom CSS for BeQuant branding

#### BeQuant CSS Template

```css
/* BeQuant Forum Theme */
:root {
  --primary: #2563eb;
  --primary-dark: #0f172a;
  --primary-light: #38bdf8;
  --accent: #f59e0b;
  --success: #10b981;
  --warning: #f59e0b;
  --danger: #ef4444;
}

/* Header customization */
.header {
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
}

/* Category colors */
.category-box[data-category-id="1"] {
  border-color: #2563eb;
}

.category-box[data-category-id="2"] {
  border-color: #10b981;
}

.category-box[data-category-id="3"] {
  border-color: #8b5cf6;
}

.category-box[data-category-id="4"] {
  border-color: #6b7280;
}
```

### 6. Plugin Installation

Install these recommended plugins:

1. **Discourse Solved**
   - Mark best answers in topics

2. **Discourse Reactions**
   - Like/dislike posts

3. **Discourse Calendar**
   - Schedule events and meetups

4. **Discourse Assign**
   - Assign topics to users

## 📊 Monitoring & Analytics

### Railway Monitoring

1. Monitor resource usage in Railway dashboard
2. Set up alerts for high CPU/memory usage
3. Check database performance

### Discourse Analytics

1. Go to Admin → Reports
2. Monitor user engagement
3. Track category popularity
4. Analyze post statistics

### Google Analytics

1. Add Google Analytics tracking code
2. Monitor traffic and user behavior
3. Set up conversion tracking

## 🔒 Security & Maintenance

### Regular Maintenance

1. **Backup Database**
   - Railway provides automatic backups
   - Monitor backup health

2. **Update Discourse**
   - Regular security updates
   - Feature updates
   - Plugin updates

3. **Monitor Logs**
   - Check Railway logs
   - Monitor Discourse logs
   - Watch for errors

### Security Best Practices

1. **SSL Certificate**
   - Railway provides automatic SSL
   - Ensure HTTPS is enforced

2. **User Permissions**
   - Configure appropriate user roles
   - Set up moderation tools

3. **Spam Protection**
   - Enable Akismet integration
   - Configure spam detection

## 🚨 Troubleshooting

### Common Issues

1. **Deployment Fails**
   - Check Railway logs
   - Verify environment variables
   - Ensure sufficient resources

2. **Email Not Working**
   - Verify SMTP settings
   - Check Gmail app password
   - Test email configuration

3. **SSO Issues**
   - Verify Clerk configuration
   - Check SSO URL and secret
   - Test SSO login flow

4. **Performance Issues**
   - Monitor Railway resources
   - Check database performance
   - Optimize Redis usage

### Getting Help

- **Railway Support**: Check Railway documentation
- **Discourse Support**: Visit [Discourse Meta](https://meta.discourse.org)
- **Clerk Support**: Contact Clerk for SSO issues

## 🎉 Launch Checklist

- [ ] Railway deployment successful
- [ ] Domain configured and SSL working
- [ ] Email notifications working
- [ ] Clerk SSO integration complete
- [ ] Categories and permissions set up
- [ ] Custom theme applied
- [ ] Analytics tracking configured
- [ ] Content seeded from Discord
- [ ] Pro user benefits configured
- [ ] Launch announcement ready

## 💰 Cost Estimation

### Railway Pricing (Monthly)

- **Discourse App**: ~$20-30/month
- **PostgreSQL Database**: ~$10-15/month
- **Redis Cache**: ~$5-10/month
- **Total**: ~$35-55/month

### Additional Costs

- **Domain**: ~$10-15/year
- **Email Service**: Free (Gmail) or ~$20/month (SendGrid)
- **Analytics**: Free (Google Analytics)

**Total Estimated Cost**: ~$40-60/month

---

**Your BeQuant Community Forum is ready to launch! 🚀** 