# frozen_string_literal: true

module Affiliates
  module Import
    # Processes a single sanitized affiliate row.
    # Finds or initializes an Affiliate record based on email and merchant slug,
    # applies changes, saves if needed, and records outcomes in the import result.
    class Processor
      # @param row [Hash] A sanitized affiliate row with symbol keys
      # @param result [Affiliates::Import::Result] A shared result object used to track import stats
      # @param line [Integer] Line number in the original CSV (used for error reporting)
      def initialize(row, result, line)
        @row = row
        @result = result
        @line = line
      end

      # Processes the affiliate row and updates the result accordingly.
      #
      # @return [Affiliates::Import::Result] the updated result object
      def call
        result.increment_total

        return log_merchant_error unless merchant

        process_affiliate
        result
      rescue StandardError => error
        result.add_error("Line #{line}: Unexpected error - #{error.message}", line: line)
        result
      end

      private

      attr_reader :row, :result, :line

      # Finds the merchant by slug.
      #
      # @return [Merchant, nil]
      def merchant
        @merchant ||= Merchant.find_by(slug: row[:merchant_slug])
      end

      # Saves the affiliate if needed and tracks the result.
      #
      # @return [void]
      def process_affiliate
        return result.increment_skipped unless affiliate.new_record? || affiliate.changed?

        if affiliate.save
          affiliate.previous_changes.key?('id') ? result.increment_created : result.increment_updated
        else
          result.add_error("Line #{line}: #{affiliate.errors.full_messages.join(', ')}", line: line)
        end
      end

      # Finds or initializes the affiliate and assigns attributes.
      #
      # @return [Affiliate]
      def affiliate
        @affiliate ||= merchant.affiliates.find_or_initialize_by(email: row[:email]).tap do |aff|
          aff.assign_attributes(affiliate_attributes)
        end
      end

      # Returns the attributes to assign to the affiliate.
      #
      # @return [Hash]
      def affiliate_attributes
        row.slice(:first_name, :last_name, :website_url, :commissions_total)
      end

      # Logs an error when the merchant is not found.
      #
      # @return [Affiliates::Import::Result]
      def log_merchant_error
        result.add_error("Line #{line}: Unknown merchant slug '#{row[:merchant_slug]}'", line: line)
        result
      end
    end
  end
end
