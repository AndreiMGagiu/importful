# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Imports' do
  describe 'POST /imports' do
    let(:params) do
      {
        filename: 'test.csv',
        content_type: 'text/csv'
      }
    end

    let(:expected_keys) { %w[direct_upload key] }

    let(:s3_object) do
      instance_double(Aws::S3::Object, presigned_url: 'https://s3.amazonaws.com/fake-url')
    end

    before do
      allow(Aws::S3::Resource).to receive(:new).and_return(
        instance_double(Aws::S3::Resource,
          bucket: instance_double(Aws::S3::Bucket,
            object: s3_object))
      )
    end

    context 'when request is valid' do
      it 'creates an ImportAudit record' do
        expect do
          post '/imports', params: params
        end.to change(ImportAudit, :count).by(1)
      end

      it 'returns a 200 OK status' do
        post '/imports', params: params
        expect(response).to have_http_status(:ok)
      end

      it 'returns expected JSON keys' do
        post '/imports', params: params
        json = response.parsed_body
        expect(json.keys).to match_array(expected_keys)
      end

      it 'includes URL in response' do
        post '/imports', params: params
        json = response.parsed_body
        expect(json['direct_upload']['url']).to include('https://s3.amazonaws.com/fake-url')
      end

      it 'includes headers in response' do
        post '/imports', params: params
        json = response.parsed_body
        expect(json['direct_upload']).to include('headers')
      end
    end

    context 'when AWS service fails' do
      before do
        allow(s3_object).to receive(:presigned_url).and_raise(Aws::Errors::ServiceError.new(nil, 'AWS error'))
      end

      it 'returns a 500 Internal Server Error' do
        post '/imports', params: params
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'returns error message in JSON' do
        post '/imports', params: params
        json = response.parsed_body
        expect(json['error']).to eq('Failed to generate signed URL')
      end
    end

    context 'when ImportAudit validation fails' do
      before do
        allow(ImportAudit).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(ImportAudit.new))
      end

      it 'returns a 500 Internal Server Error' do
        post '/imports', params: params
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'returns error message in JSON' do
        post '/imports', params: params
        json = response.parsed_body
        expect(json['error']).to eq('Failed to generate signed URL')
      end
    end
  end
end
