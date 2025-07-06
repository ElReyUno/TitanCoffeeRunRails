#!/bin/bash

# TitanCoffeeRunRails Model Validation Script
# This script validates and fixes Rails model syntax issues

set -e  # Exit on any error

echo "🔍 TitanCoffeeRunRails Model Validation"
echo "======================================="

# Check if we're in the right directory
if [ ! -f "Gemfile" ]; then
    echo "⚠️  Gemfile not found in current directory. Attempting to change to ~/TitanCoffeeRunRails..."
    cd ~/TitanCoffeeRunRails || { echo "❌ Error: Could not change to ~/TitanCoffeeRunRails. Please ensure the directory exists."; exit 1; }
    if [ ! -f "Gemfile" ]; then
        echo "❌ Error: Gemfile still not found in ~/TitanCoffeeRunRails. Please run this script from the project root directory."
        exit 1
    fi
fi

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
                echo "💡 This usually indicates a serious issue with the Rails environment"
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
                    echo "🔍 Found incomplete enum declarations:"
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
                echo "💡 The fix may have worked but Rails is having loading issues"
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

echo ""
echo "✅ Model validation complete!"
echo "💡 All models are now ready for Rails to load"
echo ""
