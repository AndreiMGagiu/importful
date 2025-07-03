import { Controller } from "@hotwired/stimulus";
import AOS from "aos";

export default class extends Controller {
  static targets = ["statValue"];

  connect() {
    console.log("Homepage controller connected");
    this.initializeAnimations();
    this.startCounterAnimations();
  }

  initializeAnimations() {
    // Initialize AOS (Animate On Scroll) if available
    if (typeof AOS !== "undefined") {
      AOS.init({
        duration: 800,
        easing: "ease-out-cubic",
        once: true,
        offset: 100,
      });
    }

    // Add intersection observer for counter animations
    this.observeCounters();
  }

  observeCounters() {
    const counters = document.querySelectorAll("[data-count]");

    if ("IntersectionObserver" in window) {
      const observer = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              this.animateCounter(entry.target);
              observer.unobserve(entry.target);
            }
          });
        },
        { threshold: 0.5 }
      );

      counters.forEach((counter) => observer.observe(counter));
    } else {
      // Fallback for browsers without IntersectionObserver
      counters.forEach((counter) => this.animateCounter(counter));
    }
  }

  animateCounter(element) {
    const target = Number.parseInt(element.dataset.count);
    const duration = 2000;
    const start = performance.now();
    const isRevenue = element.textContent.includes("$");

    const animate = (currentTime) => {
      const elapsed = currentTime - start;
      const progress = Math.min(elapsed / duration, 1);

      // Easing function for smooth animation
      const easeOutCubic = 1 - Math.pow(1 - progress, 3);
      const current = Math.floor(target * easeOutCubic);

      if (isRevenue) {
        element.textContent = `$${this.formatNumber(current)}`;
      } else {
        element.textContent = this.formatNumber(current);
      }

      if (progress < 1) {
        requestAnimationFrame(animate);
      } else {
        // Ensure final value is exact
        if (isRevenue) {
          element.textContent = `$${this.formatNumber(target)}`;
        } else {
          element.textContent = this.formatNumber(target);
        }
      }
    };

    requestAnimationFrame(animate);
  }

  formatNumber(num) {
    return new Intl.NumberFormat("en-US").format(num);
  }

  startCounterAnimations() {
    // Add staggered animations to feature cards
    const featureCards = document.querySelectorAll(".feature-card");
    featureCards.forEach((card, index) => {
      card.style.animationDelay = `${index * 0.1}s`;
    });

    // Add hover effects to CTA buttons
    this.addButtonEffects();
  }

  addButtonEffects() {
    const ctaButtons = document.querySelectorAll(
      ".cta-primary, .cta-secondary"
    );

    ctaButtons.forEach((button) => {
      button.addEventListener("mouseenter", (e) => {
        this.createRippleEffect(e);
      });
    });
  }

  createRippleEffect(e) {
    const button = e.currentTarget;
    const rect = button.getBoundingClientRect();
    const size = Math.max(rect.width, rect.height);
    const x = e.clientX - rect.left - size / 2;
    const y = e.clientY - rect.top - size / 2;

    const ripple = document.createElement("div");
    ripple.style.cssText = `
      position: absolute;
      width: ${size}px;
      height: ${size}px;
      left: ${x}px;
      top: ${y}px;
      background: rgba(255, 255, 255, 0.3);
      border-radius: 50%;
      transform: scale(0);
      animation: ripple 0.6s linear;
      pointer-events: none;
    `;

    button.style.position = "relative";
    button.style.overflow = "hidden";
    button.appendChild(ripple);

    setTimeout(() => {
      ripple.remove();
    }, 600);
  }

  // Smooth scroll for anchor links
  smoothScroll(event) {
    event.preventDefault();
    const targetId = event.currentTarget.getAttribute("href");
    const targetElement = document.querySelector(targetId);

    if (targetElement) {
      targetElement.scrollIntoView({
        behavior: "smooth",
        block: "start",
      });
    }
  }

  // Parallax effect for hero section
  handleScroll() {
    const scrolled = window.pageYOffset;
    const parallaxElements = document.querySelectorAll(
      ".hero-bg-animation, .hero-particles"
    );

    parallaxElements.forEach((element) => {
      const speed = element.dataset.speed || 0.5;
      element.style.transform = `translateY(${scrolled * speed}px)`;
    });
  }

  disconnect() {
    // Clean up event listeners
    window.removeEventListener("scroll", this.handleScroll);
  }
}
