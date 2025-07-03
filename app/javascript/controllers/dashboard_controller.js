import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["statsContainer"];
  static values = {
    statsUrl: { type: String, default: "/dashboard/stats" },
    notificationDuration: { type: Number, default: 3000 },
  };

  connect() {
    console.log("Dashboard controller connected");
    this.setupPerformanceOptimizations();
  }

  setupPerformanceOptimizations() {
    // Debounce resize events for responsive adjustments
    this.resizeHandler = this.debounce(() => {
      this.handleResize();
    }, 250);

    window.addEventListener("resize", this.resizeHandler);
  }

  disconnect() {
    window.removeEventListener("resize", this.resizeHandler);
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
      this.showNotification(
        "Failed to refresh stats. Please try again.",
        "error"
      );
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
        // Animate the number change
        this.animateNumberChange(valueElement, stat.formatter(data[stat.key]));
      }
    });
  }

  animateNumberChange(element, newValue) {
    element.style.transform = "scale(1.05)";
    element.style.transition = "transform 0.2s ease";

    setTimeout(() => {
      element.textContent = newValue;
      element.style.transform = "scale(1)";
    }, 100);
  }

  setButtonLoading(button, isLoading) {
    if (isLoading) {
      button.dataset.originalContent = button.innerHTML;
      button.innerHTML =
        '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Refreshing...';
      button.disabled = true;
      button.classList.add("loading");
    } else {
      button.innerHTML = button.dataset.originalContent;
      button.disabled = false;
      button.classList.remove("loading");
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
    const iconClass =
      type === "error" ? "bi-exclamation-triangle" : "bi-check-circle";

    const toast = document.createElement("div");
    toast.className = `alert alert-${alertClass} alert-dismissible fade show position-fixed shadow-sm`;
    toast.style.cssText =
      "top: 20px; right: 20px; z-index: 9999; min-width: 300px; border: none;";
    toast.innerHTML = `
      <div class="d-flex align-items-center">
        <i class="${iconClass} me-2"></i>
        <span>${message}</span>
      </div>
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `;

    document.body.appendChild(toast);

    // Auto-remove after duration
    setTimeout(() => {
      if (toast.parentNode) {
        toast.classList.remove("show");
        setTimeout(() => toast.remove(), 150);
      }
    }, this.notificationDurationValue);
  }

  handleResize() {
    // Handle responsive adjustments if needed
    const isMobile = window.innerWidth < 768;

    if (isMobile) {
      // Mobile-specific optimizations
      this.optimizeForMobile();
    } else {
      // Desktop optimizations
      this.optimizeForDesktop();
    }
  }

  optimizeForMobile() {
    // Add mobile-specific optimizations
    const tables = document.querySelectorAll(".table-responsive");
    tables.forEach((table) => {
      table.style.fontSize = "0.875rem";
    });
  }

  optimizeForDesktop() {
    // Add desktop-specific optimizations
    const tables = document.querySelectorAll(".table-responsive");
    tables.forEach((table) => {
      table.style.fontSize = "";
    });
  }

  // Utility function for debouncing
  debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }
}
