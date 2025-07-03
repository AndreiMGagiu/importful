module Affiliates
  # A Sidekiq job responsible for handling S3 event data and triggering CSV import.
  # This job is typically enqueued by an Amazon SNS webhook notification after a file upload.
  class ProcessCsvImportJob
    include Sidekiq::Job
    sidekiq_options queue: 'csv_process'

    # Performs the job to process the given S3 event data.
    # Initializes and runs the FetchCsvData service, which downloads and parses the CSV,
    # then triggers the orchestrator to import affiliate records.
    #
    # @param s3_event_data [String] JSON string representing the S3 event message from SNS
    # @return [void]
    def perform(s3_event_data)
      FetchCsvData.new(s3_event_data).call
    end
  end
end
