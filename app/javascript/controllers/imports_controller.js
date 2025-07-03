// app/javascript/controllers/imports_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "form",
    "fileInput",
    "dropArea",
    "fileDetails",
    "fileName",
    "fileSize",
    "submitButton",
    "uploadProgress",
    "progressBar",
    "progressPercentage",
    "processingStatus",
    "errorAlert",
    "errorMessage",
  ];

  connect() {
    ["dragenter", "dragover", "dragleave", "drop"].forEach((eventName) => {
      this.dropAreaTarget.addEventListener(
        eventName,
        this.preventDefaults,
        false
      );
    });

    ["dragenter", "dragover"].forEach((eventName) => {
      this.dropAreaTarget.addEventListener(
        eventName,
        this.highlight.bind(this),
        false
      );
    });

    ["dragleave", "drop"].forEach((eventName) => {
      this.dropAreaTarget.addEventListener(
        eventName,
        this.unhighlight.bind(this),
        false
      );
    });

    this.dropAreaTarget.addEventListener(
      "drop",
      this.handleDrop.bind(this),
      false
    );
    this.fileInputTarget.addEventListener(
      "change",
      this.fileSelected.bind(this)
    );
    this.submitButtonTarget.disabled = true;
  }

  preventDefaults(event) {
    event.preventDefault();
    event.stopPropagation();
  }

  highlight() {
    this.dropAreaTarget.classList.add("border-primary", "bg-light");
  }

  unhighlight() {
    this.dropAreaTarget.classList.remove("border-primary", "bg-light");
  }

  handleDrop(event) {
    const dt = event.dataTransfer;
    if (!dt.files || dt.files.length === 0) return;
    this.fileInputTarget.files = dt.files;
    this.fileSelected();
  }

  fileSelected() {
    const file = this.fileInputTarget.files[0];
    if (!file) {
      this.resetFileInput();
      return;
    }

    if (!file.name.toLowerCase().endsWith(".csv")) {
      this.showError("Please upload a valid CSV file.");
      this.resetFileInput();
      return;
    }

    this.fileNameTarget.textContent = file.name;
    this.fileSizeTarget.textContent = this.formatFileSize(file.size);
    this.fileDetailsTarget.classList.remove("d-none");
    this.submitButtonTarget.disabled = false;
    this.hideError();
  }

  removeFile(event) {
    event.preventDefault();
    this.resetFileInput();
    this.hideError();
  }

  resetFileInput() {
    this.fileInputTarget.value = "";
    this.fileDetailsTarget.classList.add("d-none");
    this.submitButtonTarget.disabled = true;
  }

  showError(message) {
    this.errorMessageTarget.textContent = message;
    this.errorAlertTarget.classList.remove("d-none");
  }

  hideError() {
    this.errorAlertTarget.classList.add("d-none");
    this.errorMessageTarget.textContent = "";
  }

  formatFileSize(bytes) {
    if (bytes === 0) return "0 Bytes";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`;
  }

  async submitForm(event) {
    event.preventDefault();

    const file = this.fileInputTarget.files[0];
    if (!file) return this.showError("Please select a CSV file");

    this.submitButtonTarget.disabled = true;
    this.uploadProgressTarget.classList.remove("d-none");
    this.processingStatusTarget.classList.add("d-none");
    this.updateProgress(0);

    try {
      const payload = {
        filename: file.name,
        content_type: file.type || "text/csv",
        size: file.size,
      };

      const response = await fetch("/imports", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.getCSRFToken(),
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Presign failed: ${response.status} ${errorText}`);
      }

      const { direct_upload, key } = await response.json();

      const uploadResponse = await fetch(direct_upload.url, {
        method: "PUT",
        headers: direct_upload.headers,
        body: file,
      });

      if (!uploadResponse.ok) {
        const errorText = await uploadResponse.text();
        throw new Error(
          `S3 upload failed: ${uploadResponse.status} ${errorText}`
        );
      }

      await this.fakeProgressBar();

      this.uploadProgressTarget.classList.add("d-none");
      this.processingStatusTarget.classList.remove("d-none");

      setTimeout(() => {
        this.processingStatusTarget.classList.add("d-none");
        this.showUploadSuccessMessage(file.name);
      }, 1000);
    } catch (error) {
      this.uploadProgressTarget.classList.add("d-none");
      this.processingStatusTarget.classList.add("d-none");
      this.showError("Upload failed: " + error.message);
    } finally {
      this.submitButtonTarget.disabled = false;
      this.updateProgress(0);
    }
  }

  getCSRFToken() {
    return (
      document
        .querySelector('meta[name="csrf-token"]')
        ?.getAttribute("content") || ""
    );
  }

  updateProgress(percent) {
    this.progressBarTarget.style.width = `${percent}%`;
    this.progressBarTarget.setAttribute("aria-valuenow", percent);
    this.progressPercentageTarget.textContent = `${percent}%`;
  }

  fakeProgressBar() {
    return new Promise((resolve) => {
      let progress = 0;
      const interval = setInterval(() => {
        progress += 10;
        if (progress > 100) {
          clearInterval(interval);
          resolve();
        } else {
          this.updateProgress(progress);
        }
      }, 100);
    });
  }

  showUploadSuccessMessage(fileName) {
    const successModal = document.getElementById("successModal");

    this.addUploadNotification(fileName);

    if (successModal) {
      const modalTitle =
        successModal.querySelector(".modal-title") ||
        successModal.querySelector("h3");
      if (modalTitle) {
        modalTitle.innerHTML = `
        <i class="bi bi-check-circle-fill text-success me-2"></i>
        Upload Complete!
      `;
      }

      const modalDescription = successModal.querySelector("p.text-muted");
      if (modalDescription) {
        modalDescription.innerHTML = `
        <div class="d-flex align-items-center mb-3">
          <div class="spinner-border spinner-border-sm text-primary me-2" role="status">
            <span class="visually-hidden">Processing...</span>
          </div>
          <strong class="text-primary">Processing "${fileName}"</strong>
        </div>
        <p class="mb-3">
          Great! Your file is being processed in the background. This usually takes just a few minutes, 
          and you're free to continue working.
        </p>
        <div class="alert alert-info border-0 bg-light mb-3">
          <div class="d-flex align-items-start">
            <i class="bi bi-info-circle text-info me-2 mt-1"></i>
            <div>
              <strong>What happens next?</strong>
              <ul class="mb-0 mt-1">
                <li>We'll validate and import your data</li>
                <li>You'll get notified of any issues</li>
                <li>Results will appear in your dashboard</li>
              </ul>
            </div>
          </div>
        </div>
        <p class="mb-0">
          <i class="bi bi-graph-up text-success me-1"></i>
          Track progress in your 
          <a href="/dashboard/import_audits" class="text-decoration-none fw-semibold">
            Import Dashboard <i class="bi bi-arrow-right"></i>
          </a>
        </p>
      `;
      }

      const statsCard = successModal.querySelector(".card");
      if (statsCard) {
        statsCard.style.display = "none";
      }

      if (typeof $ !== "undefined") {
        $(successModal).modal("show");
        $(successModal).one("hidden.bs.modal", () => {
          this.resetFileInput();
        });
      } else {
        successModal.classList.add("show");
        successModal.style.display = "block";
        document.body.classList.add("modal-open");

        let backdrop = document.querySelector(".modal-backdrop");
        if (!backdrop) {
          backdrop = document.createElement("div");
          backdrop.className = "modal-backdrop fade show";
          document.body.appendChild(backdrop);
        }

        const closeButtons = successModal.querySelectorAll(
          '[data-bs-dismiss="modal"], [data-dismiss="modal"]'
        );
        closeButtons.forEach((button) => {
          button.addEventListener(
            "click",
            () => {
              successModal.classList.remove("show");
              successModal.style.display = "none";
              document.body.classList.remove("modal-open");
              if (backdrop && backdrop.parentNode) {
                backdrop.parentNode.removeChild(backdrop);
              }
              this.resetFileInput();
            },
            { once: true }
          );
        });
      }
    } else {
      const toast = document.createElement("div");
      toast.className = "position-fixed top-0 end-0 m-3";
      toast.style.cssText = "z-index: 9999; min-width: 350px;";

      toast.innerHTML = `
      <div class="alert alert-success alert-dismissible fade show shadow-lg border-0">
        <div class="d-flex align-items-start">
          <i class="bi bi-check-circle-fill text-success me-2 mt-1"></i>
          <div class="flex-grow-1">
            <h6 class="alert-heading mb-1">Upload Successful!</h6>
            <p class="mb-2"><strong>"${fileName}"</strong> is being processed in the background.</p>
            <a href="/dashboard/import_audits" class="btn btn-sm btn-outline-success">
              <i class="bi bi-graph-up me-1"></i>View Progress
            </a>
          </div>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      </div>
    `;

      document.body.appendChild(toast);
      setTimeout(() => toast.remove(), 8000);
      this.resetFileInput();
    }
  }
  addUploadNotification(fileName) {
    const notificationsController = this.findNotificationsController();

    if (notificationsController) {
      notificationsController.addNotification({
        id: Date.now(),
        title: "Upload Received",
        message: `We've received your CSV file "${fileName}" and will process it shortly.`,
        timestamp: new Date(),
        read: false,
        type: "info",
      });
    }
  }

  findNotificationsController() {
    const notificationsElement = document.querySelector(
      '[data-controller~="notifications"]'
    );
    if (!notificationsElement) return null;

    const application = this.application;
    if (!application) return null;

    return application.getControllerForElementAndIdentifier(
      notificationsElement,
      "notifications"
    );
  }

  showSuccess() {
    this.showUploadSuccessMessage("your file");
  }
}
