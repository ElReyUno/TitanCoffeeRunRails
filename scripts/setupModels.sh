#!/bin/bash

# Titans Coffee Run Rails - Model Setup Script
# This script automates the setup of models, migrations, and basic configuration
# for integrating the Titans Coffee Run frontend into Rails

set -e  # Exit on any error

echo "🏗️  Setting up Titans Coffee Run Rails Models & Database..."
echo "=================================================="

# Function to find and navigate to Rails project root
find_rails_root() {
    local current_dir="$(pwd)"
    local search_dir="$current_dir"
    
    # Look for Rails project root up to 3 levels up
    for i in {0..3}; do
        if [ -f "$search_dir/Gemfile" ] && [ -f "$search_dir/config/application.rb" ]; then
            if [ "$search_dir" != "$current_dir" ]; then
                echo "📁 Found Rails project root: $search_dir"
                cd "$search_dir"
            fi
            return 0
        fi
        search_dir="$(dirname "$search_dir")"
    done
    
    echo "❌ Error: Not in a Rails project directory"
    echo "Please run this script from the Rails project root or a subdirectory"
    echo "Current directory: $current_dir"
    exit 1
}

# Function to check if we're in a Rails project
check_rails_project() {
    find_rails_root
    echo "✅ Running from Rails project root: $(pwd)"
}

# Function to check system dependencies
check_dependencies() {
    echo "🔍 Checking system dependencies..."
    
    # Check if Ruby is installed
    if ! command -v ruby &> /dev/null; then
        echo "❌ Error: Ruby is not installed"
        echo "Please install Ruby 3.3.6 or later"
        exit 1
    fi
    
    # Check Ruby version
    ruby_version=$(ruby -v | cut -d' ' -f2)
    echo "✅ Ruby version: $ruby_version"
    
    # Check if Rails is available
    if ! command -v rails &> /dev/null; then
        echo "❌ Error: Rails is not installed"
        echo "Please install Rails: gem install rails"
        exit 1
    fi
    
    # Check Rails version
    rails_version=$(rails -v | cut -d' ' -f2)
    echo "✅ Rails version: $rails_version"
    
    # Check if Bundler is installed
    if ! command -v bundle &> /dev/null; then
        echo "❌ Error: Bundler is not installed"
        echo "Please install Bundler: gem install bundler"
        exit 1
    fi
    
    echo "✅ Bundler version: $(bundle -v)"
    
    # Check if SQLite3 is available (Rails 8 default)
    if ! gem list sqlite3 -i &> /dev/null; then
        echo "⚠️  Warning: SQLite3 gem may not be installed"
        echo "This will be handled by bundle install"
    fi
    
    # Check if we can write to necessary directories
    if [ ! -w "." ]; then
        echo "❌ Error: No write permission in current directory"
        exit 1
    fi
    
    echo "✅ All system dependencies check passed"
}

# Function to check Rails application state
check_rails_state() {
    echo "🔍 Checking Rails application state..."
    
    # Check if database exists
    if [ -f "db/development.sqlite3" ]; then
        echo "✅ Development database exists"
    else
        echo "ℹ️  Development database will be created"
    fi
    
    # Check if there are pending migrations
    if rails db:migrate:status &> /dev/null; then
        echo "✅ Database migration status accessible"
    else
        echo "ℹ️  Database may need initial setup"
    fi
    
    # Check if application can boot (quick test)
    if timeout 10s rails runner "puts 'Rails app can boot'" &> /dev/null; then
        echo "✅ Rails application can boot successfully"
    else
        echo "⚠️  Warning: Rails application may have boot issues"
        echo "Continuing with setup - this may resolve boot issues"
    fi
}

# Function to validate Gemfile structure
check_gemfile_structure() {
    echo "🔍 Validating Gemfile structure..."
    
    # Check if Gemfile has required Rails gems
    if ! grep -q "gem ['\"]rails['\"]" Gemfile; then
        echo "❌ Error: Rails gem not found in Gemfile"
        exit 1
    fi
    
    # Check for development/test group
    if ! grep -q "group :development, :test do" Gemfile; then
        echo "ℹ️  No development/test group found - will create one"
    fi
    
    # Check if Gemfile.lock exists
    if [ -f "Gemfile.lock" ]; then
        echo "✅ Gemfile.lock exists"
    else
        echo "ℹ️  Gemfile.lock will be created during bundle install"
    fi
    
    echo "✅ Gemfile structure validation passed"
}

# Function to add gems to Gemfile if not already present
add_gem_if_missing() {
    local gem_name="$1"
    local gem_line="$2"
    
    # More thorough check for existing gems (handles quotes, spacing, comments)
    if grep -q "gem.*['\"]${gem_name}['\"]" Gemfile; then
        echo "✅ ${gem_name} gem already present in Gemfile"
        return 0
    fi
    
    echo "📦 Adding ${gem_name} gem to Gemfile..."
    
    # Add to appropriate section based on gem type
    if [[ "$gem_line" == *"group :development, :test"* ]]; then
        # Add to development/test group
        if grep -q "group :development, :test do" Gemfile; then
            # Insert after the group declaration line
            sed -i "/group :development, :test do/a\\  gem '${gem_name}'" Gemfile
        else
            # Create the group if it doesn't exist
            echo "" >> Gemfile
            echo "group :development, :test do" >> Gemfile
            echo "  gem '${gem_name}'" >> Gemfile
            echo "end" >> Gemfile
        fi
    else
        # Add to main gems section (before any group blocks)
        if grep -q "^group" Gemfile; then
            # Insert before first group
            sed -i "/^group/i\\gem '${gem_name}'" Gemfile
        else
            # No groups found, append to end
            echo "gem '${gem_name}'" >> Gemfile
        fi
    fi
}

# Function to clean duplicate gems from Gemfile
clean_duplicate_gems() {
    echo "🧹 Checking for duplicate gems in Gemfile..."
    
    # Create a backup
    cp Gemfile Gemfile.backup-$(date +%s)
    
    # List of gems we're adding
    local gems=("devise" "pundit" "image_processing" "rspec-rails" "factory_bot_rails" "capybara" "selenium-webdriver")
    
    for gem in "${gems[@]}"; do
        # Count occurrences of each gem
        local count=$(grep -c "gem.*['\"]${gem}['\"]" Gemfile || true)
        
        if [ "$count" -gt 1 ]; then
            echo "⚠️  Found ${count} occurrences of ${gem} gem, removing duplicates..."
            
            # Keep only the first occurrence, remove the rest
            # Create temp file with duplicates removed
            awk -v gem="$gem" '
            BEGIN { found = 0 }
            /gem.*["'"'"']/ {
                if ($0 ~ gem && found == 0) {
                    print $0
                    found = 1
                } else if ($0 ~ gem && found == 1) {
                    next
                } else {
                    print $0
                }
                next
            }
            { print $0 }
            ' Gemfile > Gemfile.tmp && mv Gemfile.tmp Gemfile
            
            echo "✅ Cleaned up ${gem} duplicates"
        fi
    done
    
    echo "✅ Gemfile duplicate check complete"
}

# Function to run Rails generators safely
run_generator() {
    local generator_cmd="$1"
    echo "🔧 Running: $generator_cmd"
    
    if eval "$generator_cmd"; then
        echo "✅ Generator completed successfully"
    else
        echo "⚠️  Generator may have failed or files already exist"
        # Don't exit on generator failures - they might be due to existing files
        return 1
    fi
}

# Function to safely run bundle install with error handling
safe_bundle_install() {
    echo "📦 Installing gem dependencies..."
    
    if bundle install; then
        echo "✅ Bundle install completed successfully"
    else
        echo "❌ Bundle install failed"
        echo "Try running manually: bundle install"
        exit 1
    fi
}

# Function to safely run database operations
safe_db_operations() {
    echo "🗄️  Running database operations..."
    
    # Try to create database first (in case it doesn't exist)
    if rails db:create &> /dev/null; then
        echo "✅ Database created or already exists"
    fi
    
    # Run migrations
    if rails db:migrate; then
        echo "✅ Database migrations completed"
    else
        echo "❌ Database migrations failed"
        echo "Please check the migration files and try again"
        exit 1
    fi
    
    # Run seeds
    if rails db:seed; then
        echo "✅ Database seeding completed"
    else
        echo "❌ Database seeding failed"
        echo "Please check the seed file and try again"
        exit 1
    fi
}

# Check if we're in the right directory
check_rails_project

# Run dependency checks
check_dependencies
check_rails_state
check_gemfile_structure

echo ""
echo "📋 Step 1: Adding required gems to Gemfile..."
echo "============================================="

# Add production gems
add_gem_if_missing "devise" "gem 'devise'"
add_gem_if_missing "pundit" "gem 'pundit'"
add_gem_if_missing "image_processing" "gem 'image_processing'"

# Add development/test gems
add_gem_if_missing "rspec-rails" "group :development, :test"
add_gem_if_missing "factory_bot_rails" "group :development, :test"
add_gem_if_missing "capybara" "group :development, :test"
add_gem_if_missing "selenium-webdriver" "group :development, :test"

# Clean up any duplicates
clean_duplicate_gems

echo ""
echo "📦 Step 2: Installing gem dependencies..."
echo "========================================"
safe_bundle_install

echo ""
echo "🔐 Step 3: Setting up Devise authentication..."
echo "============================================="

# Install Devise
if [ ! -f "config/initializers/devise.rb" ]; then
    run_generator "rails generate devise:install"
else
    echo "✅ Devise already installed"
fi

# Generate Devise User model
if [ ! -f "app/models/user.rb" ]; then
    run_generator "rails generate devise User admin:boolean"
else
    echo "✅ User model already exists"
fi

echo ""
echo "🏪 Step 4: Creating Product model..."
echo "==================================="
if [ ! -f "app/models/product.rb" ]; then
    run_generator "rails generate model Product name:string price:decimal available_sizes:text active:boolean"
else
    echo "✅ Product model already exists"
fi

echo ""
echo "📋 Step 5: Creating Order model..."
echo "=================================="
if [ ! -f "app/models/order.rb" ]; then
    run_generator "rails generate model Order user:references total_amount:decimal notes:text status:integer titan_fund_donation:decimal"
else
    echo "✅ Order model already exists"
fi

echo ""
echo "🛒 Step 6: Creating OrderItem model..."
echo "====================================="
if [ ! -f "app/models/order_item.rb" ]; then
    run_generator "rails generate model OrderItem order:references product:references size:string quantity:integer unit_price:decimal subtotal:decimal"
else
    echo "✅ OrderItem model already exists"
fi

echo ""
echo "🗄️  Step 7: Setting up database..."
echo "================================="
safe_db_operations

# Create seeds.rb with Titans Coffee Run specific data
cat > db/seeds.rb << 'EOF'
# Titans Coffee Run Seed Data

puts "🌱 Seeding Titans Coffee Run data..."

# Create admin user
admin_email = 'admin@titanscoffee.com'
admin = User.find_by(email: admin_email)

if admin.nil?
  admin = User.create!(
    email: admin_email,
    password: 'test123',
    password_confirmation: 'test123',
    admin: true
  )
  puts "✅ Created admin user: #{admin_email}"
else
  puts "✅ Admin user already exists: #{admin_email}"
end

# Create products based on Titans Coffee Run frontend
products_data = [
  { name: 'Cappuccino', price: 9.00, available_sizes: ['Small', 'Medium', 'Large'] },
  { name: 'Macaroons', price: 4.00, available_sizes: ['Small', 'Medium', 'Large'] },
  { name: 'Donuts', price: 5.00, available_sizes: ['Small', 'Medium', 'Large'] }
]

products_data.each do |product_data|
  product = Product.find_by(name: product_data[:name])
  
  if product.nil?
    Product.create!(
      name: product_data[:name],
      price: product_data[:price],
      available_sizes: product_data[:available_sizes].to_json,
      active: true
    )
    puts "✅ Created product: #{product_data[:name]} ($#{product_data[:price]})"
  else
    puts "✅ Product already exists: #{product_data[:name]}"
  end
end

# Create a sample regular user for testing
regular_email = 'user@titanscoffee.com'
regular_user = User.find_by(email: regular_email)

if regular_user.nil?
  regular_user = User.create!(
    email: regular_email,
    password: 'password123',
    password_confirmation: 'password123',
    admin: false
  )
  puts "✅ Created regular user: #{regular_email}"
else
  puts "✅ Regular user already exists: #{regular_email}"
end

puts ""
puts "🎉 Seed data complete!"
puts "📊 Database Summary:"
puts "   - Users: #{User.count} (#{User.where(admin: true).count} admin, #{User.where(admin: false).count} regular)"
puts "   - Products: #{Product.count}"
puts "   - Orders: #{Order.count}"
puts ""
puts "🔑 Login Credentials:"
puts "   Admin: admin@titanscoffee.com / test123"
puts "   User:  user@titanscoffee.com / password123"
EOF

echo ""
echo "📁 Step 8: Creating basic controller structure..."
echo "=============================================="

# Create HomeController
if [ ! -f "app/controllers/home_controller.rb" ]; then
    mkdir -p app/controllers
    cat > app/controllers/home_controller.rb << 'EOF'
class HomeController < ApplicationController
  # Landing page - no authentication required
  def index
  end
end
EOF
    echo "✅ Created HomeController"
else
    echo "✅ HomeController already exists"
fi

# Create ProductsController
if [ ! -f "app/controllers/products_controller.rb" ]; then
    cat > app/controllers/products_controller.rb << 'EOF'
class ProductsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @products = Product.where(active: true)
    @cart_items = session[:cart] || {}
  end
end
EOF
    echo "✅ Created ProductsController"
else
    echo "✅ ProductsController already exists"
fi

# Create OrdersController
if [ ! -f "app/controllers/orders_controller.rb" ]; then
    cat > app/controllers/orders_controller.rb << 'EOF'
class OrdersController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @orders = current_user.orders.includes(:order_items, :products)
  end
  
  def show
    @order = current_user.orders.find(params[:id])
  end
  
  def create
    @order = current_user.orders.build(order_params)
    
    if @order.save
      process_cart_items
      session[:cart] = nil
      redirect_to @order, notice: 'Order was successfully created.'
    else
      redirect_to products_path, alert: 'There was an error creating your order.'
    end
  end
  
  private
  
  def order_params
    params.require(:order).permit(:notes, :titan_fund_donation)
  end
  
  def process_cart_items
    cart_items = session[:cart] || {}
    cart_items.each do |product_id, item_data|
      product = Product.find(product_id)
      @order.order_items.create!(
        product: product,
        size: item_data['size'],
        quantity: item_data['quantity'],
        unit_price: product.price
      )
    end
  end
end
EOF
    echo "✅ Created OrdersController"
else
    echo "✅ OrdersController already exists"
fi

# Create Admin controllers directory and base controller
mkdir -p app/controllers/admin

if [ ! -f "app/controllers/admin/base_controller.rb" ]; then
    cat > app/controllers/admin/base_controller.rb << 'EOF'
class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  
  private
  
  def ensure_admin
    redirect_to root_path, alert: 'Access denied.' unless current_user&.admin?
  end
end
EOF
    echo "✅ Created Admin::BaseController"
else
    echo "✅ Admin::BaseController already exists"
fi

if [ ! -f "app/controllers/admin/sales_controller.rb" ]; then
    cat > app/controllers/admin/sales_controller.rb << 'EOF'
class Admin::SalesController < Admin::BaseController
  def index
    @orders = Order.includes(:user, :order_items, :products)
    @sales_data = calculate_sales_data
  end
  
  private
  
  def calculate_sales_data
    {
      total_orders: Order.count,
      total_revenue: Order.sum(:total_amount),
      this_month_orders: Order.where(created_at: Time.current.beginning_of_month..Time.current.end_of_month).count,
      this_month_revenue: Order.where(created_at: Time.current.beginning_of_month..Time.current.end_of_month).sum(:total_amount)
    }
  end
end
EOF
    echo "✅ Created Admin::SalesController"
else
    echo "✅ Admin::SalesController already exists"
fi

echo ""
echo "🛣️  Step 9: Adding basic routes..."
echo "=================================="

# Check if routes need to be added
if ! grep -q "devise_for :users" config/routes.rb; then
    # Backup existing routes
    cp config/routes.rb config/routes.rb.backup
    
    # Create new routes file with Titans Coffee Run routes
    cat > config/routes.rb << 'EOF'
Rails.application.routes.draw do
  devise_for :users
  root 'home#index'
  
  resources :products, only: [:index]
  resources :orders, only: [:index, :show, :create]
  
  namespace :admin do
    resources :sales, only: [:index]
    resources :products
    resources :orders, only: [:index, :show, :update]
  end
  
  # API routes for AJAX requests (future enhancement)
  namespace :api do
    namespace :v1 do
      resources :cart_items, only: [:create, :update, :destroy]
      resources :sales, only: [:index]
    end
  end
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  
  # PWA files
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
EOF
    echo "✅ Updated routes.rb (backup saved as routes.rb.backup)"
else
    echo "✅ Routes already configured"
fi

echo ""
echo "🎉 Setup Complete!"
echo "================="
echo ""
echo "✅ What was created:"
echo "   • User authentication with Devise"
echo "   • Product, Order, and OrderItem models"
echo "   • Database migrations and seed data"
echo "   • Basic controllers for Home, Products, Orders, and Admin"
echo "   • Routes configuration"
echo ""
echo "📋 Next Steps (Manual):"
echo "   1. Customize model associations and validations"
echo "   2. Create view templates (ERB files)"
echo "   3. Migrate frontend assets (CSS, JS, images)"
echo "   4. Implement proper authentication flows"
echo "   5. Add authorization with Pundit policies"
echo ""
echo "🚀 To start the Rails server:"
echo "   rails server"
echo ""
echo "🔗 Access the application:"
echo "   • Frontend: http://localhost:3000"
echo "   • Admin Panel: http://localhost:3000/admin/sales"
echo ""
echo "🔑 Test Credentials:"
echo "   • Admin: admin@titanscoffee.com / test123"
echo "   • User:  user@titanscoffee.com / password123"
echo ""
echo "📖 For detailed implementation steps, see:"
echo "   Titans-Coffee-Run/TitansCoffeeRunProjectAnalysis.md"