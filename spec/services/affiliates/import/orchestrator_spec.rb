# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Affiliates::Import::Orchestrator do
  subject(:result) { described_class.new(file, audit).call }

  let(:merchant) { create(:merchant, slug: 'test-merchant') }

  let(:audit) {create(:import_audit)}

  let(:file) do
    Tempfile.create(['affiliates', '.csv']).tap do |f|
      f.write(csv_content)
      f.rewind
    end
  end

  after do
    file.close unless file.closed?
    file.unlink if file.respond_to?(:unlink)
  end

  around do |example|
    Sidekiq::Testing.inline! { example.run }
  end

  describe '#call' do
    context 'with a valid CSV file' do
      let(:csv_content) do
        merchant
        <<~CSV
          merchant_slug,first_name,last_name,email,website_url,commissions_total
          test-merchant,John,Doe,john@example.com,www.example.com,123.45
          test-merchant,Jane,Smith,jane@foo.com,,789.12
        CSV
      end

      it 'creates two affiliates' do
        expect { result }.to change(Affiliate, :count).by(2)
        expect(Affiliate.pluck(:email)).to include('john@example.com', 'jane@foo.com')
      end
    end

    context 'with a CSV using BOM and tab separator' do
      let(:csv_content) do
        merchant
        "\uFEFFmerchant_slug\tfirst_name\tlast_name\temail\twebsite_url\tcommissions_total\n" \
          "test-merchant\tYuri\tNagata\tyuri@ex.com\thttps://yuri.com\t987,65\n"
      end

      it 'imports affiliates with European decimal format' do
        expect { result }.to change(Affiliate, :count).by(1)
        expect(Affiliate.last.commissions_total).to eq(987.65)
      end
    end

    context 'with missing merchant in a row' do
      let(:csv_content) do
        merchant
        <<~CSV
          merchant_slug,first_name,last_name,email
          test-merchant,Tom,Foolery,tom@foo.com
          missing-merchant,Fake,Person,fake@foo.com
        CSV
      end

      it 'creates only the valid affiliate' do
        expect { result }.to change(Affiliate, :count).by(1)
        expect(Affiliate.last.email).to eq('tom@foo.com')
      end
    end

    context 'with duplicate emails for same merchant' do
      let(:csv_content) do
        merchant
        <<~CSV
          merchant_slug,first_name,last_name,email
          test-merchant,Bob,Builder,bob@foo.com
          test-merchant,Bob,Builder,bob@foo.com
        CSV
      end

      it 'creates one affiliate and skips the duplicate' do
        expect { result }.to change(Affiliate, :count).by(1)
        expect(Affiliate.first.email).to eq('bob@foo.com')
      end
    end

    context 'with extra columns and trailing blank rows' do
      let(:csv_content) do
        merchant
        <<~CSV
          merchant_slug,first_name,last_name,email,website_url,commissions_total,extra_col
          test-merchant,Anna,Smith,anna@foo.com,,0,EXTRA

        CSV
      end

      it 'ignores extra columns and creates affiliate' do
        expect { result }.to change(Affiliate, :count).by(1)
        expect(Affiliate.last.email).to eq('anna@foo.com')
      end
    end

    context 'with a CSV having only headers' do
      let(:csv_content) do
        merchant
        "merchant_slug,first_name,last_name,email,website_url,commissions_total\n"
      end

      it 'does not create any affiliates' do
        expect { result }.not_to change(Affiliate, :count)
      end
    end

    context 'with empty file' do
      let(:csv_content) { '' }

      it 'does not create any affiliates' do
        expect { result }.not_to change(Affiliate, :count)
      end
    end

    context 'with malformed CSV' do
      let(:csv_content) do
        merchant
        "merchant_slug,first_name,last_name,email\n\"a,b,c"
      end

      it 'does not create any affiliates' do
        expect { result }.not_to change(Affiliate, :count)
      end
    end

    context 'with crazy delimiters and mixed whitespace' do
      let(:csv_content) do
        merchant
        "merchant_slug ; first_name ; last_name ; email ; website_url ; commissions_total\n" \
          "test-merchant ;  Ann ;  O'Malley ; ann@weird.com ; ann.com ; 10,05\n"
      end

      it 'creates affiliate with proper formatting' do
        expect { result }.to change(Affiliate, :count).by(1)
        expect(Affiliate.last.email).to eq('ann@weird.com')
        expect(Affiliate.last.commissions_total).to eq(10.05)
      end
    end
  end
end
