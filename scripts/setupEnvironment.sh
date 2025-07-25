#!/bin/bash

# TitanCoffeeRunRails Environment Setup Script
# This script sets up Ruby, dependencies, and databases for the Rails application

set -e  # Exit on any error

echo "🔧 TitanCoffeeRunRails Environment Setup"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "Gemfile" ]; then
    echo "⚠️  Gemfile not found in current directory. Attempting to change to ~/TitanCoffeeRunRails..."
    cd ~/TitanCoffeeRunRails || { echo "❌ Error: Could not change to ~/TitanCoffeeRunRails. Please ensure the directory exists."; exit 1; }
    if [ ! -f "Gemfile" ]; then
        echo "❌ Error: Gemfile still not found in ~/TitanCoffeeRunRails. Please run this script from the project root directory."
        exit 1
    fi
fi

# Check Ruby version
echo "📋 Checking Ruby version..."
REQUIRED_RUBY="3.3.6"

if command -v rbenv &> /dev/null; then
    echo "🔧 Using rbenv for Ruby management"
    
    # Check if required Ruby version is installed
    if ! rbenv versions | grep -q "$REQUIRED_RUBY"; then
        echo "⚠️  Ruby $REQUIRED_RUBY not installed via rbenv"
        echo ""
        echo "Choose an option:"
        echo "1) Install Ruby $REQUIRED_RUBY (recommended)"
        echo "2) Continue with current Ruby version (may cause issues)"
        echo "3) Exit and install manually"
        echo ""
        read -p "Enter your choice (1/2/3): " ruby_choice
        
        case $ruby_choice in
            1)
                echo "📥 Installing Ruby $REQUIRED_RUBY..."
                echo "⏳ This may take 5-15 minutes depending on your system..."
                echo "💡 You'll see compilation output - this is normal!"
                echo "🛑 DO NOT interrupt this process - let it complete!"
                echo ""
                
                # Temporarily disable exit on error for the installation
                set +e
                
                # Start installation in background to show progress
                rbenv install "$REQUIRED_RUBY" --verbose &
                install_pid=$!
                
                # Show progress while waiting
                while kill -0 $install_pid 2>/dev/null; do
                    echo "⏳ Still installing Ruby... ($(date '+%H:%M:%S'))"
                    sleep 30
                done
                
                # Wait for the process to complete and get exit code
                wait $install_pid
                install_result=$?
                
                # Re-enable exit on error
                set -e
                
                if [ $install_result -eq 0 ]; then
                    echo "✅ Ruby $REQUIRED_RUBY installed successfully!"
                    # Reload rbenv to recognize new installation
                    rbenv rehash
                    rbenv local "$REQUIRED_RUBY"
                    echo "🔄 Set local Ruby version to $REQUIRED_RUBY"
                else
                    echo "❌ Ruby installation failed with exit code: $install_result"
                    echo "💡 Common fixes:"
                    echo "   - Install build dependencies: sudo apt-get install build-essential"
                    echo "   - Try manually: rbenv install $REQUIRED_RUBY"
                    echo "   - Check rbenv doctor: curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-doctor | bash"
                    exit 1
                fi
                ;;
            2)
                echo "⚠️  Continuing with available Ruby version..."
                # Don't set local version, use whatever is available
                ;;
            3|*)
                echo "❌ Exiting. Install Ruby $REQUIRED_RUBY with: rbenv install $REQUIRED_RUBY"
                exit 1
                ;;
        esac
    else
        # Set local Ruby version if it's already installed
        rbenv local "$REQUIRED_RUBY"
    fi
    
elif command -v ruby &> /dev/null; then
    RUBY_VERSION=$(ruby -v)
    echo "✅ Ruby found: $RUBY_VERSION"
    
    # Check if it's the right version
    if ! echo "$RUBY_VERSION" | grep -q "$REQUIRED_RUBY"; then
        echo "⚠️  Warning: Expected Ruby $REQUIRED_RUBY, but found: $RUBY_VERSION"
        read -p "Continue anyway? (y/N): " continue_anyway
        if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    echo "❌ Error: Ruby not found. Please install Ruby $REQUIRED_RUBY"
    echo "💡 Consider using rbenv: https://github.com/rbenv/rbenv#installation"
    exit 1
fi

echo "✅ Ruby version check complete"

# Check Bundler
echo "📋 Checking Bundler..."
if command -v bundle &> /dev/null; then
    echo "✅ Bundler found"
else
    echo "⚠️  Bundler not found. Installing..."
    gem install bundler
fi

# Install dependencies
echo "📦 Installing Ruby dependencies..."
bundle install

# Database setup
echo "🗄️  Setting up databases..."

# Check for existing databases (Rails 8 uses multiple SQLite databases)
PRIMARY_DB="db/development.sqlite3"
CACHE_DB="db/cache.sqlite3"
QUEUE_DB="db/queue.sqlite3"
CABLE_DB="db/cable.sqlite3"

# Function to check if any database exists
check_databases() {
    local db_count=0
    [ -f "$PRIMARY_DB" ] && ((db_count++))
    [ -f "$CACHE_DB" ] && ((db_count++))
    [ -f "$QUEUE_DB" ] && ((db_count++))
    [ -f "$CABLE_DB" ] && ((db_count++))
    echo $db_count
}

existing_dbs=$(check_databases)

if [ $existing_dbs -eq 0 ]; then
    echo "📥 No databases found. Creating fresh database setup..."
    
    # Temporarily disable exit on error to handle schema issues
    set +e
    bundle exec rails db:setup
    setup_result=$?
    set -e
    
    if [ $setup_result -ne 0 ]; then
        echo "❌ Database setup failed!"
        echo ""
        echo "This usually happens when schema.rb doesn't exist yet."
        echo "Choose a fix:"
        echo "1) Run 'bin/rails db:migrate' to create schema.rb"
        echo "2) Exit and fix manually"
        echo "3) Continue anyway (may cause Rails startup issues)"
        echo ""
        read -p "Enter your choice (1/2/3): " fix_choice
        
        case $fix_choice in
            1)
                echo "🔧 Running db:migrate to create schema.rb..."
                bundle exec rails db:create
                bundle exec rails db:migrate
                echo "✅ Schema created. Attempting setup again..."
                bundle exec rails db:setup
                ;;
            2)
                echo "🔄 Please run the following manually:"
                echo "   bin/rails db:migrate"
                echo "   Then rerun this script or the server script"
                exit 1
                ;;
            3)
                echo "⚠️  Continuing anyway - Rails may fail to start..."
                ;;
            *)
                echo "❌ Invalid choice. Exiting."
                exit 1
                ;;
        esac
    else
        echo "✅ Database setup completed successfully!"
    fi
elif [ $existing_dbs -eq 4 ]; then
    echo "✅ All databases exist. Running migrations to ensure they're up to date..."
    bundle exec rails db:migrate
else
    echo "⚠️  Partial database setup detected ($existing_dbs/4 databases found)"
    echo "Found databases:"
    [ -f "$PRIMARY_DB" ] && echo "  ✅ Primary database"
    [ -f "$CACHE_DB" ] && echo "  ✅ Cache database"
    [ -f "$QUEUE_DB" ] && echo "  ✅ Queue database"
    [ -f "$CABLE_DB" ] && echo "  ✅ Cable database"
    echo ""
    echo "Choose an option:"
    echo "1) Reset all databases (recommended for clean start)"
    echo "2) Try to migrate existing databases"
    echo "3) Continue without database changes"
    echo ""
    read -p "Enter your choice (1/2/3): " db_choice
    
    case $db_choice in
        1)
            echo "🔄 Resetting all databases..."
            bundle exec rails db:drop db:setup
            ;;
        2)
            echo "🔄 Attempting to migrate existing databases..."
            bundle exec rails db:create db:migrate
            ;;
        3)
            echo "⚠️  Continuing without database changes..."
            ;;
        *)
            echo "❌ Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

echo ""
echo "✅ Environment setup complete!"
echo "💡 You can now run './scripts/runRailsServer.sh' to start the server quickly"
echo ""
