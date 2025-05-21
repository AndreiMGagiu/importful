require 'rails_helper'

RSpec.describe "Imports", type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /" do
    pending "imports a file"
  end
end
