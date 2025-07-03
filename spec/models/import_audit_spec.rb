# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportAudit do
  subject(:import_audit) { build(:import_audit) }

  describe '#path' do
    it { is_expected.to validate_presence_of(:path) }
  end

  describe '#status' do
    it { is_expected.to validate_presence_of(:status) }

    ImportAudit::VALID_STATUSES.each do |valid_status|
      it { is_expected.to allow_value(valid_status).for(:status) }
    end

    it { is_expected.not_to allow_value('bad_status').for(:status) }
  end

  describe '#import_type' do
    it { is_expected.to validate_presence_of(:import_type) }

    ImportAudit::VALID_IMPORT_TYPES.each do |valid_type|
      it { is_expected.to allow_value(valid_type).for(:import_type) }
    end

    it { is_expected.not_to allow_value('invalid_type').for(:import_type) }
  end

  describe '#total_successful_rows' do
    it 'can be nil or any integer' do
      expect(build(:import_audit, total_successful_rows: nil)).to be_valid
      expect(build(:import_audit, total_successful_rows: 0)).to be_valid
      expect(build(:import_audit, total_successful_rows: 50)).to be_valid
    end
  end

  describe '#total_failed_rows' do
    it 'can be nil or any integer' do
      expect(build(:import_audit, total_failed_rows: nil)).to be_valid
      expect(build(:import_audit, total_failed_rows: 0)).to be_valid
      expect(build(:import_audit, total_failed_rows: 10)).to be_valid
    end
  end

  describe '#error_message' do
    it 'can be nil or any string' do
      expect(build(:import_audit, error_message: nil)).to be_valid
      expect(build(:import_audit, error_message: 'some error')).to be_valid
    end
  end

  describe '#processed_at' do
    it 'can be nil or a datetime' do
      expect(build(:import_audit, processed_at: nil)).to be_valid
      expect(build(:import_audit, processed_at: Time.current)).to be_valid
    end
  end
end
