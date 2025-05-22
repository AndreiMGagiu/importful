# frozen_string_literal: true

module Affiliates
  module Import
    # Orchestrates the affiliate import process, handling parsing, normalization,
    # row-by-row processing, and error tracking.
    class Orchestrator
      # Error types that are considered recoverable and will be
      # added to the result errors instead of raising.
      HANDLED_ERRORS = [
        Affiliates::Import::Parser::MissingHeadersError,
        CSV::MalformedCSVError
      ].freeze

      # @param file [ActionDispatch::Http::UploadedFile, IO, String]
      def initialize(file)
        @file = file
        @result = Result.new
      end

      # Executes the full import process.
      # @return [Result] encapsulating all stats and errors
      def call
        process_rows(parse_file)
        result
      rescue *HANDLED_ERRORS => error
        handle_known_error(error)
      rescue StandardError => error
        handle_unexpected_error(error)
      end

      private

      attr_reader :file, :result

      def parse_file
        Parser.new(file).call
      end

      # Iterates over each row and processes it.
      def process_rows(rows)
        rows.each_with_index do |raw_row, index|
          process_row(raw_row, index + 2) # +2 for header row and 0-indexing
        end
      end

      # Normalizes, sanitizes, and processes a row, updating result stats.
      def process_row(raw_row, line)
        row_hash = extract_row_hash(raw_row)
        processed_row = RowProcessor.new(row_hash).call
        Processor.new(processed_row, result, line).call
      end

      # Converts CSV::Row to Hash with symbol keys for consistency.
      def extract_row_hash(raw_row)
        raw_row.respond_to?(:to_h) ? raw_row.to_h.symbolize_keys : raw_row.symbolize_keys
      end

      # Handles known error types gracefully.
      def handle_known_error(error)
        case error
        when Affiliates::Import::Parser::MissingHeadersError
          result.add_error("Missing required headers: #{error.missing.join(', ')}")
        when CSV::MalformedCSVError
          result.add_error("Invalid CSV format: #{error.message}")
        end
        result
      end

      # Handles truly unexpected errors (logs, then surfaces error).
      def handle_unexpected_error(error)
        Rails.logger.error(message: 'Affiliates import error', error: e.message)
        result.add_error("Unexpected import error: #{error.message}")
        result
      end
    end
  end
end
