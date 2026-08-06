const API_BASE_URL = "https://sl9as1tfu9.execute-api.us-east-1.amazonaws.com";

const els = {
  registrationForm: document.getElementById("registrationForm"),
  submitBtn: document.getElementById("submitBtn"),
  eventId: document.getElementById("eventId"),
  email: document.getElementById("email"),
  registerNotice: document.getElementById("registerNotice"),
  eventsList: document.getElementById("eventsList"),
  lookupForm: document.getElementById("lookupForm"),
  lookupEmail: document.getElementById("lookupEmail"),
  lookupBtn: document.getElementById("lookupBtn"),
  lookupNotice: document.getElementById("lookupNotice"),
  registrationsList: document.getElementById("registrationsList"),
  cancelForm: document.getElementById("cancelForm"),
  registrationId: document.getElementById("registrationId"),
  cancelBtn: document.getElementById("cancelBtn"),
  cancelNotice: document.getElementById("cancelNotice"),
};

function showNotice(node, message, type) {
  node.textContent = message;
  node.className = `notice show ${type}`;
}

function hideNotice(node) {
  node.className = "notice";
  node.textContent = "";
}

function statusClass(status) {
  const value = String(status || "Available").toLowerCase();
  return value.includes("limit") ? "limited" : "available";
}

function eventIdFromItem(event) {
  return event.EventId || String(event.PK || "").replace(/^EVENT#/, "");
}

function selectEvent(eventId, buttonEl) {
  els.eventId.value = eventId;
  document.querySelectorAll(".event-row").forEach((row) => row.classList.remove("is-selected"));
  if (buttonEl) buttonEl.classList.add("is-selected");
  els.email.focus();
  document.getElementById("register").scrollIntoView({ behavior: "smooth", block: "center" });
}

function renderEvents(events) {
  els.eventsList.innerHTML = "";

  if (!events.length) {
    els.eventsList.innerHTML = `<div class="state">No published events yet. You can still register with a known event ID.</div>`;
    return;
  }

  events.forEach((event) => {
    const eventId = eventIdFromItem(event);
    const name = event.EventName || eventId || "Untitled event";
    const date = event.Date || "Date TBA";
    const venue = event.Venue ? ` · ${event.Venue}` : "";
    const status = event.Status || "Available";

    const button = document.createElement("button");
    button.type = "button";
    button.className = "row event-row";
    button.setAttribute("aria-label", `Select ${name}`);
    button.innerHTML = `
      <div>
        <strong>${name}</strong>
        <small>${eventId}</small>
      </div>
      <div class="meta">${date}${venue}</div>
      <span class="pill ${statusClass(status)}">${status}</span>
    `;
    button.addEventListener("click", () => selectEvent(eventId, button));
    els.eventsList.appendChild(button);
  });
}

function renderRegistrations(registrations) {
  els.registrationsList.innerHTML = "";

  if (!registrations.length) {
    els.registrationsList.innerHTML = `<div class="state">No registrations found for that email.</div>`;
    return;
  }

  registrations.forEach((item) => {
    const eventId = eventIdFromItem(item);
    const ticketId = item.RegistrationId || "—";
    const when = item.RegistrationDate
      ? new Date(item.RegistrationDate).toLocaleString()
      : "Date unknown";

    const row = document.createElement("div");
    row.className = "row static";
    row.innerHTML = `
      <div>
        <strong>${eventId}</strong>
        <small>${when}</small>
      </div>
      <div class="ticket-actions">
        <span class="ticket-id" title="${ticketId}">${ticketId}</span>
        <button type="button" class="btn btn-ghost" data-cancel="${ticketId}">Cancel</button>
      </div>
    `;

    row.querySelector("[data-cancel]").addEventListener("click", () => {
      els.registrationId.value = ticketId;
      document.getElementById("cancel").scrollIntoView({ behavior: "smooth", block: "center" });
      els.registrationId.focus();
    });

    els.registrationsList.appendChild(row);
  });
}

async function fetchEvents() {
  try {
    const response = await fetch(`${API_BASE_URL}/events`);
    if (!response.ok) throw new Error("Could not load events");
    const data = await response.json();
    renderEvents(Array.isArray(data.events) ? data.events : []);
  } catch (error) {
    console.error(error);
    els.eventsList.innerHTML = `<div class="state fail">Failed to load events. Check the API and try again.</div>`;
  }
}

els.registrationForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  hideNotice(els.registerNotice);

  const eventId = els.eventId.value.trim();
  const email = els.email.value.trim();

  if (!eventId || !email) {
    showNotice(els.registerNotice, "Event ID and email are required.", "err");
    return;
  }
  if (!email.includes("@")) {
    showNotice(els.registerNotice, "Enter a valid email address.", "err");
    return;
  }

  els.submitBtn.disabled = true;
  els.submitBtn.textContent = "Confirming…";

  try {
    const response = await fetch(`${API_BASE_URL}/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ eventId, email }),
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Registration failed");

    showNotice(
      els.registerNotice,
      `You're in. Ticket ID: ${data.registrationId}`,
      "ok"
    );
    els.lookupEmail.value = email;
    els.registrationId.value = data.registrationId || "";
    els.registrationForm.reset();
    document.querySelectorAll(".event-row").forEach((row) => row.classList.remove("is-selected"));
  } catch (error) {
    showNotice(els.registerNotice, error.message || "Something went wrong.", "err");
  } finally {
    els.submitBtn.disabled = false;
    els.submitBtn.textContent = "Confirm seat";
  }
});

els.lookupForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  hideNotice(els.lookupNotice);

  const email = els.lookupEmail.value.trim();
  if (!email || !email.includes("@")) {
    showNotice(els.lookupNotice, "Enter a valid email address.", "err");
    return;
  }

  els.lookupBtn.disabled = true;
  els.lookupBtn.textContent = "Searching…";
  els.registrationsList.innerHTML = `<div class="state">Looking up tickets…</div>`;

  try {
    const response = await fetch(
      `${API_BASE_URL}/registrations/${encodeURIComponent(email)}`
    );
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Lookup failed");

    const registrations = Array.isArray(data.registrations) ? data.registrations : [];
    renderRegistrations(registrations);
    showNotice(
      els.lookupNotice,
      registrations.length
        ? `Found ${registrations.length} registration${registrations.length === 1 ? "" : "s"}.`
        : "No tickets for that email.",
      registrations.length ? "ok" : "err"
    );
  } catch (error) {
    els.registrationsList.innerHTML = `<div class="state fail">Could not load registrations.</div>`;
    showNotice(els.lookupNotice, error.message || "Lookup failed.", "err");
  } finally {
    els.lookupBtn.disabled = false;
    els.lookupBtn.textContent = "Find tickets";
  }
});

els.cancelForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  hideNotice(els.cancelNotice);

  const registrationId = els.registrationId.value.trim();
  if (!registrationId) {
    showNotice(els.cancelNotice, "Registration ID is required.", "err");
    return;
  }

  els.cancelBtn.disabled = true;
  els.cancelBtn.textContent = "Cancelling…";

  try {
    const response = await fetch(
      `${API_BASE_URL}/registration/${encodeURIComponent(registrationId)}`,
      { method: "DELETE" }
    );
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Cancellation failed");

    showNotice(els.cancelNotice, data.message || "Registration cancelled.", "ok");
    els.cancelForm.reset();

    // Refresh lookup results if an email is already filled in
    if (els.lookupEmail.value.trim()) {
      els.lookupForm.requestSubmit();
    }
  } catch (error) {
    showNotice(els.cancelNotice, error.message || "Cancellation failed.", "err");
  } finally {
    els.cancelBtn.disabled = false;
    els.cancelBtn.textContent = "Cancel ticket";
  }
});

fetchEvents();
