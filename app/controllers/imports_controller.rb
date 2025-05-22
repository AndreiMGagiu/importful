# frozen_string_literal: true

class ImportsController < ApplicationController
  def create
    return respond_with_error('No file uploaded') if params[:file].blank?

    result = Affiliates::Import::Orchestrator.new(params[:file]).call

    respond_to do |format|
      format.json { respond_with_json(result) }
      format.html { respond_with_html(result) }
    end
  end
end