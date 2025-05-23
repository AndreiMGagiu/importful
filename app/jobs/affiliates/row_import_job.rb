module Affiliates
  # A Sidekiq worker responsible for importing individual CSV rows asynchronously.
  # Processes a single row, runs validations and transformations, and updates the audit log.
  class RowImportJob
    include Sidekiq::Worker
    sidekiq_options queue: 'row_import'

    # Performs the row import process.
    #
    # @param raw_row [Hash] the raw CSV row data with string keys
    # @param line [Integer] the line number of the row in the original CSV file
    # @param audit_id [Integer] the ID of the ImportAudit record to track success/failure
    # @return [void]
    def perform(raw_row, line, audit_id)
      row_hash = raw_row.transform_keys(&:to_sym)
      processed_row = Import::RowProcessor.new(row_hash).call
      Import::Processor.new(processed_row, Import::Result.new, line).call

      ImportAudit.increment_counter(:total_successful_rows, audit_id)
    rescue => e
      ImportAudit.increment_counter(:total_failed_rows, audit_id)
      Rails.logger.error(message: "Row import error on line #{line}", error: e.message)
    end
  end
end
