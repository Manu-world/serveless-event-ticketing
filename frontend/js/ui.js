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

function createTextElement(tag, text, className) {
  const el = document.createElement(tag);
  el.textContent = text;
  if (className) el.className = className;
  return el;
}

function renderEvents(container, events, onSelect) {
  container.textContent = "";

  if (!events.length) {
    container.appendChild(
      createTextElement(
        "div",
        "No published events yet. You can still register with a known event ID.",
        "state"
      )
    );
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

    button.addEventListener("click", () => onSelect(eventId, button));
    container.appendChild(button);
  });
}

function renderRegistrations(container, registrations, onCancelClick) {
  container.textContent = "";

  if (!registrations.length) {
    container.appendChild(
      createTextElement("div", "No registrations found for that email.", "state")
    );
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
    cancelBtn.addEventListener("click", () => onCancelClick(ticketId));
    actionsDiv.appendChild(cancelBtn);

    row.appendChild(actionsDiv);
    container.appendChild(row);
  });
}

function renderAdminEvents(container, events, onDelete) {
  container.textContent = "";

  if (!events.length) {
    container.appendChild(createTextElement("div", "No events found.", "state"));
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

    row.appendChild(
      createTextElement("span", event.Status || "Available", `pill ${statusClass(event.Status)}`)
    );

    const actionsDiv = document.createElement("div");
    actionsDiv.className = "ticket-actions";

    const deleteBtn = createTextElement("button", "Delete", "btn btn-ghost");
    deleteBtn.style.color = "var(--wine)";
    deleteBtn.addEventListener("click", () => onDelete(eventId));
    actionsDiv.appendChild(deleteBtn);

    row.appendChild(actionsDiv);
    container.appendChild(row);
  });
}

window.EventTicketingUI = {
  showNotice,
  hideNotice,
  createTextElement,
  renderEvents,
  renderRegistrations,
  renderAdminEvents,
};
