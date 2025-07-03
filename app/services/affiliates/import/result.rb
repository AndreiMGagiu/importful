# frozen_string_literal: true

module Affiliates
  module Import
    ImportError = Struct.new(:message, :line)

    class Result
      attr_reader :total, :created, :updated, :skipped, :errors

      def initialize
        @total   = 0
        @created = 0
        @updated = 0
        @skipped = 0
        @errors  = []
      end

      def increment_total   = @total += 1
      def increment_created = @created += 1
      def increment_updated = @updated += 1
      def increment_skipped = @skipped += 1

      def add_error(message, line: nil)
        @errors << ImportError.new(message, line)
      end

      def success?
        created.positive? || updated.positive? || skipped.positive?
      end
    end
  end
end
