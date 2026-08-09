function getApiBaseUrl() {
  const meta = document.querySelector('meta[name="api-base-url"]');
  const url = meta ? meta.getAttribute("content") : "";
  // Fallback for local testing if placeholder wasn't replaced
  return url.includes("__API_BASE_URL__") ? "http://localhost:3000" : url;
}

const API_BASE_URL = getApiBaseUrl();

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
  
  // Admin Elements
  navAdminLink: document.getElementById("navAdminLink"),
  adminPanel: document.getElementById("admin"),
  adminLoginModal: document.getElementById("adminLoginModal"),
  adminLoginForm: document.getElementById("adminLoginForm"),
  adminApiKey: document.getElementById("adminApiKey"),
  adminLoginNotice: document.getElementById("adminLoginNotice"),
  adminLoginCancel: document.getElementById("adminLoginCancel"),
  adminLogoutBtn: document.getElementById("adminLogoutBtn"),
  adminEventForm: document.getElementById("adminEventForm"),
  adminNotice: document.getElementById("adminNotice"),
  adminEventsList: document.getElementById("adminEventsList"),
  adminCreateBtn: document.getElementById("adminCreateBtn")
};

let currentApiKey = sessionStorage.getItem("adminApiKey");

// --- Fetch Wrapper with Retry ---
async function fetchWithRetry(url, options = {}, retries = 2) {
  const delay = (ms) => new Promise(res => setTimeout(res, ms));
  let lastError;

  for (let i = 0; i <= retries; i++) {
    try {
      const response = await fetch(url, options);
      return response;
    } catch (err) {
      lastError = err;
      if (i < retries) await delay(Math.pow(2, i) * 500); // 500ms, 1000ms...
    }
  }
  throw lastError;
}

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

function createTextElement(tag, text, className) {
  const el = document.createElement(tag);
  el.textContent = text;
  if (className) el.className = className;
  return el;
}

// --- DOM Rendering (XSS Safe) ---
function renderEvents(events) {
  els.eventsList.textContent = "";

  if (!events.length) {
    els.eventsList.appendChild(createTextElement("div", "No published events yet. You can still register with a known event ID.", "state"));
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
    
    const titleDiv = document.createElement("div");
    titleDiv.appendChild(createTextElement("strong", name));
    titleDiv.appendChild(createTextElement("small", eventId));
    button.appendChild(titleDiv);
    
    button.appendChild(createTextElement("div", `${date}${venue}`, "meta"));
    button.appendChild(createTextElement("span", status, `pill ${statusClass(status)}`));

    button.addEventListener("click", () => selectEvent(eventId, button));
    els.eventsList.appendChild(button);
  });
}

function renderRegistrations(registrations) {
  els.registrationsList.textContent = "";

  if (!registrations.length) {
    els.registrationsList.appendChild(createTextElement("div", "No registrations found for that email.", "state"));
    return;
  }

  registrations.forEach((item) => {
    const eventId = eventIdFromItem(item);
    const ticketId = item.RegistrationId || "—";
    const when = item.RegistrationDate ? new Date(item.RegistrationDate).toLocaleString() : "Date unknown";

    const row = document.createElement("div");
    row.className = "row static";
    
    const titleDiv = document.createElement("div");
    titleDiv.appendChild(createTextElement("strong", eventId));
    titleDiv.appendChild(createTextElement("small", when));
    row.appendChild(titleDiv);

    const actionsDiv = document.createElement("div");
    actionsDiv.className = "ticket-actions";
    
    const idSpan = createTextElement("span", ticketId, "ticket-id");
    idSpan.title = ticketId;
    actionsDiv.appendChild(idSpan);
    
    const cancelBtn = createTextElement("button", "Cancel", "btn btn-ghost");
    cancelBtn.type = "button";
    cancelBtn.addEventListener("click", () => {
      els.registrationId.value = ticketId;
      document.getElementById("cancel").scrollIntoView({ behavior: "smooth", block: "center" });
      els.registrationId.focus();
    });
    actionsDiv.appendChild(cancelBtn);
    
    row.appendChild(actionsDiv);
    els.registrationsList.appendChild(row);
  });
}

function renderAdminEvents(events) {
  els.adminEventsList.textContent = "";
  
  if (!events.length) {
    els.adminEventsList.appendChild(createTextElement("div", "No events found.", "state"));
    return;
  }
  
  events.forEach((event) => {
    const eventId = eventIdFromItem(event);
    const name = event.EventName || eventId;
    
    const row = document.createElement("div");
    row.className = "row static";
    
    const titleDiv = document.createElement("div");
    titleDiv.appendChild(createTextElement("strong", name));
    titleDiv.appendChild(createTextElement("small", eventId));
    row.appendChild(titleDiv);
    
    row.appendChild(createTextElement("span", event.Status || "Available", `pill ${statusClass(event.Status)}`));
    
    const actionsDiv = document.createElement("div");
    actionsDiv.className = "ticket-actions";
    
    const deleteBtn = createTextElement("button", "Delete", "btn btn-ghost");
    deleteBtn.style.color = "var(--wine)";
    deleteBtn.addEventListener("click", () => deleteEvent(eventId));
    actionsDiv.appendChild(deleteBtn);
    
    row.appendChild(actionsDiv);
    els.adminEventsList.appendChild(row);
  });
}

// --- API Calls ---
async function fetchEvents() {
  try {
    const response = await fetchWithRetry(`${API_BASE_URL}/events`);
    if (!response.ok) throw new Error("Could not load events");
    const data = await response.json();
    const events = Array.isArray(data.events) ? data.events : [];
    renderEvents(events);
    if(currentApiKey) renderAdminEvents(events);
  } catch (error) {
    console.error(error);
    els.eventsList.textContent = "";
    els.eventsList.appendChild(createTextElement("div", "Failed to load events. Check the API and try again.", "state fail"));
  }
}

async function deleteEvent(eventId) {
  if (!confirm(`Are you sure you want to delete event: ${eventId}?`)) return;
  
  try {
    const response = await fetchWithRetry(`${API_BASE_URL}/admin/events/${encodeURIComponent(eventId)}`, {
      method: "DELETE",
      headers: { "x-api-key": currentApiKey }
    });
    const data = await response.json();
    if (!response.ok) {
        if(response.status === 409) {
            alert(`Cannot delete event. It has ${data.activeRegistrations} active registrations.`);
        } else {
            throw new Error(data.error || "Failed to delete event");
        }
        return;
    }
    
    alert("Event deleted successfully.");
    fetchEvents();
  } catch (error) {
    alert(error.message);
  }
}

// --- Event Listeners ---
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
    const response = await fetchWithRetry(`${API_BASE_URL}/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ eventId, email }),
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Registration failed");

    showNotice(els.registerNotice, `You're in. Ticket ID: ${data.registrationId}`, "ok");
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
  
  els.registrationsList.textContent = "";
  els.registrationsList.appendChild(createTextElement("div", "Looking up tickets…", "state"));

  try {
    const response = await fetchWithRetry(`${API_BASE_URL}/registrations/${encodeURIComponent(email)}`);
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
    els.registrationsList.textContent = "";
    els.registrationsList.appendChild(createTextElement("div", "Could not load registrations.", "state fail"));
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
    const response = await fetchWithRetry(`${API_BASE_URL}/registration/${encodeURIComponent(registrationId)}`, { method: "DELETE" });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Cancellation failed");

    showNotice(els.cancelNotice, data.message || "Registration cancelled.", "ok");
    els.cancelForm.reset();

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

// --- Admin Logic ---
function showAdminPanel() {
  els.adminPanel.classList.remove("hidden");
  els.navAdminLink.textContent = "Admin Area";
  fetchEvents(); // Refresh to populate admin list
}

function hideAdminPanel() {
  els.adminPanel.classList.add("hidden");
  els.navAdminLink.textContent = "Admin";
  currentApiKey = null;
  sessionStorage.removeItem("adminApiKey");
}

if (currentApiKey) {
  showAdminPanel();
}

els.navAdminLink.addEventListener("click", (e) => {
  e.preventDefault();
  if (currentApiKey) {
    document.getElementById("admin").scrollIntoView({ behavior: "smooth", block: "start" });
  } else {
    els.adminLoginModal.showModal();
  }
});

els.adminLoginCancel.addEventListener("click", () => {
  els.adminLoginModal.close();
  hideNotice(els.adminLoginNotice);
});

els.adminLogoutBtn.addEventListener("click", () => {
  hideAdminPanel();
  document.getElementById("top").scrollIntoView({ behavior: "smooth" });
});

els.adminLoginForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  hideNotice(els.adminLoginNotice);
  
  const key = els.adminApiKey.value.trim();
  const btn = els.adminLoginForm.querySelector("button[type=submit]");
  btn.disabled = true;
  
  // Verify key by trying to hit an admin endpoint or we can trust it until it fails
  // Let's try fetching events with the key, we don't have a specific GET /admin/events right now, 
  // but we can trust the session storage and it will fail on mutating actions.
  // Wait, let's just save it. It will error when they try to create/delete.
  currentApiKey = key;
  sessionStorage.setItem("adminApiKey", currentApiKey);
  
  els.adminLoginForm.reset();
  els.adminLoginModal.close();
  btn.disabled = false;
  showAdminPanel();
  document.getElementById("admin").scrollIntoView({ behavior: "smooth", block: "start" });
});

els.adminEventForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  hideNotice(els.adminNotice);
  
  const formData = new FormData(els.adminEventForm);
  const payload = Object.fromEntries(formData.entries());
  
  els.adminCreateBtn.disabled = true;
  els.adminCreateBtn.textContent = "Publishing...";
  
  try {
    const response = await fetchWithRetry(`${API_BASE_URL}/admin/events`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": currentApiKey
      },
      body: JSON.stringify(payload)
    });
    
    const data = await response.json();
    if (response.status === 403 || response.status === 401) {
      hideAdminPanel();
      els.adminLoginModal.showModal();
      throw new Error("Unauthorized. Please login again.");
    }
    if (!response.ok) throw new Error(data.error || "Failed to create event");
    
    showNotice(els.adminNotice, "Event published successfully!", "ok");
    els.adminEventForm.reset();
    fetchEvents();
  } catch (err) {
    showNotice(els.adminNotice, err.message, "err");
  } finally {
    els.adminCreateBtn.disabled = false;
    els.adminCreateBtn.textContent = "Publish Event";
  }
});

// Initial load
fetchEvents();
