require 'rails_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

RSpec.describe Affiliates::ProcessCsvImportJob, type: :job do
  let(:s3_event_data) { "some json" }

  it 'enqueues the job to the correct queue' do
    expect {
      described_class.perform_async(s3_event_data)
    }.to change(described_class.jobs, :size).by(1)

    expect(described_class.jobs.last['queue']).to eq('csv_process')
  end
end
