# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::S3WebhooksController do
  describe 'POST /api/v1/s3_webhooks' do
    let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }

    context 'when the message is a SubscriptionConfirmation' do
      let(:subscribe_url) { 'https://sns.example.com/confirm' }
      let(:payload) do
        {
          'Type' => 'SubscriptionConfirmation',
          'SubscribeURL' => subscribe_url
        }.to_json
      end

      before do
        stub_request(:get, subscribe_url).to_return(status: 200)
        post '/api/v1/s3_webhooks', params: payload, headers: headers
      end

      it 'confirms the subscription' do
        expect(a_request(:get, subscribe_url)).to have_been_made
      end

      it 'returns HTTP 200' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the message is a Notification' do
      let(:message_body) { { 'Records' => [{ 's3' => { 'object' => { 'key' => 'some/path.csv' } } }] }.to_json }

      let(:payload) do
        {
          'Type' => 'Notification',
          'Message' => message_body
        }.to_json
      end

      before do
        allow(Affiliates::ProcessCsvImportJob).to receive(:perform_async)
        post '/api/v1/s3_webhooks', params: payload, headers: headers
      end

      it 'enqueues the ProcessCsvImportJob' do
        expect(Affiliates::ProcessCsvImportJob).to have_received(:perform_async).with(message_body)
      end

      it 'returns HTTP 200' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the message type is unsupported' do
      let(:payload) do
        {
          'Type' => 'UnknownType'
        }.to_json
      end

      it 'returns 400 Bad Request' do
        post '/api/v1/s3_webhooks', params: payload, headers: headers
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when an exception is raised during processing' do
      let(:payload) { 'invalid-json' }

      before do
        allow(Rails.logger).to receive(:error)
        post '/api/v1/s3_webhooks', params: payload, headers: headers
      end

      it 'logs the error' do
        expect(Rails.logger).to have_received(:error).with(hash_including(message: 'S3 webhook error'))
      end

      it 'returns HTTP 500' do
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
