# frozen_string_literal: true

# Handles display and filtering of import audit logs.
#
# Provides paginated and filterable views of past CSV imports,
# along with metadata statistics.
class ImportAuditsController < ApplicationController
  before_action :set_import_audit, only: [:show]

  # Displays a list of import audits with optional filters and pagination.
  # @return [void]
  def index
    query = ImportAudits::Filter.new(filter_params)
    assign_collection(query)
    @stats = ImportAudits::Statistics.call
    @filter_params = filter_params
  end

  # Shows a single import audit.
  #
  # @example
  #   GET /dashboard/import_audits/:id
  #
  # @return [void]
  def show; end

  private

  # Finds the import audit for the `show` action.
  #
  # @return [void]
  def set_import_audit
    @import_audit = ImportAudit.find(params[:id])
  end

  # Extracts filtering and pagination parameters from the request.
  #
  # @return [ActionController::Parameters]
  def filter_params
    params.permit(
      :search, :status_filter, :type_filter,
      :date_from, :date_to, :page, :per_page
    )
  end

  # Assigns the paginated result set and metadata to instance variables.
  #
  # @param query [ImportAudits::Filter]
  # @return [void]
  def assign_collection(query)
    @import_audits = query.results

    pagination = query.pagination
    @page        = pagination.page
    @per_page    = pagination.per_page
    @total_count = pagination.total_count
    @total_pages = pagination.total_pages
    @offset      = pagination.offset
  end
end
