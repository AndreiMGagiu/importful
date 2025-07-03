# app/queries/top_merchants_query.rb
class TopMerchantsQuery
  def self.call(limit: 5)
    Merchant.joins(:affiliates)
            .group('merchants.id, merchants.slug')
            .order('COUNT(affiliates.id) DESC')
            .limit(limit)
            .pluck('merchants.slug', 'COUNT(affiliates.id)')
  end
end
