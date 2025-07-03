# frozen_string_literal: true

module ErrorResponsesHelper
  extend ActiveSupport::Concern

  # Respond with an error message
  def respond_with_error(message)
    respond_to do |format|
      format.json { render json: { status: 'error', errors: [message] }, status: :unprocessable_entity }
      format.html { redirect_to root_path, alert: message }
    end
  end

  # Respond with JSON format
  def respond_with_json(result)
    status = result.success? ? :ok : :unprocessable_entity
    render json: response_payload(result), status: status
  end

  # Respond with HTML format
  def respond_with_html(result)
    if result.success?
      redirect_to root_path, notice: success_message(result)
    else
      redirect_to root_path, alert: failure_message(result)
    end
  end

  private

  # Format the response payload for JSON
  def response_payload(result)
    if result.success?
      {
        status: 'ok',
        total: result.total,
        created: result.created,
        updated: result.updated,
        errors: []
      }
    else
      {
        status: 'error',
        errors: format_errors(result.errors)
      }
    end
  end

  # Format success message for HTML
  def success_message(result)
    "Import completed: #{result.created} created, #{result.updated} updated"
  end

  # Format failure message for HTML
  def failure_message(result)
    "Import failed: #{format_errors(result.errors).join(', ')}"
  end

  # Helper method to format errors consistently
  def format_errors(errors)
    errors.map { |e| e.respond_to?(:message) ? e.message : e.to_s }
  end
end
