require 'rails_helper'

RSpec.describe Affiliate, type: :model do
  let(:merchant) { create(:merchant) }
  subject(:affiliate) { build(:affiliate, merchant: merchant) }

  describe '#merchant' do
    it { should belong_to(:merchant) }
  end

  describe '#first_name' do
    it { should validate_presence_of(:first_name) }
  end

  describe '#last_name' do
    it { should validate_presence_of(:last_name) }
  end

  describe '#website_url' do
    it { should allow_value(nil).for(:website_url) }
    it { should allow_value('http://example.com').for(:website_url) }
    it { should_not allow_value('invalid_url').for(:website_url) }
  end

  describe '#email' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).scoped_to(:merchant_id) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
    it { should_not allow_value('user@localhost').for(:email) }
  end

  describe '#commissions_total' do
    it { should validate_numericality_of(:commissions_total).is_greater_than_or_equal_to(0) }
  end
end
