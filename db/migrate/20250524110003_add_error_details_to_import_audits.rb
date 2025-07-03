# frozen_string_literal: true

class AddErrorDetailsToImportAudits < ActiveRecord::Migration[8.0]
  def up
    add_column :import_audits, :error_details, :text
  end

  def down
    remove_column :import_audits, :error_details, :text
  end
end
