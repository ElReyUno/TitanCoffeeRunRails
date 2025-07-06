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
