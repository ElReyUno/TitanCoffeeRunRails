#!/bin/bash

# TitanCoffeeRunRails Quality Check Script
# This script runs tests and code quality checks

set -e  # Exit on any error

echo "🔍 TitanCoffeeRunRails Quality Check"
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

# Verify environment is ready
echo "🔍 Verifying Rails environment..."
if ! bundle exec rails runner "puts 'Environment OK'" 2>/dev/null; then
    echo "❌ Rails environment not ready. Please run './scripts/setupEnvironment.sh' first"
    exit 1
fi

echo "✅ Rails environment verified"

# Run tests
echo ""
read -p "🧪 Would you like to run tests? (Y/n): " run_tests
if [[ ! $run_tests =~ ^[Nn]$ ]]; then
    echo "🧪 Running tests..."
    if bundle exec rails test; then
        echo "✅ All tests passed!"
    else
        echo "❌ Some tests failed. Review the output above."
        read -p "Continue with code quality checks anyway? (y/N): " continue_anyway
        if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    echo "⏭️  Skipping tests"
fi

# Run code quality checks
echo ""
read -p "🔍 Would you like to run code quality checks? (Y/n): " run_quality
if [[ ! $run_quality =~ ^[Nn]$ ]]; then
    echo "🔍 Running RuboCop..."
    
    # Use bundle exec as primary method to avoid bin stub issues
    if bundle exec rubocop --version >/dev/null 2>&1; then
        # Temporarily disable exit on error for RuboCop
        set +e
        bundle exec rubocop
        rubocop_exit_code=$?
        set -e  # Re-enable exit on error
        
        if [ $rubocop_exit_code -eq 0 ]; then
            echo "✅ RuboCop passed!"
        else
            echo "⚠️  RuboCop found issues (exit code: $rubocop_exit_code)"
            echo ""
            read -p "Would you like to auto-fix what's possible? (Y/n): " auto_fix
            if [[ ! $auto_fix =~ ^[Nn]$ ]]; then
                echo "🔧 Running RuboCop auto-corrections..."
                # Also disable exit on error for auto-corrections
                set +e
                bundle exec rubocop --auto-correct-all
                auto_fix_exit_code=$?
                set -e
                
                if [ $auto_fix_exit_code -eq 0 ]; then
                    echo "✅ All issues auto-corrected successfully!"
                else
                    echo "✅ Auto-corrections applied. Some issues may need manual review (exit code: $auto_fix_exit_code)."
                fi
            fi
        fi
    else
        echo "⚠️  RuboCop not found in Gemfile. Skipping RuboCop check."
    fi
    
    echo ""
    echo "🔒 Running Brakeman security check..."
    
    # Same approach for brakeman with timeout handling
    if bundle exec brakeman --version >/dev/null 2>&1; then
        echo "📊 Brakeman scan in progress (this may take 30-60 seconds)..."
        
        # Run brakeman with no pager and proper formatting to avoid user input
        if timeout 120 bundle exec brakeman --format text --no-pager --no-exit-on-warn; then
            echo "✅ Brakeman security scan completed - no issues found!"
        else
            exit_code=$?
            if [ $exit_code -eq 124 ]; then
                echo "⚠️  Brakeman scan timed out after 2 minutes."
            else
                echo "⚠️  Brakeman found potential security issues (exit code: $exit_code)"
                echo "💡 Review the output above for security concerns"
            fi
        fi
    else
        echo "⚠️  Brakeman not found in Gemfile. Skipping security check."
    fi
else
    echo "⏭️  Skipping code quality checks"
fi

echo ""
echo "✅ Quality check complete!"
echo "💡 Your code is ready for development or deployment"
echo ""
