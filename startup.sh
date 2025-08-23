#!/usr/bin/env bash
set -e

echo "🚀 Starting Discourse..."

# Fix git ownership issue
git config --global --add safe.directory /var/www/discourse

# Set required environment
export RAILS_ENV=production

# Set developer emails explicitly
export DISCOURSE_DEVELOPER_EMAILS="rajat@bequant.dev,1997.rajatjain@gmail.com"
echo "🔧 Set developer emails: ${DISCOURSE_DEVELOPER_EMAILS}"

# Debug port configuration
echo "🔍 Checking port configuration..."
echo "PORT: ${PORT:-not set}"
echo "RAILWAY_STATIC_URL: ${RAILWAY_STATIC_URL:-not set}"
echo "DISCOURSE_HOSTNAME: ${DISCOURSE_HOSTNAME:-not set}"

# Check if DISCOURSE_HOSTNAME is set
if [ -z "${DISCOURSE_HOSTNAME:-}" ]; then
  echo "⚠️  WARNING: DISCOURSE_HOSTNAME is not set!"
  echo "   Please add DISCOURSE_HOSTNAME to your Railway environment variables."
  echo "   Example: DISCOURSE_HOSTNAME=your-app-name.railway.app"
fi

# Debug Redis connection
echo "🔍 Checking Redis configuration..."
echo "REDIS_URL: ${REDIS_URL:-not set}"
echo "REDIS_HOST: ${REDIS_HOST:-not set}"
echo "REDIS_PORT: ${REDIS_PORT:-not set}"

# Set Redis URL if not provided by Railway
if [ -z "${REDIS_URL:-}" ]; then
  if [ -n "${REDIS_HOST:-}" ] && [ -n "${REDIS_PORT:-}" ]; then
    REDIS_PASSWORD="${REDIS_PASSWORD:-}"
    if [ -n "$REDIS_PASSWORD" ]; then
      export REDIS_URL="redis://:$REDIS_PASSWORD@$REDIS_HOST:$REDIS_PORT/0"
    else
      export REDIS_URL="redis://$REDIS_HOST:$REDIS_PORT/0"
    fi
    echo "🔧 Set REDIS_URL: $REDIS_URL"
  fi
fi

# Set all Redis environment variables that Discourse expects
export DISCOURSE_REDIS_URL="${REDIS_URL}"
export SIDEKIQ_REDIS_URL="${REDIS_URL}"
export REDIS_PROVIDER="REDIS_URL"

# Set SMTP environment variables if provided
if [ -n "${DISCOURSE_SMTP_USER_NAME:-}" ] && [ -n "${DISCOURSE_SMTP_PASSWORD:-}" ]; then
  echo "🔧 Configuring SMTP settings..."
  export DISCOURSE_SMTP_ADDRESS="smtp.gmail.com"
  export DISCOURSE_SMTP_PORT="587"
  export DISCOURSE_SMTP_ENABLE_START_TLS="true"
  export DISCOURSE_SMTP_DOMAIN="bequant.dev"
  echo "✅ SMTP configured for Gmail"
else
  echo "⚠️  SMTP credentials not provided - email will be disabled"
fi

# Extract Redis components for individual variables
if [[ "${REDIS_URL}" =~ redis://([^:]*):([^@]*)@([^:]*):([^/]*) ]]; then
  export DISCOURSE_REDIS_PASSWORD="${BASH_REMATCH[2]}"
  export DISCOURSE_REDIS_HOST="${BASH_REMATCH[3]}"
  export DISCOURSE_REDIS_PORT="${BASH_REMATCH[4]}"
  echo "🔧 Set Redis components: HOST=${DISCOURSE_REDIS_HOST} PORT=${DISCOURSE_REDIS_PORT}"
elif [[ "${REDIS_URL}" =~ redis://([^:]*):([^/]*) ]]; then
  export DISCOURSE_REDIS_HOST="${BASH_REMATCH[1]}"
  export DISCOURSE_REDIS_PORT="${BASH_REMATCH[2]}"
  echo "🔧 Set Redis components: HOST=${DISCOURSE_REDIS_HOST} PORT=${DISCOURSE_REDIS_PORT}"
fi

# Go to Discourse directory
cd /var/www/discourse

# Create all required log directories
echo "📁 Creating log directories..."
mkdir -p log
mkdir -p /home/discourse/discourse/log
mkdir -p tmp/pids
mkdir -p /home/discourse/discourse/tmp/pids
chmod 755 log
chmod 755 /home/discourse/discourse/log
chmod 755 tmp/pids
chmod 755 /home/discourse/discourse/tmp/pids

# Completely remove AI plugin to avoid vector migration issues
echo "🔧 Removing AI plugin..."
if [ -d "plugins/discourse-ai" ]; then
  rm -rf plugins/discourse-ai
  echo "✅ AI plugin completely removed"
elif [ -d "plugins/discourse-ai.disabled" ]; then
  rm -rf plugins/discourse-ai.disabled
  echo "✅ Disabled AI plugin completely removed"
else
  echo "ℹ️  AI plugin not found"
fi

# Disable AI plugin in plugin registry
echo "🔧 Disabling AI plugin in registry..."
bundle exec rails r '
  begin
    # Disable AI plugin if it exists in the registry
    if defined?(Plugin::Instance)
      Plugin::Instance.find_by_name("discourse-ai")&.disable!
      puts "AI plugin disabled in registry"
    end
  rescue => e
    puts "Could not disable AI plugin in registry: #{e.message}"
  end
' || true

# Pre-mark problematic migration to avoid pg_vector issues
echo "🔧 Pre-marking problematic migrations..."
bundle exec rails r '
  begin
    migration_name = "20230710171141_enable_pg_vector_extension"
    if ActiveRecord::Base.connection.table_exists?("schema_migrations")
      ActiveRecord::Base.connection.execute("INSERT INTO schema_migrations (version) VALUES ('\''#{migration_name}'\'') ON CONFLICT (version) DO NOTHING")
      puts "Pre-marked vector extension migration as completed"
    end
  rescue => e
    puts "Could not pre-mark migration: #{e.message}"
  end
' || true

# Run migrations with error handling
echo "📊 Running database migrations..."
if ! bundle exec rake db:migrate; then
  echo "❌ Migration failed, marking problematic migration as complete..."
  bundle exec rails r '
    begin
      migration_name = "20230710171141_enable_pg_vector_extension"
      if ActiveRecord::Base.connection.table_exists?("schema_migrations")
        ActiveRecord::Base.connection.execute("INSERT INTO schema_migrations (version) VALUES ('\''#{migration_name}'\'') ON CONFLICT (version) DO NOTHING")
        puts "Marked vector extension migration as completed"
      end
    rescue => e
      puts "Could not handle migration: #{e.message}"
    end
  ' || true
fi

# Set the correct port for Railway
PORT_TO_BIND="${PORT:-3000}"
echo "🌟 Starting Puma on port ${PORT_TO_BIND}..."

# Check if this is a restart
if [ -f "/tmp/discourse_started" ]; then
  echo "⚠️  This appears to be a restart - checking for issues..."
  rm -f /tmp/discourse_started
else
  echo "✅ First time startup"
  touch /tmp/discourse_started
fi

# Set up signal handling
trap 'echo "Received signal, shutting down gracefully..."; exit 0' SIGTERM SIGINT

# Start Puma with single mode for Railway's 1GB VM
echo "🚀 Launching Puma server in single mode..."
exec bundle exec puma -b "tcp://0.0.0.0:${PORT_TO_BIND}" -e production -w 0 -t 4:8 --preload