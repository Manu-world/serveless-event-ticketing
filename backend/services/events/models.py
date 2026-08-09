"""Event domain helpers and payload validation."""

REQUIRED_CREATE_FIELDS = ("eventId", "eventName", "date")

FIELD_MAP = {
    "eventName": "EventName",
    "date": "Date",
    "venue": "Venue",
    "description": "Description",
    "status": "Status",
    "maxCapacity": "MaxCapacity",
}


def validate_create_payload(body: dict) -> tuple[bool, str | None]:
    missing = [field for field in REQUIRED_CREATE_FIELDS if not body.get(field)]
    if missing:
        return False, "eventId, eventName, and date are required"
    return True, None


def build_event_item(body: dict) -> dict:
    item = {
        "PK": f"EVENT#{body['eventId']}",
        "SK": "METADATA",
        "EventId": body["eventId"],
        "EventName": body["eventName"],
        "Date": body["date"],
        "Venue": body.get("venue", ""),
        "Description": body.get("description", ""),
        "Status": body.get("status", "Available"),
    }
    if body.get("maxCapacity") is not None:
        item["MaxCapacity"] = body["maxCapacity"]
    return item


def build_update_expression(body: dict) -> tuple[str | None, dict, dict, str | None]:
    updates = []
    expr_attr_values = {}
    expr_attr_names = {}

    for body_key, db_key in FIELD_MAP.items():
        if body_key in body:
            attr_name = f"#{db_key}"
            attr_val = f":{db_key}"
            updates.append(f"{attr_name} = {attr_val}")
            expr_attr_names[attr_name] = db_key
            expr_attr_values[attr_val] = body[body_key]

    if not updates:
        return None, {}, {}, "No valid fields provided for update"

    return "SET " + ", ".join(updates), expr_attr_names, expr_attr_values, None
