class CreateImportAudits < ActiveRecord::Migration[8.0]
  def up
    create_table :import_audits do |t|
      t.string  :path, null: false
      t.string  :filename
      t.string  :status, null: false, default: 'pending'
      t.string  :import_type, null: false
      t.integer :total_successful_rows
      t.integer :total_failed_rows
      t.text    :error_message
      t.datetime :processed_at

      t.timestamps
    end
  end

  def down
    drop_table :import_audits
  end
end
