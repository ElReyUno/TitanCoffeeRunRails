class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :total_amount
      t.text :notes
      t.integer :status
      t.decimal :titan_fund_donation

      t.timestamps
    end
  end
end
