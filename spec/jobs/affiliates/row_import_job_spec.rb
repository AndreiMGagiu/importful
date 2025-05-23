# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

RSpec.describe Affiliates::RowImportJob, type: :job do
  let(:raw_row) { { 'email' => 'test@example.com', 'merchant_slug' => 'amazon' } }
  let(:line_number) { 5 }
  let(:audit_id) { 123 }

  describe 'queueing' do
    it 'enqueues the job to the row_import queue' do
      expect {
        described_class.perform_async(raw_row, line_number, audit_id)
      }.to change(described_class.jobs, :size).by(1)

      expect(described_class.jobs.last['queue']).to eq('row_import')
    end
  end
end
