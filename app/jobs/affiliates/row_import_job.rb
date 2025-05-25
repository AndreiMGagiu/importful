# frozen_string_literal: true

module Affiliates
  # Background job for importing a single row from a CSV file.
  #
  # This job delegates row processing to `Affiliates::Import::RowImport`,
  # handling success/failure updates to the associated ImportAudit.
  #
  class RowImportJob
    include Sidekiq::Worker
    sidekiq_options queue: 'row_import'

    # Performs the job by processing a single CSV row.
    #
    # @param raw_row [Hash] The CSV row represented as a Hash with string keys
    # @param line [Integer] The line number in the original CSV file
    # @param audit_id [Integer] ID of the associated ImportAudit
    # @return [void]
    def perform(raw_row, line, audit_id)
      Import::RowImport.new(raw_row, line, audit_id).call
    end
  end
end
