# frozen_string_literal: true

require 'csv'

module Affiliates
  module Import
    # Parser handles parsing CSV files or content for affiliate imports.
    # It auto-detects delimiters, normalizes headers, and ensures all required columns are present.
    # Supports string input, IO objects, Tempfile, and ActionDispatch::Http::UploadedFile.
    class Parser
      CANDIDATE_SEPARATORS = [',', ';', "\t", ':'].freeze

      REQUIRED_HEADERS = %i[merchant_slug first_name last_name email].freeze

      # Custom error for missing headers in the import file
      class MissingHeadersError < StandardError
        attr_reader :missing

        # @param missing [Array<Symbol>] missing header names
        def initialize(missing)
          @missing = missing
          super("Missing required headers: #{missing.join(', ')}")
        end
      end

      # @param file_or_content [String, IO, Tempfile, ActionDispatch::Http::UploadedFile]
      # The file object or raw CSV string to parse
      def initialize(file_or_content)
        @input = file_or_content
      end

      # Parses the CSV input and returns a CSV::Table.
      # Automatically detects column separator and handles UTF-8 BOM.
      #
      # @return [CSV::Table] parsed CSV data
      # @raise [MissingHeadersError] if any required header is missing
      # @raise [CSV::MalformedCSVError] if the CSV is not well-formed
      def call
        csv = CSV.parse(
          content,
          headers: true,
          header_converters: :symbol,
          col_sep: detect_separator,
          skip_blanks: true
        )
        assert_required_headers!(csv.headers)
        csv
      end

      private

      attr_reader :input

      # Reads and returns the raw file content as a string.
      # Handles string, IO, Tempfile, or UploadedFile.
      # Removes BOM if present.
      #
      # @return [String]
      def content
        @content ||= extract_content
      end

      def extract_content
        case input
        when String
          remove_bom(input)
        when IO, StringIO, Tempfile
          input.rewind
          remove_bom(input.read)
        else
          input.tempfile.rewind
          remove_bom(input.tempfile.read)
        end
      end

      # Removes a UTF-8 BOM from the beginning of the string if present.
      #
      # @param str [String]
      # @return [String]
      def remove_bom(str)
        str.delete_prefix("\uFEFF")
      end

      # Auto-detects the CSV column separator from sample content.
      #
      # @return [String] detected separator, defaults to ','
      def detect_separator
        sample = content.lines.first(10).join
        CANDIDATE_SEPARATORS.find { |sep| headers_match_required?(sample, sep) } || ','
      end

      # Checks if a separator applied to the sample yields all required headers.
      #
      # @param sample [String] CSV sample
      # @param sep [String] candidate separator
      # @return [Boolean]
      def headers_match_required?(sample, sep)
        csv = CSV.parse(sample, headers: true, col_sep: sep)
        headers = normalized_headers(csv.headers)
        required_headers?(headers)
      rescue CSV::MalformedCSVError
        false
      end

      # Normalizes header names to symbols (downcased, stripped)
      #
      # @param headers [Array<String,Symbol>]
      # @return [Array<Symbol>]
      def normalized_headers(headers)
        Array(headers).map { |h| h.to_s.strip.downcase.to_sym }
      end

      # Checks if all required headers are present.
      #
      # @param headers [Array<Symbol>]
      # @return [Boolean]
      def required_headers?(headers)
        (REQUIRED_HEADERS - headers).empty?
      end

      # Raises an error if any required header is missing.
      #
      # @param headers [Array<String,Symbol>]
      # @raise [MissingHeadersError]
      def assert_required_headers!(headers)
        normalized = normalized_headers(headers)
        missing = REQUIRED_HEADERS - normalized
        raise MissingHeadersError, missing if missing.any?
      end
    end
  end
end
