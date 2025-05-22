# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliates::Import::Parser do
  describe '#call' do
    context 'with valid CSV string' do
      subject(:csv) { described_class.new(csv_content).call }

      let(:csv_content) do
        <<~CSV
          merchant_slug,first_name,last_name,email,website_url,commissions_total
          some-merchant,John,Doe,john@example.com,www.example.com,123.45
        CSV
      end

      it { is_expected.to be_a(CSV::Table) }
      it { expect(csv.size).to eq(1) }
      it { expect(csv.headers).to include(:merchant_slug, :first_name, :last_name, :email) }
    end

    context 'with valid IO file' do
      subject(:csv) { described_class.new(io_file).call }

      let(:csv_content) do
        <<~CSV
          merchant_slug,first_name,last_name,email,website_url,commissions_total
          some-merchant,John,Doe,john@example.com,www.example.com,123.45
        CSV
      end
      let(:io_file) do
        file = Tempfile.new('affiliates.csv')
        file.write(csv_content)
        file.rewind
        file
      end

      after { io_file.close! }

      it { expect(csv.size).to eq(1) }
      it { expect(csv.first[:merchant_slug]).to eq('some-merchant') }
    end

    context 'with semicolon separator' do
      subject(:csv) { described_class.new(csv_content).call }

      let(:csv_content) do
        <<~CSV
          merchant_slug;first_name;last_name;email
          some-merchant;Jane;Smith;jane@ex.com
        CSV
      end

      it { expect(csv.size).to eq(1) }
      it { expect(csv.first[:email]).to eq('jane@ex.com') }
    end

    context 'with BOM present' do
      subject(:csv) { described_class.new(csv_content).call }

      let(:csv_content) { "\uFEFFmerchant_slug,first_name,last_name,email\nacme,Al,Bundy,al@acme.com\n" }

      it { expect(csv.size).to eq(1) }
      it { expect(csv.first[:merchant_slug]).to eq('acme') }
    end

    context 'when required headers are missing' do
      subject(:parser) { described_class.new(csv_content) }

      let(:csv_content) do
        <<~CSV
          merchant_slug,first_name,last_name
          some-merchant,John,Doe
        CSV
      end

      it 'raises MissingHeadersError' do
        expect { parser.call }.to raise_error(described_class::MissingHeadersError)
      end

      it 'indicates which headers are missing' do
        parser.call
      rescue described_class::MissingHeadersError => error
        expect(error.missing).to match_array(%i[email])
      end
    end

    context 'with malformed CSV' do
      subject(:parser) { described_class.new(malformed_csv) }

      let(:malformed_csv) { "merchant_slug,first_name,last_name,email\nnot,properly,\"unclosed" }

      it 'raises an error' do
        expect { parser.call }.to raise_error(CSV::MalformedCSVError)
      end
    end

    context 'with custom input type (StringIO)' do
      subject(:csv) { described_class.new(StringIO.new(csv_content)).call }

      let(:csv_content) do
        <<~CSV
          merchant_slug,first_name,last_name,email,website_url,commissions_total
          some-merchant,John,Doe,john@example.com,www.example.com,123.45
        CSV
      end

      it { expect(csv.size).to eq(1) }
      it { expect(csv.first[:first_name]).to eq('John') }
    end

    context 'with extra whitespace and mixed-case headers' do
      subject(:csv) { described_class.new(csv_content).call }

      let(:csv_content) do
        <<~CSV
          MERCHANT_SLUG , First_Name , Last_Name , Email
          weird-merchant , Foo , Bar , foo@bar.com
        CSV
      end

      it 'parses and normalizes headers (trailing space is preserved by CSV)' do
        expect(csv.first[:merchant_slug].strip).to eq('weird-merchant')
      end

      it 'parses first_name with whitespace' do
        expect(csv.first[:first_name].strip).to eq('Foo')
      end
    end

    context 'when file is empty' do
      subject(:parser) { described_class.new('') }

      it 'raises an error' do
        expect { parser.call }.to raise_error(described_class::MissingHeadersError)
      end
    end
  end
end
