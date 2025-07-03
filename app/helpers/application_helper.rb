# frozen_string_literal: true

# Helper methods for formatting currency values in views.
module ApplicationHelper
  # Scale definitions for formatting large currency numbers.
  #
  # @return [Array<Hash>] thresholds, suffixes, and divisors for currency scaling
  CURRENCY_SCALES = [
    { threshold: 1_000_000_000_000, suffix: 'T', divisor: 1_000_000_000_000.0 },
    { threshold: 1_000_000_000, suffix: 'B', divisor: 1_000_000_000.0 },
    { threshold: 1_000_000, suffix: 'M', divisor: 1_000_000.0 },
    { threshold: 1_000, suffix: 'K', divisor: 1_000.0 }
  ].freeze

  # Formats a number into a shortened currency format with a suffix.
  #
  # Examples:
  #   format_currency_short(123456) => "$123.5K"
  #   format_currency_short(0) => "$0"
  #
  # @param amount [Numeric, String, nil] the amount to format
  # @return [String] formatted currency with suffix
  def format_currency_short(amount)
    return '$0' if amount.blank? || amount.to_f.zero?

    amount = amount.to_f.abs
    scale = CURRENCY_SCALES.find { |s| amount >= s[:threshold] }

    if scale
      scaled_amount = amount / scale[:divisor]
      "$#{number_with_precision(scaled_amount, precision: 1)}#{scale[:suffix]}"
    else
      "$#{number_with_precision(amount, precision: 0)}"
    end
  end

  # Formats a number into a full currency string with two decimal places.
  #
  # Examples:
  #   format_currency_detailed(1234.5) => "$1,234.50"
  #   format_currency_detailed(nil) => "$0.00"
  #
  # @param amount [Numeric, String, nil] the amount to format
  # @return [String] formatted currency with two decimals
  def format_currency_detailed(amount)
    return '$0.00' if amount.blank? || amount.to_f.zero?

    number_to_currency(amount, precision: 2)
  end
end
