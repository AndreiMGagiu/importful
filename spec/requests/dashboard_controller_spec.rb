# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DashboardController' do
  describe 'GET /dashboard' do
    before { get dashboard_path }

    it 'returns a successful response' do
      expect(response).to have_http_status(:ok)
    end

    it 'renders the dashboard title' do
      expect(response.body).to include('Dashboard')
    end
  end

  describe 'GET /dashboard/stats' do
    before do
      create_list(:affiliate, 2, commissions_total: 100.0)
      create_list(:merchant, 3)
      get dashboard_stats_path, as: :json
    end

    let(:json) { response.parsed_body }

    it 'returns the total number of affiliates' do
      expect(json['total_affiliates']).to eq(2)
    end

    it 'returns the total number of merchants' do
      expect(json['total_merchants']).to eq(5)
    end

    it 'returns the total commissions' do
      expect(json['total_commissions']).to eq('200.0')
    end

    it 'returns the average commission' do
      expect(json['avg_commission']).to eq('100.0')
    end

    it 'returns affiliates created this month' do
      expect(json['affiliates_this_month']).to eq(2)
    end
  end

  describe 'GET /dashboard/affiliates' do
    before do
      Affiliate.delete_all
      create(:affiliate, first_name: 'John', last_name: 'Doe', email: 'john@example.com')
    end

    context 'with HTML' do
      before { get dashboard_affiliates_path }

      it 'returns a successful response' do
        expect(response).to have_http_status(:ok)
      end

      it 'renders the affiliates page title' do
        expect(response.body).to include('Affiliates')
      end
    end

    context 'with filters' do
      before { get dashboard_affiliates_path(search: 'john', page: 1, per_page: 12), as: :json }

      let(:json) { response.parsed_body }

      it 'returns one filtered result' do
        expect(json['affiliates'].length).to eq(1)
      end

      it 'returns the expected email' do
        expect(json['affiliates'].first['email']).to eq('john@example.com')
      end

      it 'returns the correct total count' do
        expect(json['total_count']).to eq(1)
      end

      it 'returns the correct page number' do
        expect(json['page']).to eq(1)
      end

      it 'returns the correct per_page value' do
        expect(json['per_page']).to eq(12)
      end
    end
  end
end
