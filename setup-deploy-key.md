# Setting Up GitHub Deploy Key for Railway

Since your repository is private, Railway can't access the raw GitHub content. Here's how to set up a deploy key for secure access.

## Step 1: Generate SSH Key Pair

Run these commands on your local machine:

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "railway-discourse@bequant.dev" -f ~/.ssh/railway_deploy_key

# View the public key (you'll add this to GitHub)
cat ~/.ssh/railway_deploy_key.pub

# View the private key (you'll add this to Railway)
cat ~/.ssh/railway_deploy_key
```

## Step 2: Add Public Key to GitHub

1. Go to your GitHub repository: `https://github.com/rajatjain/bequant`
2. Click **Settings** → **Deploy keys**
3. Click **Add deploy key**
4. Fill in:
   - **Title**: `Railway Discourse Deploy`
   - **Key**: Paste the content of `~/.ssh/railway_deploy_key.pub`
   - **Allow write access**: ✅ Check this box
5. Click **Add key**

## Step 3: Add Private Key to Railway

1. Go to your Railway project
2. Go to **Discourse** service → **Variables**
3. Add new variable:
   - **Name**: `GITHUB_DEPLOY_KEY`
   - **Value**: Paste the content of `~/.ssh/railway_deploy_key` (the private key)
4. Click **Add**

## Step 4: Update Pre-Deploy Command

In Railway, update the **Pre-Deploy Command** for both Discourse and Sidekiq services to:

```bash
git clone git@github.com:rajatjain/bequant.git /tmp/bequant && bash /tmp/bequant/forum/pre-deploy.sh
```

## Step 5: Test Deployment

1. Deploy the Discourse service
2. Check the logs to ensure the script runs successfully
3. You should see messages like:
   - ✅ "GitHub deploy key configured"
   - ✅ "Cloning configuration repository..."
   - ✅ "OAuth2 plugin installed successfully"

## Security Notes

- The deploy key only has access to this specific repository
- You can revoke it anytime from GitHub settings
- The private key is stored securely in Railway's environment variables
- Railway will use this key to clone your private repository during deployment

## Alternative: Public Gist Method

If you prefer not to use deploy keys, you can:

1. Create a public GitHub Gist with the pre-deploy script
2. Use the raw gist URL in Railway:
   ```bash
   curl -sSL https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/pre-deploy.sh | bash
   ```

But the deploy key method is more secure and reliable. 