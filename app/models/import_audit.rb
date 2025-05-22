class ImportAudit < ApplicationRecord
  VALID_STATUSES = %w[pending uploaded processing processed failed].freeze
  VALID_IMPORT_TYPES = %w[affiliate].freeze

  validates :path, presence: true
  validates :status, presence: true, inclusion: { in: VALID_STATUSES }
  validates :import_type, presence: true, inclusion: { in: VALID_IMPORT_TYPES }
end
