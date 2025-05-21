class CreateAffiliates < ActiveRecord::Migration[8.0]
  def change
    create_table :affiliates do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.decimal :commissions_total, null: false, precision: 10, scale: 2, default: 0
      t.string :website_url

      t.timestamps
    end
    add_index :affiliates, [ :merchant_id, :email ], unique: true
  end
end
