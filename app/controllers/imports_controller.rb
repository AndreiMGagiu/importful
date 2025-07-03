# frozen_string_literal: true

# Controller responsible for generating S3 presigned URLs for CSV imports.
# @return [JSON] Presigned URL and associated metadata
class ImportsController < ApplicationController
  protect_from_forgery with: :null_session

  # Generates a presigned S3 URL for direct file upload and creates an ImportAudit record.
  #
  # @return [void]
  # @raise [Aws::Errors::ServiceError] if AWS credentials or network issues cause a failure
  # @raise [ActiveRecord::RecordInvalid] if ImportAudit creation fails validation
  def create
    render json: signed_url
  rescue Aws::Errors::ServiceError, ActiveRecord::RecordInvalid => error
    log_error(error, params)
    render json: { error: 'Failed to generate signed URL' }, status: :internal_server_error
  end

  private

  # Instantiates and calls the GenerateSignedUrl service.
  #
  # @return [Hash] Hash containing the S3 direct_upload URL and the key
  def signed_url
    Affiliates::GeneratePresignedUrl.new(
      filename: params[:filename],
      content_type: params[:content_type]
    ).call
  end

  # Logs details about any error encountered while generating the presigned URL.
  #
  # @param error [StandardError] the rescued error
  # @param info [ActionController::Parameters] the incoming params
  # @return [void]
  def log_error(error, info)
    Rails.logger.error(
      message: 'Unable to generate signed URL',
      error: error.message,
      params: info.slice(:filename, :content_type),
      request_id: request.request_id
    )
  end
end
