"""Integration smoke tests against a deployed environment.

Requires:
  API_BASE_URL   - e.g. https://xxxx.execute-api.us-east-1.amazonaws.com
  ADMIN_API_KEY  - value of the environment admin API key

Run:
  API_BASE_URL=... ADMIN_API_KEY=... make test-integration
"""

from __future__ import annotations

import os
import time
import uuid

import pytest
import urllib.error
import urllib.request
import json


pytestmark = pytest.mark.integration


def _require_env():
    base = os.environ.get("API_BASE_URL", "").rstrip("/")
    key = os.environ.get("ADMIN_API_KEY", "")
    if not base or not key:
        pytest.skip("API_BASE_URL and ADMIN_API_KEY are required for integration tests")
    return base, key


def _request(method: str, url: str, body: dict | None = None, headers: dict | None = None):
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            payload = resp.read().decode("utf-8")
            return resp.status, json.loads(payload) if payload else {}
    except urllib.error.HTTPError as exc:
        payload = exc.read().decode("utf-8")
        try:
            parsed = json.loads(payload) if payload else {}
        except json.JSONDecodeError:
            parsed = {"raw": payload}
        return exc.code, parsed


def test_missing_api_key_is_rejected():
    base, _ = _require_env()
    status, _ = _request(
        "POST",
        f"{base}/admin/events",
        body={"eventId": "x", "eventName": "x", "date": "2099-01-01"},
    )
    assert status in (401, 403)


def test_admin_create_register_lookup_cancel_flow():
    base, key = _require_env()
    suffix = uuid.uuid4().hex[:8]
    event_id = f"smoke-{suffix}"
    email = f"smoke-{suffix}@example.com"

    status, body = _request(
        "POST",
        f"{base}/admin/events",
        body={
            "eventId": event_id,
            "eventName": f"Smoke Event {suffix}",
            "date": "2099-12-31",
            "venue": "Integration Lab",
            "description": "Created by integration smoke test",
        },
        headers={"x-api-key": key},
    )
    assert status == 201, body

    # Small pause for eventual consistency on GSIs
    time.sleep(1)

    status, body = _request(
        "POST",
        f"{base}/register",
        body={"eventId": event_id, "email": email},
    )
    assert status == 201, body
    registration_id = body.get("registrationId")
    assert registration_id

    status, body = _request("GET", f"{base}/registrations/{email}")
    assert status == 200, body
    regs = body.get("registrations") or []
    assert any(r.get("RegistrationId") == registration_id for r in regs)

    status, body = _request("DELETE", f"{base}/registration/{registration_id}")
    assert status in (200, 204), body

    status, body = _request(
        "DELETE",
        f"{base}/admin/events/{event_id}",
        headers={"x-api-key": key},
    )
    assert status == 200, body
