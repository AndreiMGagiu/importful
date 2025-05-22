# frozen_string_literal: true

module Affiliates
  module Import
    # RowProcessor sanitizes and normalizes affiliate data from a CSV row,
    # ensuring all fields are formatted consistently for import.
    class RowProcessor
      REQUIRED_FIELDS = %i[merchant_slug first_name last_name email].freeze
      OPTIONAL_FIELDS = %i[website_url commissions_total].freeze
      ALL_FIELDS = (REQUIRED_FIELDS + OPTIONAL_FIELDS).freeze

      # @param row [Hash] a single CSV row (string or symbol keys)
      def initialize(row)
        @row = row.respond_to?(:symbolize_keys) ? row.symbolize_keys : row
      end

      # Returns a sanitized hash of affiliate data for import.
      #
      # @return [Hash] sanitized and normalized fields, suitable for Affiliate creation/updating
      def call
        ALL_FIELDS.index_with do |field|
          process_field(field)
        end
      end

      private

      attr_reader :row

      # Cleans and normalizes a specific field
      def process_field(field)
        case field
        when :email
          normalize_email(row[field])
        when :website_url
          normalize_url(row[field])
        when :commissions_total
          parse_commission(row[field])
        else
          clean_string(row[field])
        end
      end

      # Removes leading/trailing whitespace and returns nil if blank
      def clean_string(value)
        value.to_s.strip.presence
      end

      # Lowercases and strips whitespace from emails
      def normalize_email(email)
        clean_string(email)&.downcase
      end

      # Ensures URLs have a protocol, or returns nil if blank
      def normalize_url(url)
        clean_url = clean_string(url)
        return nil if clean_url.blank?

        protocol?(clean_url) ? clean_url : "http://#{clean_url}"
      end

      # Checks if the string starts with http:// or https://
      def protocol?(url)
        %r{\Ahttps?://}i.match?(url)
      end

      # Parses a commissions value, supporting both European and US number formats
      # Examples:
      #   "1.234,56" => 1234.56
      #   "1,234.56" => 1234.56
      #   "1234.56"  => 1234.56
      #   "1234,56"  => 1234.56
      #   "$1,234.56" => 1234.56
      def parse_commission(value)
        clean_value = clean_string(value)
        return 0.0 if clean_value.blank?

        if clean_value.match?(/\A-?\d{1,3}(\.\d{3})*,\d+\z/)
          clean_value = clean_value.gsub('.', '').gsub(',', '.')
        elsif clean_value.match?(/\A-?\d{1,3}(,\d{3})*\.\d+\z/)
          clean_value = clean_value.gsub(',', '')
        end

        clean_value.gsub(/[^\d.\-]/, '').to_f
      end


      # Normalizes a single comma to a dot, for European-style decimals
      def normalize_decimal_separator(value)
        if value.count(',') == 1 && value.count('.').zero?
          value.tr(',', '.')
        else
          value
        end
      end
    end
  end
end
