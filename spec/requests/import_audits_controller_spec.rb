# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ImportAuditsController' do
  describe 'GET /dashboard/import_audits' do
    let(:processed_import) { create(:import_audit, :processed, filename: 'sales_q1.csv') }
    let(:failed_import)    { create(:import_audit, :failed, filename: 'sales_q2.csv') }

    before do
      processed_import
      failed_import
    end

    context 'when visiting the index page' do
      it 'returns a successful response' do
        get dashboard_import_audits_path
        expect(response).to have_http_status(:ok)
      end

      it 'renders the expected heading' do
        get dashboard_import_audits_path
        expect(response.body).to include('Import Logs')
      end
    end

    context 'when filtering by status' do
      it 'includes only matching imports' do
        get dashboard_import_audits_path(status_filter: 'processed')
        expect(response.body).to include(processed_import.filename)
      end

      it 'excludes non-matching imports' do
        get dashboard_import_audits_path(status_filter: 'processed')
        expect(response.body).not_to include(failed_import.filename)
      end
    end

    context 'when searching by filename' do
      it 'includes matching records' do
        get dashboard_import_audits_path(search: 'q2')
        expect(response.body).to include(failed_import.filename)
      end

      it 'excludes non-matching records' do
        get dashboard_import_audits_path(search: 'q2')
        expect(response.body).not_to include(processed_import.filename)
      end
    end

    context 'when filtering by type' do
      it 'includes records with matching import_type' do
        get dashboard_import_audits_path(type_filter: failed_import.import_type)
        expect(response.body).to include(failed_import.filename)
      end
    end

    context 'when paginating' do
      it 'renders page 2 with paginated record' do
        get dashboard_import_audits_path(per_page: 1, page: 2)
        expect(response).to have_http_status(:ok)
      end

      it 'includes at least one of the expected filenames on page 2' do
        get dashboard_import_audits_path(per_page: 1, page: 2)
        expect(response.body).to match(/sales_q[12]\.csv/)
      end
    end

    context 'when rendering statistics' do
      it 'shows the stats section title' do
        get dashboard_import_audits_path
        expect(response.body).to include('Total Imports')
      end

      it 'shows some status summary text' do
        get dashboard_import_audits_path
        expect(response.body).to match(/Processed|Failed|Pending/)
      end
    end
  end

  describe 'GET /dashboard/import_audits/:id' do
    let(:import_audit) { create(:import_audit, filename: 'details_test.csv') }

    it 'returns a successful response' do
      get import_audit_path(import_audit)
      expect(response).to have_http_status(:ok)
    end

    it 'displays the filename on the page' do
      get import_audit_path(import_audit)
      expect(response.body).to include(import_audit.filename)
    end
  end
end
