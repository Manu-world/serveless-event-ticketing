(function () {
function getApiBaseUrl() {
  const meta = document.querySelector('meta[name="api-base-url"]');
  const url = meta ? meta.getAttribute("content") : "";
  return url.includes("__API_BASE_URL__") ? "http://localhost:3000" : url;
}

const API_BASE_URL = getApiBaseUrl();

async function fetchWithRetry(url, options = {}, retries = 2) {
  const delay = (ms) => new Promise((res) => setTimeout(res, ms));
  let lastError;

  for (let i = 0; i <= retries; i++) {
    try {
      return await fetch(url, options);
    } catch (err) {
      lastError = err;
      if (i < retries) await delay(Math.pow(2, i) * 500);
    }
  }
  throw lastError;
}

async function getEvents() {
  const response = await fetchWithRetry(`${API_BASE_URL}/events`);
  if (!response.ok) throw new Error("Could not load events");
  return response.json();
}

async function registerForEvent(eventId, email) {
  const response = await fetchWithRetry(`${API_BASE_URL}/register`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ eventId, email }),
  });
  const data = await response.json();
  if (!response.ok) throw new Error(data.error || "Registration failed");
  return data;
}

async function getRegistrations(email) {
  const response = await fetchWithRetry(
    `${API_BASE_URL}/registrations/${encodeURIComponent(email)}`
  );
  const data = await response.json();
  if (!response.ok) throw new Error(data.error || "Lookup failed");
  return data;
}

async function cancelRegistration(registrationId) {
  const response = await fetchWithRetry(
    `${API_BASE_URL}/registration/${encodeURIComponent(registrationId)}`,
    { method: "DELETE" }
  );
  const data = await response.json();
  if (!response.ok) throw new Error(data.error || "Cancellation failed");
  return data;
}

async function createEvent(payload, apiKey) {
  const response = await fetchWithRetry(`${API_BASE_URL}/admin/events`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
    },
    body: JSON.stringify(payload),
  });
  const data = await response.json();
  return { response, data };
}

/** Probe the authorizer without creating an event (empty body → 400 if authorized). */
async function verifyAdminApiKey(apiKey) {
  const response = await fetchWithRetry(`${API_BASE_URL}/admin/events`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
    },
    body: "{}",
  });
  if (response.status === 401 || response.status === 403) return false;
  // 400 = authorized but invalid payload; anything else non-auth is treated as ok.
  return true;
}

async function deleteEventById(eventId, apiKey) {
  const response = await fetchWithRetry(
    `${API_BASE_URL}/admin/events/${encodeURIComponent(eventId)}`,
    {
      method: "DELETE",
      headers: { "x-api-key": apiKey },
    }
  );
  const data = await response.json();
  return { response, data };
}

window.EventTicketingApi = {
  API_BASE_URL,
  getEvents,
  registerForEvent,
  getRegistrations,
  cancelRegistration,
  createEvent,
  deleteEventById,
  verifyAdminApiKey,
};
})();
