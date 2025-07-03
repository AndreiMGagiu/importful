# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliates::Import::RowImport, type: :service do
  let(:merchant) { create(:merchant) }
  let(:line) { 2 }
  let(:raw_row) do
    {
      'merchant_slug' => merchant.slug,
      'first_name' => 'John',
      'last_name' => 'Doe',
      'email' => 'john@example.com',
      'website_url' => 'http://example.com',
      'commissions_total' => '1,234.56'
    }
  end

  describe '#call' do
    context 'when the audit exists' do
      subject(:service) { described_class.new(raw_row, line, audit.id) }

      let!(:audit) do
        create(:import_audit, status: 'pending', total_successful_rows: 0, total_failed_rows: 0)
      end

      context 'with a valid row' do
        before { service.call }

        it 'creates an affiliate' do
          expect(Affiliate.count).to eq(1)
        end

        it 'increments total_successful_rows' do
          expect(audit.reload.total_successful_rows).to eq(1)
        end

        it 'does not increment total_failed_rows' do
          expect(audit.reload.total_failed_rows).to eq(0)
        end

        it 'marks audit as processed' do
          expect(audit.reload.status).to eq('processed')
        end
      end

      context 'with an invalid merchant slug' do
        let(:raw_row) { super().merge('merchant_slug' => 'nonexistent') }

        before { service.call }

        it 'does not create affiliate' do
          expect(Affiliate.count).to eq(0)
        end

        it 'increments total_failed_rows' do
          expect(audit.reload.total_failed_rows).to eq(1)
        end

        it 'does not increment total_successful_rows' do
          expect(audit.reload.total_successful_rows).to eq(0)
        end

        it 'marks audit as processed_with_errors' do
          expect(audit.reload.status).to eq('processed_with_errors')
        end

        it 'logs validation error to audit details' do
          expect(audit.reload.error_details.first).to include('Unknown merchant slug')
        end
      end

      context 'when Processor raises an unexpected error' do
        before do
          allow(Affiliates::Import::Processor).to receive(:new).and_raise('boom')
          service.call
        end

        it 'does not raise an exception' do
          expect { service.call }.not_to raise_error
        end

        it 'increments total_failed_rows' do
          expect(audit.reload.total_failed_rows).to eq(1)
        end

        it 'does not increment total_successful_rows' do
          expect(audit.reload.total_successful_rows).to eq(0)
        end

        it 'marks audit as processed_with_errors' do
          expect(audit.reload.status).to eq('processed_with_errors')
        end

        it 'logs unexpected error to audit details' do
          expect(audit.reload.error_details.first).to include('Unexpected error')
        end
      end
    end

    context 'when audit does not exist' do
      subject(:service) { described_class.new(raw_row, line, -999) }

      it 'does nothing and raises no error' do
        expect { service.call }.not_to raise_error
      end
    end
  end
end
