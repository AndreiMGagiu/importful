# frozen_string_literal: true

class ImportAudit < ApplicationRecord
  VALID_STATUSES = %w[pending processed processed_with_errors failed].freeze
  VALID_IMPORT_TYPES = %w[affiliate].freeze

  validates :path, presence: true
  validates :status, presence: true, inclusion: { in: VALID_STATUSES }
  validates :import_type, presence: true, inclusion: { in: VALID_IMPORT_TYPES }

  serialize :error_details, coder: JSON

  def append_error_detail(detail)
    with_lock do
      self.error_details = (error_details || []) + [detail]
      save!
    end
  end
end
