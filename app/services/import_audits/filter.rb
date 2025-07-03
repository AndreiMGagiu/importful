# frozen_string_literal: true

module ImportAudits
  # Filters and paginates ImportAudit records based on various parameters.
  #
  class Filter
    attr_reader :pagination

    # Initializes the filter and applies all filtering and pagination.
    #
    # @param params [ActionController::Parameters, Hash]
    def initialize(params)
      @params = params
      @relation = ImportAudit.order(created_at: :desc)
      by_status
      by_type
      by_search
      date_from
      date_to
      apply_pagination
    end

    # Returns the filtered and paginated ImportAudit records.
    #
    # @return [ActiveRecord::Relation]
    def results
      @relation
    end

    private

    attr_reader :params

    # Filters by status (e.g. "processed", "failed").
    #
    # @return [void]
    def by_status
      return if params[:status_filter].blank?

      @relation = @relation.where(status: params[:status_filter])
    end

    # Filters by import type (e.g. "affiliates", "merchants").
    #
    # @return [void]
    def by_type
      return if params[:type_filter].blank?

      @relation = @relation.where(import_type: params[:type_filter])
    end

    # Filters by filename keyword search (case-insensitive).
    #
    # @return [void]
    def by_search
      return if params[:search].blank?

      term = "%#{params[:search].strip.downcase}%"
      @relation = @relation.where('LOWER(filename) LIKE ?', term)
    end

    # Applies start date filter to `created_at`.
    #
    # @return [void]
    def date_from
      return if params[:date_from].blank?

      from = safe_parse_date(params[:date_from])&.beginning_of_day
      @relation = @relation.where(created_at: from..) if from
    end

    # Applies end date filter to `created_at`.
    #
    # @return [void]
    def date_to
      return if params[:date_to].blank?

      to = safe_parse_date(params[:date_to])&.end_of_day
      @relation = @relation.where(created_at: ..to) if to
    end

    # Safely parses a date string to a Date object.
    #
    # @param date_str [String]
    # @return [Date, nil]
    def safe_parse_date(date_str)
      Date.parse(date_str)
    rescue ArgumentError, TypeError
      nil
    end

    # Applies pagination to the filtered relation.
    #
    # @return [void]
    def apply_pagination
      @pagination = Pagination.new(@relation, params)
      @relation = @pagination.paginated_relation
    end
  end
end
