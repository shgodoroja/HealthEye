(function () {
  const root = document.documentElement.dataset.siteRoot || "/";
  const page = document.body.dataset.page || "";
  const pageTitle = document.body.dataset.pageTitle || "HealthEye";
  const stickyLabel = document.body.dataset.stickyCtaLabel || "Download for Mac";
  const stickyHref = document.body.dataset.stickyCtaHref || `${root}download/`;

  const navItems = [
    { href: `${root}features/`, label: "Features", key: "features" },
    { href: `${root}for-coaches/`, label: "For Coaches", key: "for-coaches" },
    { href: `${root}sample-report/`, label: "Sample Report", key: "sample-report" },
    { href: `${root}pricing/`, label: "Pricing", key: "pricing" },
    { href: `${root}guides/apple-health-export-to-csv/`, label: "Guides", key: "guides" },
    { href: `${root}download/`, label: "Download", key: "download" }
  ];

  const headerSlot = document.querySelector("[data-site-header]");
  if (headerSlot) {
    const navLinks = navItems
      .map((item) => {
        const current = page === item.key ? ' aria-current="page"' : "";
        return `<a class="site-nav__link" href="${item.href}"${current}>${item.label}</a>`;
      })
      .join("");

    headerSlot.innerHTML = `
      <header class="site-header">
        <div class="site-header__inner">
          <a class="brand" href="${root}">
            <span class="brand__mark" aria-hidden="true"></span>
            <span class="brand__text">
              <span class="brand__name">HealthEye</span>
              <span class="brand__tag">Coach-first Mac app</span>
            </span>
          </a>
          <nav class="site-nav" aria-label="Primary">
            <button class="nav-toggle" type="button" aria-expanded="false" aria-label="Toggle navigation">
              <span class="nav-toggle__bars"></span>
            </button>
            <div class="site-nav__links">${navLinks}</div>
            <a class="btn btn--primary" href="${root}download/">Download for Mac</a>
          </nav>
        </div>
      </header>`;
  }

  const footerSlot = document.querySelector("[data-site-footer]");
  if (footerSlot) {
    footerSlot.innerHTML = `
      <footer class="site-footer">
        <div class="site-footer__inner">
          <div class="footer-grid">
            <div>
              <div class="brand" style="margin-bottom: .55rem;">
                <span class="brand__mark" aria-hidden="true"></span>
                <span class="brand__text">
                  <span class="brand__name">HealthEye</span>
                  <span class="brand__tag">Apple Health analysis for coaches</span>
                </span>
              </div>
              <p class="small-note">HealthEye helps coaches review Apple Health exports on Mac, understand trend changes, and generate weekly client reports. Privacy-first. Local analysis. Not a medical device.</p>
            </div>
            <div>
              <h4>Product</h4>
              <a href="${root}features/">Features</a>
              <a href="${root}for-coaches/">For Coaches</a>
              <a href="${root}sample-report/">Sample Report</a>
              <a href="${root}download/">Download</a>
            </div>
            <div>
              <h4>Guides</h4>
              <a href="${root}guides/apple-health-export-to-csv/">Export to CSV</a>
              <a href="${root}guides/apple-health-export-to-excel/">Export to Excel</a>
              <a href="${root}guides/analyze-apple-watch-health-data-on-mac/">Analyze on Mac</a>
              <a href="${root}privacy/">Privacy</a>
            </div>
            <div>
              <h4>Support</h4>
              <a href="${root}pricing/">Pricing</a>
              <a href="${root}download/">Install Guide</a>
              <a href="${root}privacy/">Data Controls</a>
              <a href="mailto:hello@healtheye.app">Contact</a>
            </div>
          </div>
          <div class="footer-note">
            <span>HealthEye provides wellness and coaching insights only and is not a medical device.</span>
            <span>&copy; <span data-year></span> HealthEye</span>
          </div>
        </div>
      </footer>`;
  }

  const stickySlot = document.querySelector("[data-sticky-cta-slot]");
  if (stickySlot) {
    stickySlot.innerHTML = `
      <div class="sticky-cta" aria-hidden="false">
        <div class="container">
          <a class="btn btn--primary" href="${stickyHref}">${stickyLabel}</a>
        </div>
      </div>`;
  }

  document.querySelectorAll("[data-year]").forEach((el) => {
    el.textContent = new Date().getFullYear();
  });

  const nav = document.querySelector(".site-nav");
  const toggle = nav?.querySelector(".nav-toggle");
  if (nav && toggle) {
    toggle.addEventListener("click", function () {
      const isOpen = nav.classList.toggle("is-open");
      toggle.setAttribute("aria-expanded", String(isOpen));
    });

    nav.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", () => {
        nav.classList.remove("is-open");
        toggle.setAttribute("aria-expanded", "false");
      });
    });
  }

  // Enhance FAQ details toggles with simple +/- indicator updates.
  document.querySelectorAll("details.faq__item").forEach((item) => {
    const sign = item.querySelector("[data-faq-sign]");
    if (!sign) return;
    const sync = () => {
      sign.textContent = item.open ? "−" : "+";
    };
    sync();
    item.addEventListener("toggle", sync);
  });

  // Highlight active guide nav state.
  if (page.startsWith("guides")) {
    document.querySelectorAll('.site-nav__link').forEach((a) => {
      if (a.textContent.trim() === "Guides") {
        a.setAttribute("aria-current", "page");
      }
    });
  }

  // Lightweight event hooks (analytics integration point).
  document.querySelectorAll("[data-track]").forEach((el) => {
    el.addEventListener("click", () => {
      const name = el.getAttribute("data-track");
      window.dispatchEvent(new CustomEvent("site-track", { detail: { name, page, pageTitle } }));
    });
  });
})();
