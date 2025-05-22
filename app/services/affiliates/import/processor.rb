# frozen_string_literal: true

module Affiliates
  module Import
    # Processes a single CSV row and updates import statistics.
    # Handles affiliate creation, update, or error logging.
    class Processor
      # @param row [Hash] The sanitized affiliate data for one row
      # @param result [Affiliates::Import::Result] The result stats and errors tracker
      # @param line [Integer] The CSV line number (for error reporting)
      def initialize(row, result, line)
        @row = row
        @result = result
        @line = line
      end

      # Main entrypoint for processing the row
      # Increments total, creates/updates affiliate or logs errors.
      def call
        result.increment_total

        return missing_merchant_error if merchant.blank?

        assign_affiliate_attributes

        return unless affiliate_changed?

        save_affiliate
      end

      private

      attr_reader :row, :result, :line

      # Finds merchant by slug, memoized for efficiency
      def merchant
        @merchant ||= Merchant.find_by(slug: row[:merchant_slug])
      end

      # Finds or builds affiliate for the merchant and email
      def affiliate
        @affiliate ||= find_or_build_affiliate
      end

      # Helper for affiliate lookup/initialization
      def find_or_build_affiliate
        merchant.affiliates.find_or_initialize_by(email: row[:email])
      end

      # Assigns incoming CSV attributes to affiliate
      def assign_affiliate_attributes
        affiliate.assign_attributes(affiliate_attributes)
      end

      # Attributes hash for mass-assignment
      def affiliate_attributes
        {
          first_name: row[:first_name],
          last_name: row[:last_name],
          website_url: row[:website_url],
          commissions_total: row[:commissions_total]
        }
      end

      # Determines if the affiliate needs to be saved (created or updated)
      def affiliate_changed?
        affiliate.new_record? || affiliate.changed?
      end

      # Attempts to save affiliate, tracks success or failure
      def save_affiliate
        affiliate.save ? record_success : record_failure
      end

      # Tracks if the record was created or updated
      def record_success
        if affiliate.previous_changes.key?('id')
          result.increment_created
        else
          result.increment_updated
        end
      end

      # Adds a formatted error to the result object
      def record_failure
        error_message = affiliate.errors.full_messages.join(', ')
        result.add_error("Line #{line}: #{error_message}", line: line)
      end

      # Logs merchant-missing error to result
      def missing_merchant_error
        result.add_error(
          "Line #{line}: Unknown merchant slug '#{row[:merchant_slug]}'",
          line: line
        )
      end
    end
  end
end
