// app/javascript/controllers/notifications_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["badge", "count", "list", "emptyState", "bellContainer"];

  connect() {
    // Initialize notifications array
    this.notifications = [];

    // For demo purposes, we can add a sample notification after a delay
    // This can be removed in production
    /*
    setTimeout(() => {
      this.addNotification({
        id: 1,
        title: "Welcome to Importful",
        message: "Start by uploading your first CSV file.",
        timestamp: new Date(),
        read: false,
        type: "info"
      });
    }, 2000);
    */

    // In a real app, you would set up a subscription to receive notifications
    // For example, using ActionCable:
    // this.channel = consumer.subscriptions.create("NotificationsChannel", {
    //   received: (data) => {
    //     this.addNotification(data.notification)
    //   }
    // })
  }

  disconnect() {
    // Clean up any subscriptions when the controller disconnects
    // if (this.channel) {
    //   this.channel.unsubscribe()
    // }
  }

  addNotification(notification) {
    // Store notification in our array
    this.notifications.push({
      ...notification,
      // Format the timestamp if it's a Date object
      formattedTime:
        notification.timestamp instanceof Date
          ? this.formatTimestamp(notification.timestamp)
          : notification.timestamp || "Just now",
    });

    // Hide empty state if it's visible
    this.emptyStateTarget.style.display = "none";

    // Create notification element
    const notificationEl = document.createElement("div");
    notificationEl.className = `notification-item p-3 border-bottom ${
      notification.read ? "bg-white" : "bg-light"
    }`;
    notificationEl.dataset.notificationId = notification.id;

    // Set icon based on notification type
    let iconClass = "bi-info-circle";
    let iconColor = "text-primary";

    if (notification.type === "success") {
      iconClass = "bi-check-circle";
      iconColor = "text-success";
    } else if (notification.type === "warning") {
      iconClass = "bi-exclamation-triangle";
      iconColor = "text-warning";
    } else if (notification.type === "error") {
      iconClass = "bi-x-circle";
      iconColor = "text-danger";
    }

    // Format time
    const timeDisplay =
      notification.timestamp instanceof Date
        ? this.formatTimestamp(notification.timestamp)
        : notification.time || "Just now";

    notificationEl.innerHTML = `
      <div class="d-flex">
        <div class="me-3">
          <i class="bi ${iconClass} ${iconColor} fs-5"></i>
        </div>
        <div class="flex-grow-1">
          <div class="d-flex justify-content-between align-items-center mb-1">
            <h6 class="mb-0 fw-semibold">${notification.title}</h6>
            <small class="text-muted">${timeDisplay}</small>
          </div>
          <p class="mb-0 small text-muted">${notification.message}</p>
        </div>
      </div>
    `;

    // Add click handler to mark as read
    notificationEl.addEventListener("click", () => {
      this.markAsRead(notification.id);
    });

    // Add to the list (newest first)
    this.listTarget.prepend(notificationEl);

    // Update notification count
    this.updateNotificationCount();

    // Flash the bell to draw attention
    this.flashBell();
  }

  updateNotificationCount() {
    // Count unread notifications
    const unreadCount = this.listTarget.querySelectorAll(".bg-light").length;

    // Update count and badge visibility
    this.countTarget.textContent = unreadCount;
    this.badgeTarget.style.display = unreadCount > 0 ? "block" : "none";

    // Show empty state if no notifications
    if (this.listTarget.children.length === 0) {
      this.emptyStateTarget.style.display = "block";
    }
  }

  markAsRead(id) {
    // Find the notification element
    const element = this.listTarget.querySelector(
      `[data-notification-id="${id}"]`
    );
    if (element) {
      element.classList.remove("bg-light");
      element.classList.add("bg-white");

      // Update the notification in our array
      const notification = this.notifications.find((n) => n.id == id);
      if (notification) {
        notification.read = true;
      }
    }

    // Update count
    this.updateNotificationCount();
  }

  markAllAsRead() {
    // Mark all notifications as read
    this.listTarget.querySelectorAll(".bg-light").forEach((el) => {
      el.classList.remove("bg-light");
      el.classList.add("bg-white");
    });

    // Update our array
    this.notifications.forEach((notification) => {
      notification.read = true;
    });

    // Update count
    this.updateNotificationCount();
  }

  clearAll() {
    // Clear all notifications
    this.listTarget.innerHTML = "";
    this.notifications = [];

    // Show empty state
    this.emptyStateTarget.style.display = "block";

    // Update count
    this.updateNotificationCount();
  }

  formatTimestamp(timestamp) {
    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now - date;
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHour / 24);

    if (diffSec < 60) return "Just now";
    if (diffMin < 60) return `${diffMin}m ago`;
    if (diffHour < 24) return `${diffHour}h ago`;
    if (diffDay < 7) return `${diffDay}d ago`;

    return date.toLocaleDateString();
  }

  // Add a visual effect to the bell when a new notification arrives
  flashBell() {
    const bell = this.bellContainerTarget.querySelector("i.bi-bell");
    if (bell) {
      // Add animation class
      bell.classList.add("bell-animation");

      // Remove it after animation completes
      setTimeout(() => {
        bell.classList.remove("bell-animation");
      }, 1000);
    }
  }
}
