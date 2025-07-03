# frozen_string_literal: true

module Affiliates
  class Filter
    def initialize(params)
      @params = params
      @relation = Affiliate.includes(:merchant).order(created_at: :desc)
    end

    # Executes the search and returns the paginated relation
    #
    # @return [ActiveRecord::Relation]
    def results
      filter
      paginate
      @relation
    end

    # Returns pagination metadata
    #
    # @return [Hash]
    def meta
      {
        total_count: pagination.total_count,
        total_pages: pagination.total_pages,
        offset: pagination.offset
      }
    end

    private

    attr_reader :params, :pagination

    def filter
      @relation = @relation.search(params[:search]) if params[:search].present?
      @relation = @relation.filter_by_merchant(params[:merchant_filter]) if params[:merchant_filter].present?
      @relation = @relation.with_min_commission(params[:commission_min]) if params[:commission_min].to_f.positive?
      @relation = @relation.with_max_commission(params[:commission_max]) if params[:commission_max].to_f.positive?
    end

    def paginate
      @pagination = Pagination.new(@relation, params)
      @relation = @pagination.paginated_relation
    end
  end
end
