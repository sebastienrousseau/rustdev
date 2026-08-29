(function () {
  "use strict";

  // --- Theme Toggle ---
  var themeToggle = document.getElementById("theme-toggle");
  var themeIcon = themeToggle ? themeToggle.querySelector(".theme-icon") : null;

  function updateThemeIcon(theme) {
    if (themeIcon) {
      themeIcon.textContent = theme === "dark" ? "☀️" : "🌙";
    }
  }

  var currentTheme = document.documentElement.getAttribute("data-theme") || "dark";
  updateThemeIcon(currentTheme);

  if (themeToggle) {
    themeToggle.addEventListener("click", function () {
      var current = document.documentElement.getAttribute("data-theme") || "dark";
      var next = current === "dark" ? "light" : "dark";
      document.documentElement.setAttribute("data-theme", next);
      updateThemeIcon(next);
      try {
        localStorage.setItem("theme", next);
      } catch (e) {}
    });
  }

  // --- Mobile Navigation Disclosure ---
  var navToggle = document.getElementById("navToggle");
  var navMenu = document.getElementById("navMenu");

  if (navToggle && navMenu) {
    navToggle.addEventListener("click", function () {
      var isExpanded = navToggle.getAttribute("aria-expanded") === "true";
      navToggle.setAttribute("aria-expanded", String(!isExpanded));
      navMenu.classList.toggle("is-open");
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && navMenu.classList.contains("is-open")) {
        navMenu.classList.remove("is-open");
        navToggle.setAttribute("aria-expanded", "false");
        navToggle.focus();
      }
    });
  }

  // --- Smooth Anchor Scrolling & Auto-Close Mobile Menu ---
  var anchorLinks = document.querySelectorAll('a[href^="#"]');
  anchorLinks.forEach(function (link) {
    link.addEventListener("click", function (e) {
      var href = this.getAttribute("href");
      if (!href || href === "#") return;
      var target = document.querySelector(href);
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: "smooth" });
        if (history.pushState) {
          history.pushState(null, null, href);
        }
        if (navMenu && navMenu.classList.contains("is-open")) {
          navMenu.classList.remove("is-open");
          if (navToggle) {
            navToggle.setAttribute("aria-expanded", "false");
          }
        }
      }
    });
  });

  // --- Active Nav Section Highlighting ---
  if ("IntersectionObserver" in window) {
    var sections = document.querySelectorAll("section[id]");
    var navLinks = document.querySelectorAll(".nav-link[href^='#']");
    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            var id = entry.target.getAttribute("id");
            navLinks.forEach(function (link) {
              if (link.getAttribute("href") === "#" + id) {
                link.classList.add("active");
                link.setAttribute("aria-current", "true");
              } else {
                link.classList.remove("active");
                link.removeAttribute("aria-current");
              }
            });
          }
        });
      },
      { threshold: 0.2, rootMargin: "-80px 0px -40% 0px" }
    );

    sections.forEach(function (sec) {
      observer.observe(sec);
    });
  }
})();
