import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tableContainer", "filterForm"];
  static values = {
    debounceDelay: { type: Number, default: 500 },
    baseUrl: { type: String, default: "/dashboard/affiliates" },
  };

  connect() {
    console.log("Affiliates table controller connected");
    this.debounceTimer = null;
  }

  disconnect() {
    this.clearDebounceTimer();
  }

  debounceFilter(event) {
    this.clearDebounceTimer();
    this.debounceTimer = setTimeout(() => {
      this.filterAffiliates(event);
    }, this.debounceDelayValue);
  }

  filterAffiliates(event) {
    event?.preventDefault();
    const params = this.buildParams();
    this.loadAffiliates(`${this.baseUrlValue}?${params}`);
  }

  loadPage(event) {
    event.preventDefault();
    const page = event.currentTarget.dataset.page;
    const params = this.buildParams({ page });
    this.loadAffiliates(`${this.baseUrlValue}?${params}`);
  }

  async loadAffiliates(url) {
    try {
      this.showLoadingState();

      const response = await fetch(url, {
        headers: {
          Accept: "text/html",
          "X-Requested-With": "XMLHttpRequest",
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const html = await response.text();
      this.updateTableContainer(html);
      this.updateUrl(url);
      this.scrollToTable();
    } catch (error) {
      console.error("Error loading affiliates:", error);
      this.showErrorState();
    }
  }

  // Private methods
  clearDebounceTimer() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = null;
    }
  }

  buildParams(additionalParams = {}) {
    const formData = new FormData(this.filterFormTarget);

    // Add any additional params (like page)
    Object.entries(additionalParams).forEach(([key, value]) => {
      formData.set(key, value);
    });

    return new URLSearchParams(formData).toString();
  }

  updateTableContainer(html) {
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, "text/html");
    const newTableContainer = doc.querySelector("#table_container");

    if (!newTableContainer) {
      throw new Error("Table container not found in response");
    }

    this.tableContainerTarget.innerHTML = newTableContainer.innerHTML;
  }

  updateUrl(url) {
    window.history.pushState({}, "", url);
  }

  scrollToTable() {
    this.tableContainerTarget.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
  }

  showLoadingState() {
    this.tableContainerTarget.innerHTML = this.loadingTemplate;
  }

  showErrorState() {
    this.tableContainerTarget.innerHTML = this.errorTemplate;
  }

  get loadingTemplate() {
    return `
      <div class="card border-0 shadow-sm">
        <div class="card-body text-center py-5">
          <div class="spinner-border text-primary mb-3" role="status">
            <span class="visually-hidden">Loading...</span>
          </div>
          <p class="text-muted mb-0">Loading affiliates...</p>
        </div>
      </div>
    `;
  }

  get errorTemplate() {
    return `
      <div class="card border-0 shadow-sm">
        <div class="card-body text-center py-5">
          <div class="text-danger mb-3">
            <i class="bi bi-exclamation-triangle fs-1"></i>
          </div>
          <h5 class="text-danger">Error Loading Data</h5>
          <p class="text-muted">There was an error loading the affiliates. Please try again.</p>
          <button class="btn btn-primary" onclick="location.reload()">
            <i class="bi bi-arrow-clockwise me-2"></i>Retry
          </button>
        </div>
      </div>
    `;
  }
}
