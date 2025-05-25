# app/services/dashboard/statistics.rb
module Dashboard
  class Statistics
    def self.call
      total_commissions = Affiliate.sum(:commissions_total) || 0
      avg_commission = Affiliate.average(:commissions_total) || 0

      {
        total_affiliates: Affiliate.count,
        total_merchants: Merchant.count,
        total_commissions: total_commissions.round(2),
        avg_commission: avg_commission.round(2),
        affiliates_this_month: Affiliate.where(created_at: 1.month.ago..Time.current).count
      }
    end
  end
end
