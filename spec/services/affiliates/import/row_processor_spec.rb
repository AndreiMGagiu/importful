# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliates::Import::RowProcessor do
  subject(:processed) { described_class.new(row).call }

  let(:row) do
    {
      'merchant_slug' => ' my-merchant ',
      'first_name' => ' John ',
      'last_name' => ' Doe ',
      'email' => ' John.Doe@example.com ',
      'website_url' => 'johndoe.com',
      'commissions_total' => '1,234.56'
    }
  end

  describe '#call' do
    it 'returns a hash' do
      expect(processed).to be_a(Hash)
    end

    it 'includes all expected symbol keys' do
      expect(processed.keys).to match_array(
        %i[merchant_slug first_name last_name email website_url commissions_total]
      )
    end

    it 'sanitizes merchant_slug' do
      expect(processed[:merchant_slug]).to eq('my-merchant')
    end

    it 'sanitizes first_name' do
      expect(processed[:first_name]).to eq('John')
    end

    it 'sanitizes last_name' do
      expect(processed[:last_name]).to eq('Doe')
    end

    it 'normalizes and lowercases email' do
      expect(processed[:email]).to eq('john.doe@example.com')
    end

    it 'adds http:// if website_url is missing protocol' do
      expect(processed[:website_url]).to eq('http://johndoe.com')
    end

    it 'parses commissions_total as a float and handles comma as decimal' do
      expect(processed[:commissions_total]).to eq(1234.56)
    end
  end

  context 'when commissions_total uses both dot and comma (European thousands and decimals)' do
    let(:row) { super().merge('commissions_total' => '1.234,56') }

    it 'parses only digits and final decimal, treating dot as thousands and comma as decimal' do
      expect(processed[:commissions_total]).to eq(1234.56)
    end
  end

  context 'when commissions_total uses both comma and dot as US-style thousands and decimal' do
    let(:row) { super().merge('commissions_total' => '1,234,567.89') }

    it 'removes commas, parses float' do
      expect(processed[:commissions_total]).to eq(1_234_567.89)
    end
  end

  context 'when commissions_total is a negative number' do
    let(:row) { super().merge('commissions_total' => '-123.45') }

    it 'parses negative values as float' do
      expect(processed[:commissions_total]).to eq(-123.45)
    end
  end

  context 'when commissions_total contains just non-numeric garbage' do
    let(:row) { super().merge('commissions_total' => 'hello,world!') }

    it 'returns 0.0 for commissions_total' do
      expect(processed[:commissions_total]).to eq(0.0)
    end
  end

  context 'when commissions_total is nil' do
    let(:row) { super().merge('commissions_total' => nil) }

    it 'returns 0.0 for commissions_total' do
      expect(processed[:commissions_total]).to eq(0.0)
    end
  end

  context 'when website_url is blank' do
    let(:row) { super().merge('website_url' => '  ') }

    it 'returns nil for website_url' do
      expect(processed[:website_url]).to be_nil
    end
  end

  context 'when commissions_total is blank' do
    let(:row) { super().merge('commissions_total' => '') }

    it 'returns 0.0 for commissions_total' do
      expect(processed[:commissions_total]).to eq(0.0)
    end
  end

  context 'when commissions_total uses dot as decimal separator' do
    let(:row) { super().merge('commissions_total' => '567.89') }

    it 'parses value correctly' do
      expect(processed[:commissions_total]).to eq(567.89)
    end
  end

  context 'when commissions_total has non-numeric characters' do
    let(:row) { super().merge('commissions_total' => '$2,345.67abc') }

    it 'parses and strips non-numeric, returning correct float' do
      expect(processed[:commissions_total]).to eq(2345.67)
    end
  end

  context 'when website_url already has protocol' do
    let(:row) { super().merge('website_url' => 'https://secure.com') }

    it 'does not add protocol again' do
      expect(processed[:website_url]).to eq('https://secure.com')
    end
  end

  context 'when required fields are missing' do
    let(:row) { {} }

    it 'returns nil for merchant_slug if missing' do
      expect(processed[:merchant_slug]).to be_nil
    end

    it 'returns nil for first_name if missing' do
      expect(processed[:first_name]).to be_nil
    end

    it 'returns nil for last_name if missing' do
      expect(processed[:last_name]).to be_nil
    end

    it 'returns nil for email if missing' do
      expect(processed[:email]).to be_nil
    end

    it 'returns nil for website_url if missing' do
      expect(processed[:website_url]).to be_nil
    end

    it 'returns 0.0 for commissions_total if missing' do
      expect(processed[:commissions_total]).to eq(0.0)
    end
  end

  context 'when row keys are symbols' do
    let(:row) do
      {
        merchant_slug: ' spacey ',
        first_name: '  Joe',
        last_name: 'Bloggs ',
        email: ' TEST@EXAMPLE.COM ',
        website_url: 'site.com',
        commissions_total: '987,65'
      }
    end

    it 'processes merchant_slug correctly' do
      expect(processed[:merchant_slug]).to eq('spacey')
    end

    it 'processes first_name correctly' do
      expect(processed[:first_name]).to eq('Joe')
    end

    it 'processes last_name correctly' do
      expect(processed[:last_name]).to eq('Bloggs')
    end

    it 'normalizes email correctly' do
      expect(processed[:email]).to eq('test@example.com')
    end

    it 'normalizes website_url correctly' do
      expect(processed[:website_url]).to eq('http://site.com')
    end

    it 'parses commissions_total correctly' do
      expect(processed[:commissions_total]).to eq(987.65)
    end
  end
end
