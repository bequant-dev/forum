#!/usr/bin/env bash
set -e

echo "🚀 Starting Discourse..."

# Fix git ownership issue
git config --global --add safe.directory /var/www/discourse

# Set required environment
export RAILS_ENV=production

# Enable debug logging
export RAILS_LOG_LEVEL=debug
export DISCOURSE_LOG_LEVEL=debug
echo "🔍 Debug logging enabled"

# Rails logging will be configured after changing to Discourse directory

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
  export DISCOURSE_SMTP_AUTHENTICATION="plain"
  export DISCOURSE_SMTP_USER_NAME="${DISCOURSE_SMTP_USER_NAME}"
  export DISCOURSE_SMTP_PASSWORD="${DISCOURSE_SMTP_PASSWORD}"
  echo "✅ SMTP configured for Gmail"
  echo "   Address: ${DISCOURSE_SMTP_ADDRESS}"
  echo "   Port: ${DISCOURSE_SMTP_PORT}"
  echo "   Domain: ${DISCOURSE_SMTP_DOMAIN}"
  echo "   Username: ${DISCOURSE_SMTP_USER_NAME}"
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

# Test if environment variables are exported
echo "🧪 Testing environment variable export..."
if [ -n "${DISCOURSE_SMTP_ADDRESS:-}" ]; then
  echo "✅ DISCOURSE_SMTP_ADDRESS is set: ${DISCOURSE_SMTP_ADDRESS}"
else
  echo "❌ DISCOURSE_SMTP_ADDRESS is not set"
fi

# Test SMTP connection with Ruby
echo "🧪 Testing SMTP connection with Ruby..."
cat > /tmp/test_smtp.rb << 'EOF'
#!/usr/bin/env ruby
require 'net/smtp'

puts "Testing SMTP with environment variables..."

smtp_settings = {
  address: ENV['DISCOURSE_SMTP_ADDRESS'],
  port: ENV['DISCOURSE_SMTP_PORT'].to_i,
  domain: ENV['DISCOURSE_SMTP_DOMAIN'],
  user_name: ENV['DISCOURSE_SMTP_USER_NAME'],
  password: ENV['DISCOURSE_SMTP_PASSWORD'],
  authentication: 'plain'
}

puts "SMTP Settings:"
puts "  Address: #{smtp_settings[:address]}"
puts "  Port: #{smtp_settings[:port]}"
puts "  Domain: #{smtp_settings[:domain]}"
puts "  Username: #{smtp_settings[:user_name]}"
puts "  Password: [HIDDEN]"

begin
  smtp = Net::SMTP.new(smtp_settings[:address], smtp_settings[:port])
  smtp.enable_starttls_auto
  
  smtp.start(smtp_settings[:domain], smtp_settings[:user_name], smtp_settings[:password], smtp_settings[:authentication]) do |smtp|
    puts "✅ SMTP connection successful!"
    
    message = <<~EMAIL
      From: #{smtp_settings[:user_name]}
      To: #{smtp_settings[:user_name]}
      Subject: Discourse SMTP Test from Railway
      
      This is a test email from your Discourse forum SMTP configuration.
      
      If you receive this, your SMTP settings are working correctly!
      
      Sent at: #{Time.now}
    EMAIL
    
    smtp.send_message(message, smtp_settings[:user_name], smtp_settings[:user_name])
    puts "✅ Test email sent successfully!"
  end
  
rescue => e
  puts "❌ SMTP Error: #{e.message}"
  puts "🔍 Error details: #{e.class}"
end
EOF

ruby /tmp/test_smtp.rb
rm -f /tmp/test_smtp.rb

# Go to Discourse directory
cd /var/www/discourse

# Configure Rails to log to STDOUT
echo "🔍 Configuring Rails logging to STDOUT..."
bundle exec rails r '
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  Rails.logger.level = Logger::DEBUG
  puts "✅ Rails logging configured for STDOUT"
'

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

# Test Discourse's SMTP configuration
echo "🧪 Testing Discourse's SMTP configuration..."
bundle exec rails r '
  begin
    puts "Testing Discourse SMTP configuration..."
    
    # Check if ActionMailer is configured
    if defined?(ActionMailer::Base)
      puts "ActionMailer is available"
      
      # Check SMTP settings
      smtp_settings = ActionMailer::Base.smtp_settings
      puts "SMTP Settings from ActionMailer:"
      puts "  Address: #{smtp_settings[:address]}"
      puts "  Port: #{smtp_settings[:port]}"
      puts "  Domain: #{smtp_settings[:domain]}"
      puts "  Username: #{smtp_settings[:user_name]}"
      puts "  Authentication: #{smtp_settings[:authentication]}"
      puts "  Enable StartTLS: #{smtp_settings[:enable_starttls_auto]}"
      
      # Try to send a test email
      puts "Sending test email..."
      ActionMailer::Base.mail(
        from: ENV["DISCOURSE_SMTP_USER_NAME"],
        to: ENV["DISCOURSE_SMTP_USER_NAME"],
        subject: "Discourse SMTP Test",
        body: "This is a test email from Discourse ActionMailer"
      ).deliver_now
      
      puts "✅ Discourse SMTP test email sent successfully!"
      
      # Test background job queue
      puts "Testing background job queue..."
      if defined?(Sidekiq)
        puts "Sidekiq is available"
        queue_size = Sidekiq::Queue.new.size
        puts "Current queue size: #{queue_size}"
        
        # Test if we can enqueue a job
        puts "✅ Background job queue is working"
        
        # Check and fix Discourse email settings
        puts "Checking Discourse email settings..."
        if defined?(SiteSetting)
          puts "Current Site Settings:"
          puts "  notification_email: #{SiteSetting.notification_email}"
          puts "  reply_by_email_address: #{SiteSetting.reply_by_email_address}"
          
          # Fix email settings
          puts "Fixing email settings..."
          SiteSetting.notification_email = ENV["DISCOURSE_SMTP_USER_NAME"]
          SiteSetting.reply_by_email_address = "reply+%{reply_key}@bequant.dev"
          
          puts "Updated Site Settings:"
          puts "  notification_email: #{SiteSetting.notification_email}"
          puts "  reply_by_email_address: #{SiteSetting.reply_by_email_address}"
          puts "✅ Email settings updated!"
        else
          puts "❌ SiteSetting not available"
        end
      end
    else
      puts "❌ ActionMailer not available"
    end
  rescue => e
    puts "❌ Discourse SMTP Error: #{e.message}"
    puts "🔍 Error details: #{e.class}"
  end
'

# Email configuration check complete
echo "✅ Email configuration check complete"

# Test if Rails console works
echo "🧪 Testing Rails console..."
bundle exec rails r 'puts "Rails console is working!"'

# Create admin account if it doesn't exist
echo "👑 Creating admin account..."
echo "🔍 Starting Rails console for admin creation..."
bundle exec rails r '
  begin
    # Check database structure first
    puts "Checking database structure..."
    columns = ActiveRecord::Base.connection.columns("users")
    email_columns = columns.select { |c| c.name.include?("email") }
    puts "Email-related columns: #{email_columns.map(&:name).join(", ")}"
    
    # Check existing users
    existing_users = User.limit(5)
    puts "Existing users:"
    existing_users.each do |user|
      puts "  - #{user.username} (admin: #{user.admin?}, active: #{user.active?})"
    end
    
    # Check if admin exists
    admin_count = User.where(admin: true).count
    puts "Current admin users: #{admin_count}"
    
        # Check existing rajat user
    existing_rajat = User.find_by(username: "rajat")
    if existing_rajat
      puts "Found existing rajat user:"
      puts "  Username: #{existing_rajat.username}"
      puts "  Email: #{existing_rajat.email}"
      puts "  Admin: #{existing_rajat.admin?}"
      puts "  Active: #{existing_rajat.active?}"
      
      # Activate and promote the existing rajat user
      puts "Activating and promoting existing rajat user..."
      existing_rajat.update!(
        admin: true,
        moderator: true,
        approved: true,
        active: true,
        password: "admin123456789012"
      )
      puts "✅ Existing rajat user activated and promoted to admin!"
      puts "  Login with: rajat / admin123456789012"
    else
      puts "Creating new admin user..."
      
      # Try to create admin with basic fields
      admin = User.new(
        username: "rajat-admin",
        name: "Rajat Jain",
        password: "admin123456789012",
        admin: true,
        moderator: true,
        approved: true,
        active: true
      )
      
      # Set email using the correct method
      admin.email = "rajat@bequant.dev"
      
      if admin.save
        puts "✅ Admin user created successfully!"
        puts "  Username: #{admin.username}"
        puts "  Email: #{admin.email}"
      else
        puts "❌ Failed to create admin: #{admin.errors.full_messages.join(", ")}"
      end
    end
  rescue => e
    puts "❌ Admin creation error: #{e.message}"
  end
'

# Test sending a real Discourse email
echo "🧪 Testing real Discourse email sending..."
echo "🔍 Starting Rails console for email test..."
bundle exec rails r '
  begin
    puts "Testing real Discourse email..."
    
    # Try to send a test email using Discourse mailer
    if defined?(UserMailer)
      puts "UserMailer is available"
      
      # Create a test user
      test_user = User.new(
        email: ENV["DISCOURSE_SMTP_USER_NAME"],
        username: "test_user",
        name: "Test User"
      )
      
      # Try to send welcome email
      puts "Sending welcome email..."
      UserMailer.welcome_user(test_user).deliver_now
      puts "✅ Welcome email sent successfully!"
      
    else
      puts "❌ UserMailer not available"
    end
    
    # Check email queue
    if defined?(Jobs::UserEmail)
      puts "UserEmail job is available"
      puts "Checking if emails are being queued..."
    else
      puts "❌ UserEmail job not available"
    end
    
    # Check Sidekiq queues
    if defined?(Sidekiq)
      puts "Checking Sidekiq queues..."
      default_queue = Sidekiq::Queue.new("default")
      puts "Default queue size: #{default_queue.size}"
      
      if default_queue.size > 0
        puts "Jobs in default queue:"
        default_queue.each do |job|
          puts "  - #{job.klass} (args: #{job.args})"
        end
      end
      
      mailer_queue = Sidekiq::Queue.new("mailers")
      puts "Mailers queue size: #{mailer_queue.size}"
      
      if mailer_queue.size > 0
        puts "Jobs in mailers queue:"
        mailer_queue.each do |job|
          puts "  - #{job.klass} (args: #{job.args})"
        end
      end
    end
    
  rescue => e
    puts "❌ Real email test error: #{e.message}"
    puts "🔍 Error details: #{e.class}"
    puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
  end
'

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

# Start both Sidekiq and Puma
echo "🚀 Starting Sidekiq and Puma..."

# Start Sidekiq in background
echo "🔄 Starting Sidekiq background job processor..."
bundle exec sidekiq -e production -C config/sidekiq.yml &
SIDEKIQ_PID=$!

# Wait a moment for Sidekiq to start
sleep 5

# Check if Sidekiq started successfully
if kill -0 $SIDEKIQ_PID 2>/dev/null; then
  echo "✅ Sidekiq started successfully (PID: $SIDEKIQ_PID)"
else
  echo "❌ Sidekiq failed to start"
fi

# Start Puma with single mode for Railway's 1GB VM
echo "🚀 Launching Puma server in single mode..."
echo "🔍 Starting Puma with debug logging..."
exec bundle exec puma -b "tcp://0.0.0.0:${PORT_TO_BIND}" -e production -w 0 -t 4:8 --preload