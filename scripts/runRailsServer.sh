#!/bin/bash

# TitanCoffeeRunRails Server Launcher
# This script quickly starts the Rails server with optional setup checks

set -e  # Exit on any error

echo "🚀 TitanCoffeeRunRails Server Launcher"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "Gemfile" ]; then
    echo "⚠️  Gemfile not found in current directory. Attempting to change to ~/TitanCoffeeRunRails..."
    cd ~/TitanCoffeeRunRails || { echo "❌ Error: Could not change to ~/TitanCoffeeRunRails. Please ensure the directory exists."; exit 1; }
    if [ ! -f "Gemfile" ]; then
        echo "❌ Error: Gemfile still not found in ~/TitanCoffeeRunRails. Please run this script from the project root directory."
        exit 1
    fi
fi

# Quick Rails environment check
echo "� Checking Rails environment..."

# Check if basic Rails environment is ready
set +e  # Don't exit on command failure
rails_check_output=$(timeout 10s bundle exec rails runner "puts 'Rails environment: ' + Rails.env" 2>&1)
rails_check_result=$?
set -e  # Re-enable exit on error

if [ $rails_check_result -eq 0 ]; then
    echo "✅ Rails environment ready: $rails_check_output"
elif [ $rails_check_result -eq 124 ]; then
    echo "❌ Rails environment check timed out (10s)"
    echo "💡 This suggests serious configuration or model issues"
    echo ""
    echo "� Available setup scripts to fix issues:"
    echo "   1) './scripts/setupEnvironment.sh' - Set up Ruby, gems, and databases"
    echo "   2) './scripts/validateModels.sh' - Fix model syntax errors (enum issues, etc.)"
    echo "   3) './scripts/qualityCheck.sh' - Run tests and code quality checks"
    echo ""
    read -p "Would you like to run setupEnvironment.sh now? (Y/n): " run_setup
    if [[ ! $run_setup =~ ^[Nn]$ ]]; then
        echo "🔧 Running environment setup..."
        ./scripts/setupEnvironment.sh
        echo "🔄 Retrying Rails environment check..."
        if bundle exec rails runner "puts 'Rails environment: ' + Rails.env" 2>/dev/null; then
            echo "✅ Rails environment is now ready!"
        else
            echo "❌ Still having issues. You may need to run './scripts/validateModels.sh'"
            exit 1
        fi
    else
        echo "❌ Cannot start server with broken Rails environment"
        exit 1
    fi
else
    echo "❌ Rails environment has errors:"
    echo "----------------------------------------"
    echo "$rails_check_output"
    echo "----------------------------------------"
    echo ""
    echo "🔧 This is usually caused by:"
    echo "   • Missing gems (run './scripts/setupEnvironment.sh')"
    echo "   • Model syntax errors (run './scripts/validateModels.sh')"
    echo "   • Database issues (run './scripts/setupEnvironment.sh')"
    echo ""
    echo "� Available setup scripts:"
    echo "   1) './scripts/setupEnvironment.sh' - Set up Ruby, gems, and databases"
    echo "   2) './scripts/validateModels.sh' - Fix model syntax errors (enum issues, etc.)"
    echo "   3) './scripts/qualityCheck.sh' - Run tests and code quality checks"
    echo ""
    read -p "Would you like to run setupEnvironment.sh to fix common issues? (Y/n): " run_setup
    if [[ ! $run_setup =~ ^[Nn]$ ]]; then
        echo "� Running environment setup..."
        ./scripts/setupEnvironment.sh
        echo "🔄 Retrying Rails environment check..."
        if bundle exec rails runner "puts 'Rails environment: ' + Rails.env" 2>/dev/null; then
            echo "✅ Rails environment is now ready!"
        else
            echo "⚠️  Still having issues. Checking if it's a model syntax problem..."
            read -p "Would you like to run model validation to fix syntax errors? (Y/n): " run_models
            if [[ ! $run_models =~ ^[Nn]$ ]]; then
                echo "🔧 Running model validation..."
                ./scripts/validateModels.sh
                echo "🔄 Final Rails environment check..."
                if bundle exec rails runner "puts 'Rails environment: ' + Rails.env" 2>/dev/null; then
                    echo "✅ Rails environment is now ready!"
                else
                    echo "❌ Still having issues. Manual intervention may be required."
                    echo "💡 Check the error output above and fix any remaining issues manually."
                    exit 1
                fi
            else
                echo "❌ Cannot start server with broken Rails environment"
                exit 1
            fi
        fi
    else
        echo "❌ Cannot start server with broken Rails environment"
        exit 1
    fi
fi

# Optional quality checks before starting server
echo ""
read -p "🔍 Would you like to run quality checks before starting? (y/N): " run_quality
if [[ $run_quality =~ ^[Yy]$ ]]; then
    echo "� Running quality checks..."
    ./scripts/qualityCheck.sh
fi

echo ""
echo "🎉 Starting Rails server..."
echo "📱 Access the app at: http://localhost:3000"
echo "⏹️  Press Ctrl+C to stop the server"
echo ""
echo "� Next time you can start faster by ensuring your environment is set up!"
echo ""

# Start the Rails server with better error handling
if ! bundle exec rails server --binding=0.0.0.0 --port=3000; then
    echo ""
    echo "❌ Rails server failed to start!"
    echo "💡 Try these troubleshooting steps:"
    echo "   1. Check if port 3000 is already in use: lsof -i :3000"
    echo "   2. Run: './scripts/setupEnvironment.sh' to fix environment issues"
    echo "   3. Run: './scripts/validateModels.sh' to fix model syntax errors"
    echo "   4. Check logs in log/development.log"
    exit 1
fi