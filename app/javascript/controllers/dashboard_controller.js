import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["statsContainer"];
  static values = {
    statsUrl: { type: String, default: "/dashboard/stats" },
    notificationDuration: { type: Number, default: 3000 },
  };

  connect() {
    console.log("Dashboard controller connected");
  }

  async refreshStats(event) {
    event.preventDefault();

    const button = event.currentTarget;
    this.setButtonLoading(button, true);

    try {
      const response = await fetch(this.statsUrlValue, {
        headers: {
          Accept: "application/json",
          "X-Requested-With": "XMLHttpRequest",
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      this.updateStatsDisplay(data);
      this.showNotification("Stats refreshed successfully!", "success");
    } catch (error) {
      console.error("Error refreshing stats:", error);
      this.showNotification("Error refreshing stats", "error");
    } finally {
      this.setButtonLoading(button, false);
    }
  }

  updateStatsDisplay(data) {
    const statsMapping = [
      { key: "total_affiliates", formatter: (val) => this.formatNumber(val) },
      { key: "total_merchants", formatter: (val) => this.formatNumber(val) },
      {
        key: "total_commissions",
        formatter: (val) => `$${this.formatNumber(val, 2)}`,
      },
      {
        key: "avg_commission",
        formatter: (val) => `$${this.formatNumber(val, 2)}`,
      },
    ];

    const statsCards = this.statsContainerTarget.querySelectorAll(".card");

    statsMapping.forEach((stat, index) => {
      const card = statsCards[index];
      const valueElement = card?.querySelector("h3");

      if (valueElement && data[stat.key] !== undefined) {
        valueElement.textContent = stat.formatter(data[stat.key]);
      }
    });
  }

  setButtonLoading(button, isLoading) {
    if (isLoading) {
      button.dataset.originalContent = button.innerHTML;
      button.innerHTML =
        '<i class="bi bi-arrow-clockwise me-2 spinner-border spinner-border-sm"></i>Refreshing...';
      button.disabled = true;
    } else {
      button.innerHTML = button.dataset.originalContent;
      button.disabled = false;
      delete button.dataset.originalContent;
    }
  }

  formatNumber(num, decimals = 0) {
    if (num === null || num === undefined) return "0";

    return new Intl.NumberFormat("en-US", {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    }).format(num);
  }

  showNotification(message, type = "info") {
    const alertClass = type === "error" ? "danger" : "success";

    const toast = document.createElement("div");
    toast.className = `alert alert-${alertClass} alert-dismissible fade show position-fixed`;
    toast.style.cssText =
      "top: 20px; right: 20px; z-index: 9999; min-width: 300px;";
    toast.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;

    document.body.appendChild(toast);

    setTimeout(() => {
      toast.remove();
    }, this.notificationDurationValue);
  }
}
