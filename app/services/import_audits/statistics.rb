# frozen_string_literal: true

module ImportAudits
  class Statistics
    def self.call
      stats = ImportAudit.group(:status).count
      total = stats.values.sum
      
      {
        total_imports: total,
        processed_imports: stats['processed'] || 0,
        failed_imports: stats['failed'] || 0,
        pending_imports: stats['pending'] || 0,
        total_rows_processed: ImportAudit.sum('total_successful_rows + total_failed_rows'),
        success_rate: total.positive? ? ((stats['processed'] || 0).to_f / total * 100).round(1) : 0
      }
    end
  end
end