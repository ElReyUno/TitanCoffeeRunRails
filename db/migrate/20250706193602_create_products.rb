class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :price
      t.text :available_sizes
      t.boolean :active

      t.timestamps
    end
  end
end
