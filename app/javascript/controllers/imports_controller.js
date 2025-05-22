import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="imports"
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
    return (
      Number.parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i]
    );
  }

  async submitForm(event) {
    event.preventDefault();
    console.log("Form submission started");

    if (this.fileInputTarget.files.length === 0) {
      this.showError("Please select a CSV file to upload.");
      return;
    }

    this.submitButtonTarget.disabled = true;
    this.hideError();

    this.uploadProgressTarget.classList.remove("d-none");
    this.processingStatusTarget.classList.add("d-none");
    this.updateProgress(0);

    try {
      const formData = new FormData(this.formTarget);

      console.log("Sending fetch request to:", this.formTarget.action);
      const response = await fetch(this.formTarget.action, {
        method: this.formTarget.method,
        headers: {
          Accept: "application/json",
        },
        body: formData,
      });

      console.log("Response received:", response.status, response.statusText);

      // For progress, lets fake a progress bar from 0 to 100 for better UX for now
      await this.fakeProgressBar();

      // Hide upload progress
      this.uploadProgressTarget.classList.add("d-none");

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        const errorMsg =
          errorData.errors?.join(", ") ||
          response.statusText ||
          "Unknown error";
        throw new Error(errorMsg);
      }

      // Try to parse the response as JSON
      let data;
      const contentType = response.headers.get("content-type");
      console.log("Response content type:", contentType);

      if (contentType && contentType.includes("application/json")) {
        const text = await response.text();
        console.log("Response text:", text);
        try {
          data = JSON.parse(text);
          console.log("Parsed JSON data:", data);
        } catch (e) {
          console.error("Error parsing JSON:", e);
          throw new Error("Invalid JSON response from server");
        }
      } else {
        console.log("Response is not JSON, using default values");
        // If not JSON, create a default success object
        data = { status: "ok", total: 1, created: 1, updated: 0, errors: [] };
      }

      // Show processing spinner
      this.processingStatusTarget.classList.remove("d-none");

      // Show processing spinner for 1 second
      await new Promise((resolve) => setTimeout(resolve, 1000));

      // Hide processing spinner
      this.processingStatusTarget.classList.add("d-none");

      if (data.errors && data.errors.length > 0) {
        this.showError(data.errors.join(", "));
      } else {
        // Show success and reset form
        this.showSuccess(data);
        this.resetFileInput();
      }
    } catch (error) {
      console.error("Error during import:", error);
      // Make sure to hide all progress indicators
      this.uploadProgressTarget.classList.add("d-none");
      this.processingStatusTarget.classList.add("d-none");
      this.showError(error.message || "An unexpected error occurred");
    } finally {
      this.submitButtonTarget.disabled = false;
      this.updateProgress(0);
    }
  }

  updateProgress(percent) {
    this.progressBarTarget.style.width = `${percent}%`;
    this.progressBarTarget.setAttribute("aria-valuenow", percent);
    this.progressPercentageTarget.textContent = `${percent}%`;
  }

  // Fake progress animation to 100% over 1.5s
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

  showSuccess(data) {
    try {
      console.log("Showing success modal with data:", data);

      const totalRecords = document.getElementById("total-records");
      const importedRecords = document.getElementById("imported-records");
      const duplicatesSkipped = document.getElementById("duplicates-skipped");

      if (totalRecords) totalRecords.textContent = data.total || "0";
      if (importedRecords) importedRecords.textContent = data.created || "0";

      // Calculate duplicates skipped
      const skipped = data.total
        ? data.total - (data.created || 0) - (data.updated || 0)
        : 0;
      if (duplicatesSkipped) duplicatesSkipped.textContent = skipped.toString();

      const modalEl = document.getElementById("successModal");
      if (modalEl) {
        console.log("Found modal element, showing it directly");

        document.body.classList.add("modal-open");

        document.body.style.paddingRight = "15px";
        document.body.style.overflow = "hidden";

        modalEl.style.display = "block";
        modalEl.classList.add("show");
        modalEl.setAttribute("aria-modal", "true");
        modalEl.removeAttribute("aria-hidden");

        let backdrop = document.querySelector(".modal-backdrop");
        if (!backdrop) {
          backdrop = document.createElement("div");
          backdrop.className = "modal-backdrop fade show";
          document.body.appendChild(backdrop);
        }

        const closeButtons = modalEl.querySelectorAll(
          "[data-bs-dismiss='modal']"
        );
        closeButtons.forEach((button) => {
          button.addEventListener("click", () => this.closeModal(modalEl));
        });

        modalEl.addEventListener("click", (event) => {
          if (event.target === modalEl) {
            this.closeModal(modalEl);
          }
        });
      } else {
        console.error("Success modal element not found");
        alert(
          "Import successful! " + (data.total || "0") + " records processed."
        );
      }
    } catch (error) {
      console.error("Error showing success modal:", error);
      alert(
        "Import successful! " + (data.total || "0") + " records processed."
      );
    }
  }

  closeModal(modalEl) {
    document.body.classList.remove("modal-open");

    document.body.style.paddingRight = "";
    document.body.style.overflow = "";

    modalEl.style.display = "none";
    modalEl.classList.remove("show");
    modalEl.setAttribute("aria-hidden", "true");
    modalEl.removeAttribute("aria-modal");

    const backdrop = document.querySelector(".modal-backdrop");
    if (backdrop) {
      backdrop.parentNode.removeChild(backdrop);
    }

    this.submitButtonTarget.disabled = true;

    this.resetFileInput();
  }
}
