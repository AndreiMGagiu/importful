# frozen_string_literal: true

# Controller responsible for rendering dashboard data and affiliate records.
#
# Provides HTML and JSON endpoints for dashboard statistics, affiliate listings,
# and top merchant summaries.
class DashboardController < ApplicationController
  # Renders the main dashboard with statistics, recent affiliates, and top merchants.
  #
  # @example
  #   GET /dashboard
  #
  # @return [void]
  def index
    @stats = Dashboard::Statistics.call
    @recent_affiliates = Affiliate.includes(:merchant)
      .order(created_at: :desc)
      .limit(5)

    @top_merchants = TopMerchantsQuery.call
  end

  # Renders a list of affiliates with optional filters and pagination.
  # Responds with either HTML or JSON depending on the request format.
  #
  # @example
  #   GET /dashboard/affiliates?page=2&search=john
  #
  # @return [void]
  # app/controllers/dashboard_controller.rb

  def affiliates
    filter = affiliate_filter
    @affiliates = filter.results
    meta = filter.meta

    @page = params[:page].to_i
    @per_page = params[:per_page].to_i
    @total_count = meta[:total_count]
    @total_pages = meta[:total_pages]
    @offset = meta[:offset]

    respond_to do |format|
      format.html
      format.json do
        render json: {
          affiliates: @affiliates.as_json(include: :merchant),
          page: @page,
          per_page: @per_page,
          total_count: @total_count,
          total_pages: @total_pages,
          offset: @offset
        }
      end
    end
  end

  # Returns dashboard statistics as JSON (used by async widgets or front-end updates).
  #
  # @example
  #   GET /dashboard/stats.json
  #
  # @return [void]
  def stats
    render json: Dashboard::Statistics.call
  end

  private

  # @return [Affiliates::Filter]
  def affiliate_filter
    Affiliates::Filter.new(params)
  end
end
