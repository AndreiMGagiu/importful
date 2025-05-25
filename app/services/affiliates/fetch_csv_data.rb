# frozen_string_literal: true

module Affiliates
  # Handles processing of CSV data from an AWS S3 event notification,
  # looks up the corresponding ImportAudit by S3 key, runs the import
  # orchestrator, updates the audit record, and returns the import result.
  class FetchCsvData
    # @param data [String] Raw JSON string from S3 event
    def initialize(data)
      @data = data
    end

    # Executes the CSV fetch and import process.
    #
    # @return [Affiliates::Import::Result]
    def call
      return failure('Invalid S3 event data') unless valid_event_data?
      return failure('Audit record not found') unless audit

      update_import_audit(process_csv_data)
    rescue Aws::S3::Errors::ServiceError => error
      handle_error("S3 error: #{error.message}", key: key, bucket: bucket)
    rescue StandardError => error
      handle_error(
        "Unexpected error: #{error.message}",
        error: error.class.name,
        backtrace: error.backtrace.first(5)
      )
    end

    private

    # @return [String] Raw JSON data from the event
    attr_reader :data

    # Validates the presence of required fields in the event data.
    #
    # @return [Boolean]
    def valid_event_data?
      event_data.present? && key.present?
    end

    # Retrieves the corresponding ImportAudit by path.
    #
    # @return [ImportAudit, nil]
    def audit
      @audit ||= ImportAudit.find_by(path: key)
    end

    # Parses and processes the CSV using the import orchestrator.
    #
    # @return [Affiliates::Import::Result]
    def process_csv_data
      Affiliates::Import::Orchestrator.new(fetch_csv_from_s3, audit).call
    end

    # Updates the ImportAudit record based on the result of the import.
    #
    # @param result [Affiliates::Import::Result]
    # @return [void]
    def update_import_audit(result)
      return unless audit

      audit.update!(
        status: result.errors.any? ? 'failed' : 'processed',
        error_details: result.errors.map(&:message),
        processed_at: Time.current
      )
    end

    # Fetches the CSV content from S3 and wraps it in a StringIO.
    #
    # @return [StringIO]
    def fetch_csv_from_s3
      response = storage_client.get_object(bucket: bucket, key: key)
      StringIO.new(response.body.read)
    end

    # Extracts the S3 object key from the event record.
    #
    # @return [String, nil]
    def key
      @key ||= record&.dig('s3', 'object', 'key')
    end

    # Extracts the first record from the event data.
    #
    # @return [Hash, nil]
    def record
      @record ||= event_data['Records']&.first
    end

    # Parses the raw JSON event payload.
    #
    # @return [Hash]
    def event_data
      @event_data ||= parse_json_data
    end

    # Safely parses JSON and logs if invalid.
    #
    # @return [Hash]
    def parse_json_data
      JSON.parse(data)
    rescue JSON::ParserError => error
      Rails.logger.error(
        message: 'Failed to parse S3 event data',
        error: error.message,
        data: data&.truncate(500)
      )
      {}
    end

    # Builds an S3 client.
    #
    # @return [Aws::S3::Client]
    def storage_client
      @storage_client ||= Aws::S3::Client.new(region: region)
    end

    # Returns the AWS region from ENV.
    #
    # @return [String]
    def region
      @region ||= ENV.fetch('AWS_REGION')
    end

    # Returns the AWS bucket from ENV.
    #
    # @return [String]
    def bucket
      @bucket ||= ENV.fetch('AWS_BUCKET')
    end

    # Logs the error, updates the audit, and returns a failed result.
    #
    # @param message [String]
    # @param context [Hash]
    # @return [Affiliates::Import::Result]
    def handle_error(message, context = {})
      Rails.logger.error({ message: message }.merge(context))
      update_audit_with_error(message)
      failure(message)
    end

    # Updates audit record with a failure and error message.
    #
    # @param error_message [String]
    # @return [void]
    def update_audit_with_error(error_message)
      audit&.update!(
        status: 'failed',
        error_details: [error_message],
        processed_at: Time.current
      )
    end

    # Builds a failure result with a single error.
    #
    # @param message [String]
    # @return [Affiliates::Import::Result]
    def failure(message)
      result = Affiliates::Import::Result.new
      result.add_error(message)
      result
    end
  end
end
