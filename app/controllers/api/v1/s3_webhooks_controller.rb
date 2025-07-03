# frozen_string_literal: true

module Api
  module V1
    # Handles incoming Amazon SNS webhook events related to S3 uploads.
    # Accepts and processes both SubscriptionConfirmation and Notification messages.
    class S3WebhooksController < ApplicationController
      # Skips CSRF verification as this endpoint is meant for external SNS callbacks.
      skip_before_action :verify_authenticity_token

      # Handles incoming POST requests from Amazon SNS.
      #
      # @return [void]
      def create
        case event_payload['Type']
        when 'SubscriptionConfirmation'
          Net::HTTP.get_response(URI.parse(event_payload['SubscribeURL']))
          head :ok
        when 'Notification'
          Affiliates::ProcessCsvImportJob.perform_async(event_payload['Message'])
          head :ok
        else
          head :bad_request
        end
      rescue StandardError => error
        Rails.logger.error(message: 'S3 webhook error', error: error.message)
        head :internal_server_error
      end

      private

      # Parses and memoizes the JSON payload from the raw POST body.
      #
      # @return [Hash] the parsed event payload
      def event_payload
        @event_payload ||= JSON.parse(request.raw_post)
      end
    end
  end
end
