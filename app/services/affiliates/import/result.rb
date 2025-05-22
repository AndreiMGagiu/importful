# frozen_string_literal: true

module Affiliates
  module Import
    # Simple value object for capturing import errors and the line number (if provided)
    ImportError = Struct.new(:message, :line)

    # Tracks statistics and errors for a single import operation.
    class Result
      attr_reader :total, :created, :updated, :errors

      def initialize
        @total   = 0
        @created = 0
        @updated = 0
        @errors  = []
      end

      # Increments counters as rows are processed
      def increment_total   = @total += 1
      def increment_created = @created += 1
      def increment_updated = @updated += 1

      # Records an error for the import result.
      # @param message [String] error message
      # @param line [Integer, nil] CSV line number (optional)
      def add_error(message, line: nil)
        @errors << ImportError.new(message, line)
      end

      def success?
        errors.empty?
      end
    end
  end
end
