# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Imports' do
  include EnvHelper

  describe 'POST /imports' do
    let(:params) do
      {
        filename: 'test.csv',
        content_type: 'text/csv'
      }
    end

    let(:expected_keys) { %w[direct_upload key] }

    context 'when request is valid' do
      it 'creates an ImportAudit record' do
        with_aws_env do
          expect do
            post '/imports', params: params
          end.to change(ImportAudit, :count).by(1)
        end
      end

      it 'returns a 200 OK status' do
        with_aws_env do
          post '/imports', params: params
          expect(response).to have_http_status(:ok)
        end
      end

      it 'returns expected JSON keys' do
        with_aws_env do
          post '/imports', params: params
          json = response.parsed_body
          expect(json.keys).to match_array(expected_keys)
        end
      end

      it 'includes URL in response' do
        with_aws_env do
          post '/imports', params: params
          json = response.parsed_body
          expect(json['direct_upload']['url']).to include('.s3.amazonaws.com')
        end
      end

      it 'includes headers in response' do
        with_aws_env do
          post '/imports', params: params
          json = response.parsed_body
          expect(json['direct_upload']).to include('headers')
        end
      end
    end

    context 'when AWS service fails' do
      before do
        allow_any_instance_of(Aws::S3::Object).to receive(:presigned_url)
          .and_raise(Aws::Errors::ServiceError.new(nil, 'AWS error'))
      end

      it 'returns a 500 Internal Server Error' do
        with_aws_env do
          post '/imports', params: params
          expect(response).to have_http_status(:internal_server_error)
        end
      end

      it 'returns error message in JSON' do
        with_aws_env do
          post '/imports', params: params
          json = response.parsed_body
          expect(json['error']).to eq('Failed to generate signed URL')
        end
      end
    end

    context 'when ImportAudit validation fails' do
      before do
        allow(ImportAudit).to receive(:create!).and_raise(
          ActiveRecord::RecordInvalid.new(ImportAudit.new)
        )
      end

      it 'returns a 500 Internal Server Error' do
        with_aws_env do
          post '/imports', params: params
          expect(response).to have_http_status(:internal_server_error)
        end
      end

      it 'returns error message in JSON' do
        with_aws_env do
          post '/imports', params: params
          json = response.parsed_body
          expect(json['error']).to eq('Failed to generate signed URL')
        end
      end
    end
  end
end
