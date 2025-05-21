class CreateMerchants < ActiveRecord::Migration[8.0]
  def change
    create_table :merchants do |t|
      t.string :slug, null: false

      t.timestamps
    end
    add_index :merchants, :slug, unique: true
  end
end
