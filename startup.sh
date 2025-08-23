#!/usr/bin/env bash
set -e

echo "🚀 Starting Discourse..."

# Set required environment
export RAILS_ENV=production

# Go to Discourse directory
cd /var/www/discourse

# Create log directory
mkdir -p log

# Setup database if needed
echo "📊 Setting up database..."
bundle exec rake db:setup

# Start Puma
echo "🌟 Starting Puma..."
exec bundle exec puma -C config/puma.rb -b "tcp://0.0.0.0:${PORT:-3000}"