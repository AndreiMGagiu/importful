require 'rails_helper'

RSpec.describe Merchant, type: :model do
  subject(:merchant) { build(:merchant) }

  describe '#affiliates' do
    it { should have_many(:affiliates) }
  end

  describe '#slug' do
    it { should validate_presence_of(:slug) }
    it { should validate_uniqueness_of(:slug) }

    it { should allow_value('valid-slug').for(:slug) }
    it { should allow_value('valid-slug-123').for(:slug) }
    it { should allow_value('validslug').for(:slug) }
    it { should allow_value('123').for(:slug) }

    it { should_not allow_value('Invalid_Slug').for(:slug) }
    it { should_not allow_value('invalid slug').for(:slug) }
    it { should_not allow_value('-invalid-slug-').for(:slug) }
    it { should_not allow_value('invalid_slug').for(:slug) }
  end
end
