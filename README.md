# BeQuant Community Forum

A professional community forum for quantitative finance professionals, powered by Discourse and hosted on Railway.

## 🚀 Overview

This repository contains documentation and configuration for deploying the BeQuant Community Forum using Discourse on Railway. The forum will integrate with your existing BeQuant platform and maintain consistent branding.

## 🎯 Forum Features

- **SSO Integration** with your existing Clerk authentication
- **BeQuant Branding** - matches your current design system
- **Categories**: Interview Prep, Trading Strategies, Career Advice, General Discussion
- **Pro User Benefits** - enhanced forum access for subscribers
- **Email Notifications** - for relevant posts and discussions
- **Domain**: forum.bequant.com or community.bequant.com

## 🛠️ Tech Stack

- **Forum Platform**: Discourse
- **Hosting**: Railway
- **Authentication**: Clerk OAuth2 (same as BeQuant platform)
- **Domain**: Custom domain integration

## 📋 Prerequisites

- Railway account
- Clerk account (existing from BeQuant platform)
- Domain name (forum.bequant.com or community.bequant.com)
- Docker knowledge (basic)

## 🚀 Railway Deployment

### 1. Create Railway Project

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Choose this repository

### 2. Configure Environment Variables

Add these environment variables in Railway:

```env
# Discourse Configuration
DISCOURSE_HOSTNAME=forum.bequant.com
DISCOURSE_DEVELOPER_EMAILS=admin@bequant.com
DISCOURSE_SMTP_ADDRESS=smtp.gmail.com
DISCOURSE_SMTP_PORT=587
DISCOURSE_SMTP_USER_NAME=your-email@gmail.com
DISCOURSE_SMTP_PASSWORD=your-app-password
DISCOURSE_SMTP_ENABLE_START_TLS=true
DISCOURSE_SMTP_DOMAIN=bequant.com

# Database (Railway will provide)
DATABASE_URL=your-railway-postgres-url

# Redis (Railway will provide)
REDIS_URL=your-railway-redis-url

# Clerk OAuth2 (Same as BeQuant)
CLERK_OAUTH2_CLIENT_ID=your-clerk-oauth-client-id
CLERK_OAUTH2_CLIENT_SECRET=your-clerk-oauth-client-secret
```

### 3. Deploy Discourse

Railway will automatically deploy Discourse using Docker. The deployment includes:

- PostgreSQL database
- Redis for caching
- Discourse application
- SSL certificate (automatic)

### 4. Initial Setup

1. Visit your forum URL (provided by Railway)
2. Complete the initial Discourse setup
3. Create admin account
4. Configure categories and permissions

## 🎨 BeQuant Branding Integration

### Color Scheme (from existing BeQuant site)

```css
/* Primary Colors */
--primary: #2563eb;     /* Indigo-600 */
--primary-dark: #0f172a; /* Slate-900 */
--primary-light: #38bdf8; /* Teal-400 */

/* Accent Colors */
--accent: #f59e0b;      /* Amber-500 */
--success: #10b981;     /* Emerald-500 */
--warning: #f59e0b;     /* Amber-500 */
--danger: #ef4444;      /* Red-500 */
```

### Custom Theme

Create a custom Discourse theme with:

1. **Header**: BeQuant logo and navigation
2. **Colors**: Match your existing color scheme
3. **Typography**: Use Inter font family
4. **Layout**: Clean, professional design

## 🔐 Clerk SSO Integration

### 1. Configure Clerk

1. Go to your [Clerk Dashboard](https://dashboard.clerk.com)
2. Add your forum domain to allowed origins
3. Configure SSO settings

### 2. Discourse SSO Plugin

Install and configure the Clerk SSO plugin for Discourse:

```bash
# In Discourse admin panel
cd /var/discourse
./launcher enter app
cd /var/www/discourse
bin/rails console
```

### 3. SSO Configuration

```ruby
# In Discourse console
SiteSetting.sso_url = "https://your-clerk-instance.clerk.accounts.dev/sso"
SiteSetting.sso_secret = "your-sso-secret"
SiteSetting.enable_sso = true
```

## 📧 Email Configuration

### Gmail Setup (Recommended)

1. Enable 2-factor authentication on Gmail
2. Generate app password
3. Use app password in DISCOURSE_SMTP_PASSWORD

### Alternative: SendGrid

```env
DISCOURSE_SMTP_ADDRESS=smtp.sendgrid.net
DISCOURSE_SMTP_PORT=587
DISCOURSE_SMTP_USER_NAME=apikey
DISCOURSE_SMTP_PASSWORD=your-sendgrid-api-key
```

## 🏗️ Forum Categories

### Initial Categories Setup

1. **Interview Prep**
   - Description: Get ready for quant trading interviews
   - Color: Blue (#2563eb)
   - Icon: Briefcase

2. **Trading Strategies**
   - Description: Share and discuss quantitative strategies
   - Color: Green (#10b981)
   - Icon: Trending Up

3. **Career Advice**
   - Description: Career guidance and mentorship
   - Color: Purple (#8b5cf6)
   - Icon: Users

4. **General Discussion**
   - Description: General quantitative finance topics
   - Color: Gray (#6b7280)
   - Icon: Message Square

## 🔧 Customization

### 1. Theme Customization

Create a custom theme in Discourse admin:

1. Go to Admin → Customize → Themes
2. Create new theme
3. Upload custom CSS/HTML
4. Apply to site

### 2. Plugin Installation

Common plugins to install:

- **Clerk SSO**: For authentication
- **Discourse Solved**: Mark best answers
- **Discourse Reactions**: Like/dislike posts
- **Discourse Calendar**: Event scheduling

### 3. SEO Optimization

Configure in Discourse admin:

- Site title: "BeQuant Community Forum"
- Site description: "Join the BeQuant community for interview prep, trading strategies, and career advice"
- Meta tags for social sharing
- Google Analytics integration

## 📊 Analytics & Monitoring

### 1. Google Analytics

Add Google Analytics tracking code to Discourse header.

### 2. Railway Monitoring

- Monitor resource usage in Railway dashboard
- Set up alerts for high CPU/memory usage
- Monitor database performance

### 3. Discourse Analytics

- User engagement metrics
- Post and topic statistics
- Category popularity

## 🚀 Success Strategy

### Community Building

1. **Migrate Discord Community**
   - Invite existing 30-40 Discord members
   - Seed content from Discord discussions
   - Cross-promote between platforms

2. **Content Strategy**
   - Interview prep questions and solutions
   - Trading strategy discussions
   - Career advice from professionals
   - Market analysis and insights

3. **Pro User Benefits**
   - Enhanced forum access for subscribers
   - Priority support
   - Exclusive content areas
   - Advanced features

### Growth Tactics

1. **SEO Optimization**
   - Optimize forum content for search
   - Create valuable, shareable content
   - Build backlinks from trading communities

2. **Social Media Promotion**
   - Share forum discussions on Twitter/LinkedIn
   - Create content marketing around forum topics
   - Engage with quantitative finance communities

3. **Email Marketing**
   - Newsletter featuring top forum discussions
   - Weekly digest of best content
   - Invite existing BeQuant users

## 🔧 Maintenance

### Regular Tasks

1. **Backup Database**
   - Railway provides automatic backups
   - Monitor backup health

2. **Update Discourse**
   - Regular security updates
   - Feature updates
   - Plugin updates

3. **Monitor Performance**
   - Check Railway resource usage
   - Monitor forum performance
   - User feedback and issues

### Troubleshooting

Common issues and solutions:

1. **Email not working**: Check SMTP settings
2. **SSO issues**: Verify Clerk configuration
3. **Performance issues**: Check Railway resources
4. **Database issues**: Monitor PostgreSQL logs

## 📞 Support

For technical support:

- **Railway**: Check Railway documentation and support
- **Discourse**: Visit [Discourse Meta](https://meta.discourse.org)
- **Clerk**: Contact Clerk support for SSO issues

## 🎉 Launch Checklist

- [ ] Railway deployment complete
- [ ] Domain configured and SSL working
- [ ] Email notifications working
- [ ] Clerk SSO integration complete
- [ ] Categories and permissions set up
- [ ] Custom theme applied
- [ ] Analytics tracking configured
- [ ] Content seeded from Discord
- [ ] Pro user benefits configured
- [ ] Launch announcement ready

---

**Ready to launch the BeQuant Community Forum! 🚀** 