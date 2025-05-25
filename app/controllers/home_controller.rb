# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @stats = {
      total_affiliates: Affiliate.count,
      total_merchants: Merchant.count,
      total_commissions: Affiliate.sum(:commissions_total) || 0
    }
  end
end
