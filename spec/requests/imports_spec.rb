# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Imports' do
  let(:merchant) { create(:merchant, slug: 'test-merchant') }
  let(:valid_csv_path)   { Rails.root.join('spec/fixtures/files/valid_affiliates.csv') }
  let(:invalid_csv_path) { Rails.root.join('spec/fixtures/files/invalid_affiliates.csv') }

  before { merchant }

  describe 'GET /' do
    it 'returns http success' do
      get '/'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /imports' do
    context 'with HTML requests' do
      context 'with a valid file' do
        it 'creates affiliates' do
          expect do
            post imports_path, params: { file: fixture_file_upload(valid_csv_path, 'text/csv') }
          end.to change(Affiliate, :count).by(2)
        end

        it 'redirects to root path' do
          post imports_path, params: { file: fixture_file_upload(valid_csv_path, 'text/csv') }
          expect(response).to redirect_to(root_path)
        end

        it 'sets a flash notice' do
          post imports_path, params: { file: fixture_file_upload(valid_csv_path, 'text/csv') }
          follow_redirect!
          expect(flash[:notice]).to match(/Import completed:/)
        end

        it 'creates affiliates with correct emails' do
          post imports_path, params: { file: fixture_file_upload(valid_csv_path, 'text/csv') }
          expect(Affiliate.pluck(:email)).to include('john@example.com', 'jane@foo.com')
        end
      end

      context 'without a file' do
        it 'does not create affiliates' do
          expect do
            post imports_path
          end.not_to change(Affiliate, :count)
        end

        it 'redirects to root path' do
          post imports_path
          expect(response).to redirect_to(root_path)
        end

        it 'sets a flash alert' do
          post imports_path
          follow_redirect!
          expect(flash[:alert]).to eq('No file uploaded')
        end
      end
    end

    context 'with JSON requests' do
      context 'with a valid file' do
        before do
          post imports_path,
            params: { file: fixture_file_upload(valid_csv_path, 'text/csv') },
            headers: { 'ACCEPT' => 'application/json' }
        end

        let(:json) { response.parsed_body }

        it 'returns JSON success' do
          expect(response).to have_http_status(:ok)
        end

        it 'includes status in JSON' do
          expect(json['status']).to eq('ok')
        end

        it 'includes created count in JSON' do
          expect(json['created']).to be >= 1
        end

        it 'creates affiliates with correct emails' do
          expect(Affiliate.pluck(:email)).to include('john@example.com', 'jane@foo.com')
        end
      end
    end
  end
end
