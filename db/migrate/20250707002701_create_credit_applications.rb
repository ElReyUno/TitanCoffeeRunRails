class CreateCreditApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_applications do |t|
      t.string :email
      t.string :re_enter_email
      t.string :first_name
      t.string :last_name
      t.string :city
      t.string :state
      t.string :zip
      t.decimal :gross_income
      t.string :ssn_last_four
      t.boolean :apply_for_credit
      t.boolean :qualified
      t.decimal :credit_limit

      t.timestamps
    end
  end
end
