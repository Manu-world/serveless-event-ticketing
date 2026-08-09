const { showNotice, hideNotice, createTextElement, renderEvents, renderRegistrations, renderAdminEvents } =
  window.EventTicketingUI;
const {
  getEvents,
  registerForEvent,
  getRegistrations,
  cancelRegistration,
  createEvent,
  deleteEventById,
} = window.EventTicketingApi;

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
  adminCreateBtn: document.getElementById("adminCreateBtn"),
};

let currentApiKey = sessionStorage.getItem("adminApiKey");

function selectEvent(eventId, buttonEl) {
  els.eventId.value = eventId;
  document.querySelectorAll(".event-row").forEach((row) => row.classList.remove("is-selected"));
  if (buttonEl) buttonEl.classList.add("is-selected");
  els.email.focus();
  document.getElementById("register").scrollIntoView({ behavior: "smooth", block: "center" });
}

async function fetchEvents() {
  try {
    const data = await getEvents();
    const events = Array.isArray(data.events) ? data.events : [];
    renderEvents(els.eventsList, events, selectEvent);
    if (currentApiKey) renderAdminEvents(els.adminEventsList, events, deleteEvent);
  } catch (error) {
    console.error(error);
    els.eventsList.textContent = "";
    els.eventsList.appendChild(
      createTextElement("div", "Failed to load events. Check the API and try again.", "state fail")
    );
  }
}

async function deleteEvent(eventId) {
  if (!confirm(`Are you sure you want to delete event: ${eventId}?`)) return;

  try {
    const { response, data } = await deleteEventById(eventId, currentApiKey);
    if (!response.ok) {
      if (response.status === 409) {
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
    const data = await registerForEvent(eventId, email);
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
    const data = await getRegistrations(email);
    const registrations = Array.isArray(data.registrations) ? data.registrations : [];
    renderRegistrations(els.registrationsList, registrations, (ticketId) => {
      els.registrationId.value = ticketId;
      document.getElementById("cancel").scrollIntoView({ behavior: "smooth", block: "center" });
      els.registrationId.focus();
    });
    showNotice(
      els.lookupNotice,
      registrations.length
        ? `Found ${registrations.length} registration${registrations.length === 1 ? "" : "s"}.`
        : "No tickets for that email.",
      registrations.length ? "ok" : "err"
    );
  } catch (error) {
    els.registrationsList.textContent = "";
    els.registrationsList.appendChild(
      createTextElement("div", "Could not load registrations.", "state fail")
    );
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
    const data = await cancelRegistration(registrationId);
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

function showAdminPanel() {
  els.adminPanel.classList.remove("hidden");
  els.navAdminLink.textContent = "Admin Area";
  fetchEvents();
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
    const { response, data } = await createEvent(payload, currentApiKey);
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

fetchEvents();
