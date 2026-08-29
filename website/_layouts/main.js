(function () {
  "use strict";
  if (window.__theme_inited) return;
  window.__theme_inited = true;

  function getPreferredTheme() {
    try {
      var stored = localStorage.getItem("theme");
      if (stored) return stored;
    } catch (e) {}
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
  }

  function setTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    try {
      localStorage.setItem("theme", theme);
    } catch (e) {}
    var themeToggle = document.getElementById("theme-toggle");
    if (themeToggle) {
      var icon = themeToggle.querySelector(".theme-icon");
      if (icon) {
        icon.textContent = theme === "dark" ? "☀️" : "🌙";
      }
    }
  }

  var initial = document.documentElement.getAttribute("data-theme") || getPreferredTheme();
  setTheme(initial);

  document.addEventListener("click", function (e) {
    var btn = e.target.closest("#theme-toggle");
    if (!btn) return;
    var now = document.documentElement.getAttribute("data-theme") || "dark";
    var next = now === "dark" ? "light" : "dark";
    setTheme(next);
  });

  document.addEventListener("click", function (e) {
    var toggle = e.target.closest("#navToggle");
    if (!toggle) return;
    var menu = document.getElementById("navMenu");
    if (menu) {
      var expanded = toggle.getAttribute("aria-expanded") === "true";
      toggle.setAttribute("aria-expanded", String(!expanded));
      menu.classList.toggle("is-open");
    }
  });

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") {
      var menu = document.getElementById("navMenu");
      var toggle = document.getElementById("navToggle");
      if (menu && menu.classList.contains("is-open")) {
        menu.classList.remove("is-open");
        if (toggle) {
          toggle.setAttribute("aria-expanded", "false");
          toggle.focus();
        }
      }
    }
  });

  document.addEventListener("click", function (e) {
    var link = e.target.closest('a[href^="#"]');
    if (!link) return;
    var href = link.getAttribute("href");
    if (!href || href === "#") return;
    var target = document.querySelector(href);
    if (target) {
      e.preventDefault();
      target.scrollIntoView({ behavior: "smooth" });
      if (history.pushState) {
        history.pushState(null, null, href);
      }
      var menu = document.getElementById("navMenu");
      var toggle = document.getElementById("navToggle");
      if (menu && menu.classList.contains("is-open")) {
        menu.classList.remove("is-open");
        if (toggle) toggle.setAttribute("aria-expanded", "false");
      }
    }
  });
})();
