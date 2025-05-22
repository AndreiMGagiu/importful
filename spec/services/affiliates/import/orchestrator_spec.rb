# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliates::Import::Orchestrator do
  subject(:result) { described_class.new(file).call }

  let(:merchant) { Merchant.create!(slug: 'test-merchant') }

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

      it 'is successful' do
        expect(result).to be_success
      end

      it 'imports two rows' do
        expect(result.total).to eq(2)
      end

      it 'creates two affiliates' do
        expect(result.created).to eq(2)
      end

      it 'has zero updated affiliates' do
        expect(result.updated).to eq(0)
      end

      it 'has no errors' do
        expect(result.errors).to be_empty
      end
    end

    context 'with a CSV using BOM and tab separator' do
      let(:csv_content) do
        merchant
        "\uFEFFmerchant_slug\tfirst_name\tlast_name\temail\twebsite_url\tcommissions_total\n" \
          "test-merchant\tYuri\tNagata\tyuri@ex.com\thttps://yuri.com\t987,65\n"
      end

      it 'parses and imports affiliates with European decimal' do
        expect(result).to be_success
        expect(result.created).to eq(1)
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

      it 'imports valid row, errors for missing merchant' do
        expect(result.total).to eq(2)
        expect(result.created).to eq(1)
        expect(result.errors.first.message).to match(/Unknown merchant slug/i)
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

      it 'creates the first, fails the second' do
        expect(result.total).to eq(2)
        expect(result.created).to eq(1)
        expect(result.updated).to eq(0)
      end
    end

    context 'with extra columns and trailing blank rows' do
      let(:csv_content) do
        merchant
        <<~CSV
          merchant_slug,first_name,last_name,email,website_url,commissions_total,extra_col
          test-merchant,Anna,Smith,anna@foo.com,,0,SHOULD_BE_IGNORED

        CSV
      end

      it 'ignores extra columns and blank lines' do
        expect(result).to be_success
        expect(result.created).to eq(1)
      end
    end

    context 'when CSV is missing a required header' do
      let(:csv_content) do
        merchant
        <<~CSV
          merchant_slug,first_name,last_name
          test-merchant,Jim,Beam
        CSV
      end

      it 'adds a missing headers error to result' do
        expect(result).not_to be_success
        expect(result.errors.first.message).to match(/Missing required headers/i)
        expect(result.total).to eq(0)
      end
    end

    context 'when CSV is malformed' do
      let(:csv_content) do
        merchant
        "merchant_slug,first_name,last_name,email\n\"a,b,c"
      end

      it 'adds a CSV format error to result' do
        expect(result).not_to be_success
        expect(result.errors.first.message).to match(/Invalid CSV format/)
      end
    end

    context 'with empty file' do
      let(:csv_content) do
        merchant
        ''
      end

      it 'adds an error for invalid CSV or missing headers' do
        expect(result.errors.first.message).to match(/Invalid CSV format|Missing required headers/i)
        expect(result.total).to eq(0)
      end
    end

    context 'with a CSV having only headers' do
      let(:csv_content) do
        merchant
        "merchant_slug,first_name,last_name,email,website_url,commissions_total\n"
      end

      it 'is successful' do
        expect(result).to be_success
      end

      it 'has zero total rows' do
        expect(result.total).to eq(0)
      end

      it 'creates zero affiliates' do
        expect(result.created).to eq(0)
      end

      it 'has no errors' do
        expect(result.errors).to be_empty
      end
    end

    context 'with crazy delimiters and mixed whitespace' do
      let(:csv_content) do
        merchant
        "merchant_slug ; first_name ; last_name ; email ; website_url ; commissions_total\n" \
          "test-merchant ;  Ann ;  O'Malley ; ann@weird.com ; ann.com ; 10,05\n"
      end

      it 'handles weird delimiters and whitespace' do
        expect(result).to be_success
        expect(Affiliate.last.email).to eq('ann@weird.com')
        expect(Affiliate.last.commissions_total).to eq(10.05)
      end
    end
  end
end
