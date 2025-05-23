# frozen_string_literal: true

module Affiliates
  module Import
    # Orchestrator is responsible for handling the overall flow of CSV affiliate imports.
    # It parses the CSV, delegates each row to Sidekiq workers, and tracks errors.
    class Orchestrator
      # Errors that are caught and added to the result object instead of raising.
      HANDLED_ERRORS = [
        Parser::MissingHeadersError,
        CSV::MalformedCSVError
      ].freeze

      # @param file [IO, Tempfile] The CSV file or stream
      # @param audit [ImportAudit] The associated audit record
      def initialize(file, audit)
        @file = file
        @audit = audit
        @result = Result.new
      end

      # Runs the import orchestration: parsing and delegating row jobs.
      #
      # @return [Result] the result object tracking import stats and errors
      def call
        process_rows(parse_file)
        result
      rescue *HANDLED_ERRORS => error
        handle_known_error(error)
      rescue StandardError => error
        handle_unexpected_error(error)
      end

      private

      # @return [CSV::Table] parsed rows from the file
      def parse_file
        Parser.new(file).call
      end

      # Enqueues each row to a Sidekiq worker for background processing.
      #
      # @param rows [CSV::Table] parsed rows from the CSV file
      # @return [void]
      def process_rows(rows)
        rows.each_with_index do |raw_row, index|
          RowImportWorker.perform_async(
            raw_row.to_h.transform_keys(&:to_s),
            index + 2,
            audit.id
          )
        end
      end

      # Handles expected errors and adds them to the result object.
      #
      # @param error [StandardError]
      # @return [Result]
      def handle_known_error(error)
        case error
        when Parser::MissingHeadersError
          result.add_error("Missing required headers: #{error.missing.join(', ')}")
        when CSV::MalformedCSVError
          result.add_error("Invalid CSV format: #{error.message}")
        end
        result
      end

      # Handles unexpected runtime errors and logs them.
      #
      # @param error [StandardError]
      # @return [Result]
      def handle_unexpected_error(error)
        Rails.logger.error(message: 'Affiliates import error', error: error.message)
        result.add_error("Unexpected import error: #{error.message}")
        result
      end

      # @return [IO] The file object being imported
      # @return [Result] The import result tracker
      # @return [ImportAudit] The associated audit record
      attr_reader :file, :result, :audit
    end
  end
end
