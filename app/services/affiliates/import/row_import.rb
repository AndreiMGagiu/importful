# frozen_string_literal: true

module Affiliates
  module Import
    # Service that processes a single row of a CSV import and updates the associated ImportAudit.
    # Handles row-level validation, processing, audit tracking, and error logging.
    #
    # @example
    #   raw_row = { 'email' => 'user@example.com', ... }
    #   line = 2
    #   audit_id = 42
    #   Affiliates::Import::RowImport.new(raw_row, line, audit_id).call
    class RowImport
      # @param raw_row [Hash{String => String}] The raw CSV row as string-keyed hash
      # @param line [Integer] Line number in the CSV file (for error context)
      # @param audit_id [Integer] ID of the associated ImportAudit record
      def initialize(raw_row, line, audit_id)
        @raw_row = raw_row
        @line = line
        @audit_id = audit_id
      end

      # Executes the row import, updating the audit record accordingly.
      #
      # @return [void]
      def call
        return unless audit

        update_audit(process_row)
      end

      private

      attr_reader :raw_row, :line, :audit_id

      # Lazily loads the associated ImportAudit.
      #
      # @return [ImportAudit, nil]
      def audit
        @audit ||= ImportAudit.find_by(id: audit_id)
      end

      # Processes the row using the row processor and importer, capturing errors if any.
      #
      # @return [Affiliates::Import::Result]
      def process_row
        result = Result.new
        processed_row = RowProcessor.new(raw_row.symbolize_keys).call
        Processor.new(processed_row, result, line).call
        result
      rescue StandardError => error
        log_error(result, error)
        result
      end

      # Applies metrics and final status to the audit.
      #
      # @param result [Affiliates::Import::Result]
      # @return [void]
      def update_audit(result)
        audit.with_lock do
          update_metrics(result)
          audit.status = determine_status
          audit.save!
        end
      end

      # Updates success/failure counters based on result.
      #
      # @param result [Affiliates::Import::Result]
      # @return [void]
      def update_metrics(result)
        return increment_failed(result) unless successful?(result)

        audit.increment!(:total_successful_rows)
      end

      # Increments failure counter and appends error messages.
      #
      # @param result [Affiliates::Import::Result]
      # @return [void]
      def increment_failed(result)
        audit.increment!(:total_failed_rows)
        result.errors.each { |err| audit.append_error_detail(err.message) }
      end

      # @param result [Affiliates::Import::Result]
      # @return [Boolean] true if the row is valid and has no errors
      def successful?(result)
        result.errors.empty?
      end

      # Determines the final audit status after processing.
      #
      # @return [String] 'processed' or 'processed_with_errors'
      def determine_status
        return audit.status unless audit.status == 'pending'

        audit.total_failed_rows.to_i.positive? ? 'processed_with_errors' : 'processed'
      end

      # Logs unexpected processing errors and appends them to the result.
      #
      # @param result [Affiliates::Import::Result]
      # @param error [StandardError]
      # @return [void]
      def log_error(result, error)
        result.add_error("Line #{line}: Unexpected error - #{error.message}", line: line)
        Rails.logger.error(
          message: "Row import error on line #{line}",
          error: error.message,
          backtrace: error.backtrace&.take(10)
        )
      end
    end
  end
end
