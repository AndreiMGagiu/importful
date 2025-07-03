# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliates::Import::Processor do
  subject(:processor_service) { described_class.new(row, result, line)}

  let(:result) { Affiliates::Import::Result.new }
  let(:line) { 5 }
  let(:merchant) { create(:merchant, slug: 'test-merchant') }
  let(:row) do
    {
      merchant_slug: merchant.slug,
      email: 'test@example.com',
      first_name: 'John',
      last_name: 'Doe',
      website_url: 'https://example.com',
      commissions_total: 1000.50
    }
  end

  describe '#call' do
    context 'when merchant does not exist' do
      let(:row) { { merchant_slug: 'non-existent-merchant', email: 'x' } }

      before { processor_service.call }

      it 'increments total count' do
        expect(result.total).to eq(1)
      end

      it 'adds an error about unknown merchant slug' do
        messages = result.errors.map(&:message)
        expect(messages).to include("Line #{line}: Unknown merchant slug 'non-existent-merchant'")
      end

      it 'includes the correct line number in the error' do
        lines = result.errors.map(&:line)
        expect(lines).to include(line)
      end
    end

    context 'when merchant exists' do
      context 'when affiliate is new' do
        it 'creates a new affiliate' do
          expect { processor_service.call }.to change(Affiliate, :count).by(1)
        end

        context 'when persisted' do
          before { processor_service.call }

          let(:affiliate) { Affiliate.last }

          it 'increments total' do
            expect(result.total).to eq(1)
          end

          it 'increments created' do
            expect(result.created).to eq(1)
          end

          it 'does not increment updated' do
            expect(result.updated).to eq(0)
          end

          it 'does not add errors' do
            expect(result.errors).to be_empty
          end
        end
      end

      context 'when affiliate exists and has changes' do
        before do
          create(:affiliate, merchant: merchant, email: 'test@example.com',
            first_name: 'Jane', last_name: 'Smith',
            website_url: 'https://old-site.com', commissions_total: 500.25)
        end

        it 'does not change Affiliate count' do
          expect { processor_service.call }.not_to change(Affiliate, :count)
        end

        context 'when persisted' do
          before { processor_service.call }

          let(:affiliate) { Affiliate.last }

          it 'increments total' do
            expect(result.total).to eq(1)
          end

          it 'increments updated' do
            expect(result.updated).to eq(1)
          end

          it 'does not increment created' do
            expect(result.created).to eq(0)
          end

          it 'does not add errors' do
            expect(result.errors).to be_empty
          end
        end
      end

      context 'when affiliate exists and has no changes' do
        before do
          create(:affiliate, merchant: merchant, email: 'test@example.com',
            first_name: 'John', last_name: 'Doe',
            website_url: 'https://example.com', commissions_total: 1000.50)
        end

        it 'does not update the affiliate' do
          expect { processor_service.call }.not_to(change { Affiliate.last.updated_at })
        end

        context 'when persisted' do
          before { processor_service.call }

          it 'increments total' do
            expect(result.total).to eq(1)
          end

          it 'does not increment created' do
            expect(result.created).to eq(0)
          end

          it 'does not increment updated' do
            expect(result.updated).to eq(0)
          end

          it 'does not add errors' do
            expect(result.errors).to be_empty
          end
        end
      end

      context 'when affiliate fails to save' do
        let(:row) do
          {
            merchant_slug: merchant.slug,
            email: 'invalid-email',
            first_name: 'John',
            last_name: 'Doe',
            website_url: 'https://example.com',
            commissions_total: 1000.50
          }
        end

        it 'does not create a new affiliate' do
          expect { processor_service.call }.not_to change(Affiliate, :count)
        end

        context 'when persisted' do
          before { processor_service.call }

          it 'increments total' do
            expect(result.total).to eq(1)
          end

          it 'does not increment created' do
            expect(result.created).to eq(0)
          end

          it 'does not increment updated' do
            expect(result.updated).to eq(0)
          end

          it 'adds an error about invalid email' do
            messages = result.errors.map(&:message)
            expect(messages.any? { |m| m.include?('Email is invalid') }).to be true
          end

          it 'includes the correct line number in the error' do
            lines = result.errors.map(&:line)
            expect(lines).to include(line)
          end
        end
      end
    end
  end
end
