# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliates::GeneratePresignedUrl, type: :service do
  subject(:service) do
    with_aws_env do
      described_class.new(filename: filename, content_type: content_type).call
    end
  end

  let(:filename) { 'test.csv' }
  let(:content_type) { 'text/csv' }

  describe '#call' do
    context 'with valid parameters' do
      it 'creates an ImportAudit record' do
        expect { service }.to change(ImportAudit, :count).by(1)
      end

      it 'returns a hash with :direct_upload and :key' do
        expect(service).to include(:direct_upload, :key)
      end

      it 'returns a direct_upload hash with :url and :headers' do
        expect(service[:direct_upload]).to include(:url, :headers)
      end

      it 'sets the correct content type in headers' do
        expect(service[:direct_upload][:headers]['Content-Type']).to eq('text/csv')
      end

      it 'generates an S3 key including the filename' do
        expect(service[:key]).to include(filename)
      end
    end

    context 'when content_type is nil' do
      let(:content_type) { nil }

      it 'defaults content_type to application/octet-stream' do
        expect(service[:direct_upload][:headers]['Content-Type']).to eq('application/octet-stream')
      end
    end

    context 'when AWS credentials are invalid' do
      before do
        allow(Aws::S3::Resource).to receive(:new).and_raise(Aws::Errors::ServiceError.new(nil, 'AWS error'))
      end

      it 'raises an AWS ServiceError' do
        expect do
          with_aws_env do
            described_class.new(filename: filename, content_type: content_type).call
          end
        end.to raise_error(Aws::Errors::ServiceError)
      end
    end

    context 'when ImportAudit creation fails' do
      before do
        allow(ImportAudit).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(ImportAudit.new))
      end

      it 'raises a RecordInvalid error' do
        expect do
          with_aws_env do
            described_class.new(filename: filename, content_type: content_type).call
          end
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
