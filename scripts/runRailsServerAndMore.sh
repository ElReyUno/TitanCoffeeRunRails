#!/bin/bash

# TitanCoffeeRunRails Launch Script
# This script sets up and launches the Rails application

set -e  # Exit on any error

echo "🚀 TitanCoffeeRunRails Launch Script"
echo "===================================="

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

# Quick Rails environment check
echo "🔍 Testing Rails environment..."
echo "📋 Running: timeout 15s bundle exec rails runner \"puts 'Rails environment: ' + Rails.env\""

set +e  # Don't exit on command failure
rails_env_output=$(timeout 15s bundle exec rails runner "puts 'Rails environment: ' + Rails.env" 2>&1)
rails_env_result=$?
set -e  # Re-enable exit on error

echo "📋 Rails environment test exit code: $rails_env_result"
if [ $rails_env_result -eq 0 ]; then
    echo "✅ Rails environment is working: $rails_env_output"
elif [ $rails_env_result -eq 124 ]; then
    echo "⚠️  Rails environment test timed out - there may be serious configuration issues"
    echo "💡 This could indicate:"
    echo "   - Missing or corrupted gems"
    echo "   - Database connection issues"
    echo "   - Model syntax errors preventing Rails from starting"
    echo "   - Missing required files"
    echo ""
    read -p "Continue anyway? (y/N): " continue_env_issues
    if [[ ! $continue_env_issues =~ ^[Yy]$ ]]; then
        echo "❌ Stopping due to Rails environment issues"
        echo "💡 Try running: bundle install"
        echo "💡 Or check: bundle exec rails console"
        exit 1
    fi
else
    echo "⚠️  Rails environment has issues:"
    echo "----------------------------------------"
    echo "$rails_env_output"
    echo "----------------------------------------"
    echo "💡 Continuing with model validation to identify specific issues..."
fi

# Validate Models First
echo "🔍 Validating Rails models..."

# Function to check for common model issues
validate_models() {
    echo "📋 Checking Rails models..."
    
    # Function to check if a model exists and loads correctly
    check_model_health() {
        local model_name="$1"
        local model_file="app/models/${model_name}.rb"
        
        if [ -f "$model_file" ]; then
            echo "✅ ${model_name^} model found - checking if it loads correctly..."
            
            # Test if the model loads without errors
            echo "🔍 Testing ${model_name^} model loading..."
            echo "📋 Running: timeout 30s bundle exec rails runner '${model_name^}; puts \"${model_name^} model loads successfully\"'"
            
            # Use timeout to prevent hanging and capture both stdout and stderr
            set +e  # Don't exit on command failure
            model_test_output=$(timeout 30s bundle exec rails runner "${model_name^}; puts '${model_name^} model loads successfully'" 2>&1)
            model_test_result=$?
            set -e  # Re-enable exit on error
            
            echo "📋 Command exit code: $model_test_result"
            echo "📋 Command output:"
            echo "----------------------------------------"
            echo "$model_test_output"
            echo "----------------------------------------"
            
            if [ $model_test_result -eq 0 ]; then
                echo "✅ Existing ${model_name^} model works perfectly - leaving it unchanged"
                return 0  # Model exists and works
            elif [ $model_test_result -eq 124 ]; then
                echo "⚠️  ${model_name^} model test timed out after 30 seconds"
                echo "� This usually indicates a serious issue with the Rails environment"
                return 1  # Model test timed out
            else
                echo "⚠️  Existing ${model_name^} model has syntax errors or loading issues"
                return 1  # Model exists but has errors
            fi
        else
            echo "ℹ️  No ${model_name^} model found - will be created by migrations if needed"
            return 2  # Model doesn't exist
        fi
    }
    
    # Check if Order model exists and works
    check_model_health "order"
    order_status=$?
    
    if [ $order_status -eq 0 ]; then
        # Model exists and works - we're done with Order model
        echo "✅ Order model validation complete"
    elif [ $order_status -eq 1 ]; then
        # Model exists but has errors - try to fix it
        echo "🔍 Analyzing the error..."
        
        # Get the specific error with verbose output
        echo "📋 Running: bundle exec rails runner 'Order' to capture error details..."
        model_error=$(bundle exec rails runner "Order" 2>&1 || true)
        
        echo "📋 Raw error output:"
        echo "----------------------------------------"
        echo "$model_error"
        echo "----------------------------------------"
        
        # Improved enum error detection - flexible pattern matching
        echo "🔍 Checking error patterns..."
        
        # Check for enum-related errors
        has_wrong_args=false
        has_enum_error=false
        has_enum_syntax_error=false
        
        if echo "$model_error" | grep -q "wrong number of arguments"; then
            echo "✅ Found 'wrong number of arguments' in error"
            has_wrong_args=true
        else
            echo "❌ Did NOT find 'wrong number of arguments' in error"
        fi
        
        if echo "$model_error" | grep -qi "enum"; then
            echo "✅ Found 'enum' in error"
            has_enum_error=true
        else
            echo "❌ Did NOT find 'enum' in error"
        fi
        
        # Check for various enum-related error patterns (flexible)
        if echo "$model_error" | grep -q "enum.rb.*wrong number of arguments" || \
           echo "$model_error" | grep -q "enum.*wrong number of arguments" || \
           echo "$model_error" | grep -q "given 0, expected 1" || \
           echo "$model_error" | grep -q "app/models/.*\.rb.*enum" || \
           (echo "$model_error" | grep -q "ArgumentError" && echo "$model_error" | grep -qi "enum"); then
            echo "✅ Found enum syntax error pattern"
            has_enum_syntax_error=true
        else
            echo "❌ Did NOT find specific enum syntax error pattern"
        fi
        
        # More flexible condition for enum errors
        if ($has_wrong_args && $has_enum_error) || $has_enum_syntax_error; then
            echo "🔧 Detected enum syntax error - attempting Rails 8 compatible fix..."
            
            # Create backup with timestamp
            backup_file="app/models/order.rb.backup.$(date +%Y%m%d_%H%M%S)"
            cp app/models/order.rb "$backup_file"
            echo "📁 Backup created: $backup_file"
            
            # Try to fix just the enum syntax while preserving the rest
            echo "🔧 Attempting to fix enum syntax while preserving existing structure..."
            
            # Get Rails version to determine correct enum syntax
            rails_version=$(bundle exec rails --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
            echo "📋 Detected Rails version: $rails_version"
            
            # For Rails 7+, fix common enum syntax issues
            if [[ "$rails_version" > "6.9" ]]; then
                echo "🔧 Applying comprehensive enum syntax fixes for Rails 8..."
                echo "📋 Before transformation:"
                grep -n -A5 -B2 "enum" app/models/order.rb || echo "No enum lines found"
                
                # Step 1: Fix old Rails enum syntax patterns
                echo "🔧 Step 1: Converting old enum syntax to Rails 8 hash syntax"
                
                # Fix various old enum patterns
                sed -i 's/enum :status, {/enum status: {/g' app/models/order.rb
                sed -i 's/enum :status,{/enum status:{/g' app/models/order.rb
                sed -i 's/enum :status$/enum status:/g' app/models/order.rb
                
                # Fix generic enum field patterns
                sed -i 's/enum :\([a-zA-Z_][a-zA-Z0-9_]*\), {/enum \1: {/g' app/models/order.rb
                sed -i 's/enum :\([a-zA-Z_][a-zA-Z0-9_]*\),{/enum \1:{/g' app/models/order.rb
                sed -i 's/enum :\([a-zA-Z_][a-zA-Z0-9_]*\)$/enum \1:/g' app/models/order.rb
                
                # Step 2: Fix incomplete enum declarations (main issue)
                echo "🔧 Step 2: Fixing incomplete enum declarations"
                
                # Find incomplete enum declarations and handle them intelligently
                incomplete_enums=$(grep -n "enum [a-zA-Z_][a-zA-Z0-9_]*:$" app/models/order.rb || true)
                
                if [ -n "$incomplete_enums" ]; then
                    echo "� Found incomplete enum declarations:"
                    echo "$incomplete_enums"
                    echo ""
                    echo "❓ These enum declarations are missing their values, which causes the ArgumentError."
                    echo "   The script can:"
                    echo "   1) Comment them out for manual completion (recommended)"
                    echo "   2) Add placeholder values that you can customize later"
                    echo "   3) Skip and let you fix manually"
                    echo ""
                    read -p "Choose option (1/2/3): " enum_fix_choice
                    
                    case $enum_fix_choice in
                        1)
                            echo "🔧 Commenting out incomplete enum declarations..."
                            sed -i 's/^[[:space:]]*enum \([a-zA-Z_][a-zA-Z0-9_]*\):$/  # TODO: Complete this enum definition\n  # enum \1: { value1: 0, value2: 1, value3: 2 }/' app/models/order.rb
                            echo "✅ Incomplete enums commented out. You can uncomment and complete them later."
                            ;;
                        2)
                            echo "🔧 Adding placeholder values to incomplete enums..."
                            # For each incomplete enum, add generic placeholder values
                            while IFS= read -r line; do
                                if [ -n "$line" ]; then
                                    enum_name=$(echo "$line" | sed 's/.*enum \([a-zA-Z_][a-zA-Z0-9_]*\):$/\1/')
                                    echo "  📝 Adding placeholder values for '$enum_name' enum"
                                    sed -i "/enum ${enum_name}:$/c\\
  # TODO: Customize these ${enum_name} values for your application\\
  enum ${enum_name}: {\\
    value1: 0,\\
    value2: 1,\\
    value3: 2\\
  }" app/models/order.rb
                                fi
                            done <<< "$incomplete_enums"
                            echo "✅ Added placeholder values. Please customize them for your application."
                            ;;
                        3)
                            echo "⏭️  Skipping enum fix. You'll need to complete the enum declarations manually."
                            echo "💡 Example: enum status: { pending: 0, confirmed: 1, completed: 2 }"
                            ;;
                        *)
                            echo "❌ Invalid choice. Commenting out incomplete enums (safe default)."
                            sed -i 's/^[[:space:]]*enum \([a-zA-Z_][a-zA-Z0-9_]*\):$/  # TODO: Complete this enum definition\n  # enum \1: { value1: 0, value2: 1, value3: 2 }/' app/models/order.rb
                            ;;
                    esac
                else
                    echo "✅ No incomplete enum declarations found"
                fi
                
                # Step 3: Ensure proper multi-line formatting
                echo "🔧 Step 3: Applying multi-line formatting best practices"
                
                # Convert single-line enums to multi-line if they exist
                if grep -q "enum status: {.*}$" app/models/order.rb; then
                    echo "🔧 Converting single-line enum to multi-line format for readability"
                    sed -i '/enum status: {.*}$/{
                        s/enum status: {\(.*\)}/enum status: { \n    \1\n  }/
                        s/, /,\n    /g
                        s/{ /{\n    /
                        s/ }$/,\n  }/
                    }' app/models/order.rb
                fi
                
                echo "📋 After transformation:"
                grep -n -A10 -B2 "enum" app/models/order.rb || echo "No enum lines found"
            fi
            
            # Test if the fix worked
            echo "🔧 Testing if the enum fix worked..."
            echo "📋 Running: timeout 30s bundle exec rails runner 'Order; puts \"Order model fixed successfully\"'"
            
            set +e  # Don't exit on command failure
            fix_test_output=$(timeout 30s bundle exec rails runner "Order; puts 'Order model fixed successfully'" 2>&1)
            fix_test_result=$?
            set -e  # Re-enable exit on error
            
            echo "📋 Fix test exit code: $fix_test_result"
            echo "📋 Fix test output:"
            echo "----------------------------------------"
            echo "$fix_test_output"
            echo "----------------------------------------"
            
            if [ $fix_test_result -eq 0 ]; then
                echo "✅ Successfully fixed enum syntax while preserving existing model"
            elif [ $fix_test_result -eq 124 ]; then
                echo "⚠️  Enum fix test timed out after 30 seconds"
                echo "� The fix may have worked but Rails is having loading issues"
            else
                echo "⚠️  Enum fix didn't work - see error details above"
                echo "💡 Backup available at: $backup_file"
                echo "🔍 You can compare: diff $backup_file app/models/order.rb"
                
                read -p "Continue anyway? (y/N): " continue_anyway
                if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
                    echo "🔄 Restoring backup..."
                    cp "$backup_file" app/models/order.rb
                    exit 1
                fi
            fi
        else
            echo "❌ Unexpected model error (not enum-related):"
            echo "$model_error"
            echo "💡 The existing Order model has issues that need manual review"
            read -p "Continue anyway? (y/N): " continue_anyway
            if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        # Model doesn't exist - that's fine, migrations will create it if needed
        echo "💡 The script will continue without creating a placeholder model"
    fi
    
    # Check other models (User, Product, OrderItem) with minimal intervention
    echo "📋 Checking other models..."
    
    # Use the helper function for all other models
    for model in "user" "product" "order_item"; do
        check_model_health "$model"
        model_status=$?
        
        if [ $model_status -eq 1 ]; then
            # Model exists but has issues - just warn, don't try to fix
            echo "⚠️  ${model^} model has issues but leaving it for manual review"
        fi
    done
}

# Run model validation
validate_models

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
    
    # Test model loading before attempting database operations
    echo "🔍 Testing model loading..."
    echo "📋 Running: timeout 30s bundle exec rails runner \"puts 'Models loaded successfully'\""
    
    set +e  # Don't exit on command failure
    model_load_output=$(timeout 30s bundle exec rails runner "puts 'Models loaded successfully'" 2>&1)
    model_load_result=$?
    set -e  # Re-enable exit on error
    
    echo "📋 Model loading exit code: $model_load_result"
    echo "📋 Model loading output:"
    echo "----------------------------------------"
    echo "$model_load_output"
    echo "----------------------------------------"
    
    if [ $model_load_result -eq 0 ]; then
        echo "✅ Models can be loaded without errors"
    elif [ $model_load_result -eq 124 ]; then
        echo "⚠️  Model loading timed out after 30 seconds"
        echo "💡 This indicates a serious Rails environment issue"
        echo "� Attempting basic Rails connectivity test..."
        
        # Try a simpler test
        simple_test_output=$(timeout 15s bundle exec rails runner "puts 'Basic test'" 2>&1 || echo "FAILED")
        echo "📋 Simple test result: $simple_test_output"
    else
        echo "❌ Model loading failed - there may be syntax errors"
        echo "💡 Attempting to fix common model issues..."
        
        # Try to identify and fix the specific error
        model_error=$(bundle exec rails runner "puts 'test'" 2>&1 || true)
        
        # Improved enum error detection - check for multiple patterns
        if (echo "$model_error" | grep -q "wrong number of arguments" && echo "$model_error" | grep -q "enum") || echo "$model_error" | grep -q "enum.rb.*wrong number of arguments"; then
            echo "🔧 Detected enum syntax error - attempting intelligent fix..."
            
            # Fix the enum syntax issue
            if [ -f "app/models/order.rb" ]; then
                # Backup the existing model
                backup_file="app/models/order.rb.backup.$(date +%Y%m%d_%H%M%S)"
                cp app/models/order.rb "$backup_file"
                echo "📁 Backup created: $backup_file"
                
                # Apply the same intelligent enum fixes as in the main validation function
                echo "🔧 Applying intelligent enum syntax fixes..."
                
                # Fix old enum syntax patterns
                sed -i 's/enum :\([a-zA-Z_][a-zA-Z0-9_]*\), {/enum \1: {/g' app/models/order.rb
                sed -i 's/enum :\([a-zA-Z_][a-zA-Z0-9_]*\),{/enum \1:{/g' app/models/order.rb
                sed -i 's/enum :\([a-zA-Z_][a-zA-Z0-9_]*\)$/enum \1:/g' app/models/order.rb
                
                # Handle incomplete enum declarations
                incomplete_enums=$(grep -n "enum [a-zA-Z_][a-zA-Z0-9_]*:$" app/models/order.rb || true)
                
                if [ -n "$incomplete_enums" ]; then
                    echo "🔍 Found incomplete enum declarations - commenting them out for safety:"
                    echo "$incomplete_enums"
                    sed -i 's/^[[:space:]]*enum \([a-zA-Z_][a-zA-Z0-9_]*\):$/  # TODO: Complete this enum definition\n  # enum \1: { value1: 0, value2: 1, value3: 2 }/' app/models/order.rb
                    echo "✅ Incomplete enums commented out. Please complete them manually."
                fi
                
                echo "✅ Applied intelligent enum fixes while preserving your model structure"
                
                # Test again
                echo "🔧 Testing fixed model..."
                echo "📋 Running: timeout 30s bundle exec rails runner \"puts 'Models fixed successfully'\""
                
                set +e  # Don't exit on command failure
                model_fix_output=$(timeout 30s bundle exec rails runner "puts 'Models fixed successfully'" 2>&1)
                model_fix_result=$?
                set -e  # Re-enable exit on error
                
                echo "📋 Model fix test exit code: $model_fix_result"
                echo "📋 Model fix test output:"
                echo "----------------------------------------"
                echo "$model_fix_output"
                echo "----------------------------------------"
                
                if [ $model_fix_result -eq 0 ]; then
                    echo "✅ Model syntax errors resolved"
                elif [ $model_fix_result -eq 124 ]; then
                    echo "⚠️  Model fix test timed out after 30 seconds"
                    echo "💡 The fix may have worked but Rails is having loading issues"
                else
                    echo "❌ Still having model issues - check the error output above"
                    echo "💡 You may need to manually fix model syntax"
                    read -p "Continue anyway? (y/N): " continue_anyway
                    if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
                        exit 1
                    fi
                fi
            fi
        else
            echo "❌ Unexpected model error:"
            echo "$model_error"
            read -p "Continue anyway? (y/N): " continue_anyway
            if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    
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
        echo "2) Rerun this script after manual fix"
        echo "3) Continue anyway (may cause Rails startup issues)"
        echo ""
        read -p "Enter your choice (1/2/3): " fix_choice
        
        case $fix_choice in
            1)
                echo "🔧 Attempting database repair with adaptive approach..."
                
                # Check what databases actually exist
                echo "📋 Checking current database state..."
                if [ -f "db/schema.rb" ]; then
                    echo "✅ Schema file exists"
                else
                    echo "ℹ️  No schema.rb found"
                fi
                
                # Check for migration files
                migration_count=$(find db/migrate -name "*.rb" 2>/dev/null | wc -l || echo "0")
                echo "📊 Found $migration_count migration files"
                
                # Adaptive database setup
                set +e  # Don't exit on errors, handle them gracefully
                
                # Step 1: Ensure databases exist (safe operation)
                echo "🔧 Step 1: Ensuring databases exist..."
                bundle exec rails db:create 2>/dev/null
                db_create_result=$?
                if [ $db_create_result -eq 0 ]; then
                    echo "✅ Database creation completed"
                else
                    echo "ℹ️  Databases may already exist (this is normal)"
                fi
                
                # Step 2: Run migrations only if they exist
                if [ $migration_count -gt 0 ]; then
                    echo "🔧 Step 2: Running $migration_count migrations..."
                    bundle exec rails db:migrate
                    migrate_result=$?
                    if [ $migrate_result -eq 0 ]; then
                        echo "✅ Migrations completed successfully"
                    else
                        echo "❌ Migration failed - checking if we can continue..."
                        echo "💡 This might be due to model syntax errors we detected earlier"
                        read -p "Try to continue with existing database state? (y/N): " continue_with_errors
                        if [[ ! $continue_with_errors =~ ^[Yy]$ ]]; then
                            set -e
                            exit 1
                        fi
                    fi
                else
                    echo "ℹ️  No migrations found - skipping db:migrate"
                fi
                
                # Step 3: Check if schema.rb was created/updated
                if [ -f "db/schema.rb" ]; then
                    echo "✅ Schema file now exists"
                    
                    # Step 4: Only try db:setup if we have a schema
                    echo "🔧 Step 3: Attempting database setup..."
                    bundle exec rails db:setup
                    setup_result=$?
                    if [ $setup_result -eq 0 ]; then
                        echo "✅ Database setup completed successfully!"
                        set -e  # Re-enable exit on error
                    else
                        echo "❌ Database setup still failed"
                        echo "💡 This is likely due to seed data issues or remaining model problems"
                        echo ""
                        echo "🔍 Checking what's working:"
                        
                        # Test basic Rails connectivity
                        rails_test_output=$(bundle exec rails runner "puts 'Rails loads: OK'" 2>&1)
                        rails_test_result=$?
                        
                        if [ $rails_test_result -eq 0 ]; then
                            echo "✅ Rails application loads successfully"
                        else
                            echo "❌ Rails application has loading issues"
                            echo "📋 Rails loading error:"
                            echo "$rails_test_output"
                        fi
                        
                        # Check if tables exist
                        tables_test_output=$(bundle exec rails runner "puts 'Tables: ' + ActiveRecord::Base.connection.tables.count.to_s" 2>&1)
                        tables_test_result=$?
                        
                        if [ $tables_test_result -eq 0 ]; then
                            echo "✅ Database tables are accessible"
                            echo "$tables_test_output"
                        else
                            echo "❌ Database tables are not accessible"
                            echo "📋 Tables access error:"
                            echo "$tables_test_output"
                        fi
                        
                        echo ""
                        read -p "Continue anyway? Rails might work without seed data (y/N): " continue_without_seeds
                        if [[ ! $continue_without_seeds =~ ^[Yy]$ ]]; then
                            set -e
                            exit 1
                        fi
                        set -e  # Re-enable exit on error
                    fi
                else
                    echo "❌ Schema file still doesn't exist after migrations"
                    echo "💡 This suggests there may be no valid migrations or other issues"
                    set -e
                    exit 1
                fi
                ;;
            2)
                echo "🔄 Please run the following manually, then rerun this script:"
                echo "   1. Check your migrations: ls -la db/migrate/"
                echo "   2. Run: bin/rails db:migrate"
                echo "   3. Check for errors in your models"
                echo "   4. Run: bin/rails db:seed (optional)"
                echo ""
                read -p "Press Enter to rerun this script, or Ctrl+C to exit..."
                exec "$0" "$@"  # Rerun the entire script
                ;;
            3)
                echo "⚠️  Continuing anyway - Rails may fail to start..."
                echo "💡 You can manually run database commands later if needed"
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

# Optional: Run tests
read -p "🧪 Would you like to run tests before starting? (y/N): " run_tests
if [[ $run_tests =~ ^[Yy]$ ]]; then
    echo "🧪 Running tests..."
    bundle exec rails test
fi

# Optional: Run code quality checks
read -p "🔍 Would you like to run code quality checks? (y/N): " run_quality
if [[ $run_quality =~ ^[Yy]$ ]]; then
    echo "🔍 Running RuboCop..."
    
    # Use bundle exec as primary method to avoid bin stub issues
    if bundle exec rubocop --version >/dev/null 2>&1; then
        echo "📊 Starting RuboCop analysis and auto-fix process..."
        
        # RuboCop auto-fix loop
        max_attempts=5
        attempt=1
        rubocop_success=false
        
        while [ $attempt -le $max_attempts ] && [ "$rubocop_success" = false ]; do
            echo "🔄 RuboCop attempt $attempt/$max_attempts..."
            
            # Run RuboCop and capture exit code
            set +e  # Don't exit on RuboCop errors
            rubocop_output=$(bundle exec rubocop --format progress --display-cop-names 2>&1)
            rubocop_exit_code=$?
            set -e  # Re-enable exit on error
            
            case $rubocop_exit_code in
                0)
                    echo "✅ RuboCop passed! No issues found."
                    rubocop_success=true
                    ;;
                1)
                    echo "⚠️  RuboCop found issues. Attempting auto-fix..."
                    echo "📋 Issues found:"
                    echo "$rubocop_output" | grep -E "(Offense|offenses|Convention|Refactor|Warning|Error)" | head -10
                    
                    # Try auto-fix with safe corrections first
                    echo "🔧 Running safe auto-corrections..."
                    if bundle exec rubocop --auto-correct --safe 2>/dev/null; then
                        echo "✅ Applied safe auto-corrections"
                    else
                        echo "⚠️  Some safe corrections couldn't be applied"
                    fi
                    
                    # If still failing, try unsafe corrections (more aggressive)
                    if [ $attempt -ge 2 ]; then
                        echo "🔧 Running unsafe auto-corrections (attempt $attempt)..."
                        if bundle exec rubocop --auto-correct-all 2>/dev/null; then
                            echo "✅ Applied unsafe auto-corrections"
                        else
                            echo "⚠️  Some unsafe corrections couldn't be applied"
                        fi
                    fi
                    
                    # Check if we made progress
                    set +e
                    new_output=$(bundle exec rubocop --format progress 2>&1)
                    new_exit_code=$?
                    set -e
                    
                    if [ $new_exit_code -eq 0 ]; then
                        echo "✅ All RuboCop issues resolved!"
                        rubocop_success=true
                    elif [ $attempt -eq $max_attempts ]; then
                        echo "⚠️  Maximum attempts reached. Remaining issues require manual intervention:"
                        echo ""
                        echo "📋 Final RuboCop report:"
                        bundle exec rubocop --format simple | head -20
                        echo ""
                        echo "💡 Common manual fixes needed:"
                        echo "   - Complex refactoring suggestions"
                        echo "   - Method length or complexity issues"
                        echo "   - Style preferences that need design decisions"
                        echo ""
                        read -p "Continue anyway? (y/N): " continue_rubocop
                        if [[ ! $continue_rubocop =~ ^[Yy]$ ]]; then
                            echo "❌ Stopping due to RuboCop issues. Fix manually and rerun."
                            exit 1
                        fi
                    else
                        echo "🔄 Some issues remain, trying next approach..."
                    fi
                    ;;
                2)
                    echo "❌ RuboCop configuration error or critical issues found"
                    echo "$rubocop_output"
                    read -p "Continue anyway? (y/N): " continue_rubocop_error
                    if [[ ! $continue_rubocop_error =~ ^[Yy]$ ]]; then
                        exit 1
                    fi
                    break
                    ;;
                *)
                    echo "❌ Unexpected RuboCop exit code: $rubocop_exit_code"
                    echo "$rubocop_output"
                    break
                    ;;
            esac
            
            ((attempt++))
        done
        
        if [ "$rubocop_success" = true ]; then
            echo "✅ RuboCop validation completed successfully!"
        else
            echo "⚠️  RuboCop completed with remaining issues that need manual review"
        fi
    else
        echo "⚠️  RuboCop not found in Gemfile. Skipping RuboCop check."
    fi
    
    echo "🔒 Running Brakeman security check..."
    
    # Same approach for brakeman with timeout handling
    if bundle exec brakeman --version >/dev/null 2>&1; then
        echo "📊 Brakeman scan in progress (this may take 30-60 seconds)..."
        
        # Run brakeman with no pager and proper formatting to avoid user input
        timeout 120 bundle exec brakeman --format text --no-pager --no-exit-on-warn || {
            exit_code=$?
            if [ $exit_code -eq 124 ]; then
                echo "⚠️  Brakeman scan timed out after 2 minutes. Continuing..."
            elif [ $exit_code -ne 0 ]; then
                echo "⚠️  Brakeman completed with warnings/issues (exit code: $exit_code)"
                echo "💡 Review the output above for security concerns"
            fi
        }
        echo "✅ Brakeman security scan completed"
    else
        echo "⚠️  Brakeman not found in Gemfile. Skipping security check."
    fi
fi

echo ""
echo "🎉 Setup complete! Starting Rails server..."
echo "📱 Access the app at: http://localhost:3000"
echo "⏹️  Press Ctrl+C to stop the server"
echo ""

# Start the Rails server with better error handling
echo "🚀 Starting Rails server..."
echo "📍 Server will be available at: http://localhost:3000"
echo "⏹️  Press Ctrl+C to stop the server"
echo ""

# Try to start the server with error handling
if ! bin/rails server --binding=0.0.0.0 --port=3000; then
    echo ""
    echo "❌ Rails server failed to start!"
    echo "💡 Try these troubleshooting steps:"
    echo "   1. Check if port 3000 is already in use: lsof -i :3000"
    echo "   2. Run: bundle exec rails server instead"
    echo "   3. Check logs in log/development.log"
    exit 1
fi
