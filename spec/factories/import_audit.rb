# frozen_string_literal: true

FactoryBot.define do
  factory :import_audit do
    path        { "csv_uploads/#{Faker::Internet.uuid}/#{Faker::File.file_name(ext: 'csv')}" }
    filename    { Faker::File.file_name(ext: 'csv') }
    status      { ImportAudit::VALID_STATUSES.sample }
    import_type { ImportAudit::VALID_IMPORT_TYPES.sample }
    row_count   { 10 }
    total_successful_rows { 8 }
    total_failed_rows     { 2 }
    error_message         { [nil, Faker::Lorem.sentence(word_count: 10)].sample }
    processed_at          { [nil, Faker::Time.backward(days: 7, period: :evening)].sample }

    trait :pending do
      status { 'pending' }
      processed_at { nil }
    end

    trait :processing do
      status { 'processing' }
      processed_at { nil }
    end

    trait :processed do
      status { 'processed' }
      processed_at { Faker::Time.backward(days: 1, period: :evening) }
      error_message { nil }
    end

    trait :failed do
      status { 'failed' }
      processed_at { Faker::Time.backward(days: 1, period: :evening) }
      error_message { Faker::Lorem.sentence(word_count: 6) }
    end
  end
end
