# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliates::Import::Result do
  subject(:result) { described_class.new }

  describe 'initialization' do
    it 'sets total to zero' do
      expect(result.total).to eq(0)
    end

    it 'sets created to zero' do
      expect(result.created).to eq(0)
    end

    it 'sets updated to zero' do
      expect(result.updated).to eq(0)
    end

    it 'initializes errors as empty array' do
      expect(result.errors).to be_empty
    end
  end

  describe '#increment_total' do
    it 'increments the total count' do
      expect { result.increment_total }.to change(result, :total).by(1)
    end
  end

  describe '#increment_created' do
    it 'increments the created count' do
      expect { result.increment_created }.to change(result, :created).by(1)
    end
  end

  describe '#increment_updated' do
    it 'increments the updated count' do
      expect { result.increment_updated }.to change(result, :updated).by(1)
    end
  end

  describe '#add_error' do
    before { result.add_error('Something went wrong', line: 42) }

    it 'adds an error to the errors array' do
      expect(result.errors.size).to eq(1)
    end

    it 'sets the error message' do
      expect(result.errors.last.message).to eq('Something went wrong')
    end

    it 'sets the error line' do
      expect(result.errors.last.line).to eq(42)
    end
  end

  describe '#add_error without line' do
    before { result.add_error('Row missing') }

    it 'adds an error with message only' do
      expect(result.errors.last.message).to eq('Row missing')
    end

    it 'sets the error line to nil' do
      expect(result.errors.last.line).to be_nil
    end
  end

  describe '#success?' do
    context 'when there are no errors' do
      it 'returns false if no rows were processed' do
        expect(result.success?).to be false
      end
    end

    context 'when there are errors' do
      before { result.add_error('Oops!') }

      it 'returns false' do
        expect(result.success?).to be false
      end
    end
  end
end
