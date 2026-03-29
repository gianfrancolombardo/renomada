#!/usr/bin/env python3
"""
Create two Supabase users (email/password), set profile location to Granollers (ES),
and insert one item with a shared storage photo path per user.

Uses the same Supabase URL and anon key as the Flutter app (RLS: JWT of each user).
No third-party packages: stdlib only (avoids httpx/supabase version conflicts on Windows).
"""

from __future__ import annotations

import json
import ssl
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from uuid import uuid4

# Match lib/core/constants/supabase_constants.dart
SUPABASE_URL = "https://izyqrmpoyxnjzoqlgjoa.supabase.co"
SUPABASE_ANON_KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6eXFybXBveXhuanpvcWxnam9hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NDI1MjksImV4cCI6MjA3NDMxODUyOX0.JnRB967BxmS6l4xx29zbZzCqjGeaBimt-bfaLqDQS3k"
)

PASSWORD = "123456.a"

GRANOLLERS_LAT = 41.6079
GRANOLLERS_LON = 2.2878

PHOTO_PATH = (
    "item-photos/6e4b8abf-4fc0-49a4-ab0e-643cc0f764c6/"
    "359b4209-14f3-4a7d-b87c-8341f2a2e674_1760230616688_0.jpg"
)


def _utf8_stdio() -> None:
    if sys.platform == "win32":
        import codecs

        sys.stdout = codecs.getwriter("utf-8")(sys.stdout.buffer, "strict")
        sys.stderr = codecs.getwriter("utf-8")(sys.stderr.buffer, "strict")


def _json_request(
    method: str,
    url: str,
    *,
    bearer: str | None,
    body: dict | None = None,
) -> dict:
    data = None
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json",
    }
    if bearer:
        headers["Authorization"] = f"Bearer {bearer}"
    else:
        headers["Authorization"] = f"Bearer {SUPABASE_ANON_KEY}"

    if body is not None:
        data = json.dumps(body).encode("utf-8")

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, timeout=60, context=ctx) as resp:
            raw = resp.read().decode("utf-8")
            if not raw:
                return {}
            return json.loads(raw)
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {e.code} {url}: {err_body}") from e


def _get_access_token(email: str, password: str) -> tuple[str, str]:
    """Returns (access_token, user_id). Tries signup then password grant."""
    base = SUPABASE_URL.rstrip("/")
    signup_url = f"{base}/auth/v1/signup"
    try:
        res = _json_request("POST", signup_url, bearer=None, body={"email": email, "password": password})
        token = res.get("access_token")
        user = res.get("user") or {}
        uid = user.get("id")
        if token and uid:
            return str(token), str(uid)
    except RuntimeError as exc:
        print(f"  [i] signup: {exc}")

    token_url = f"{base}/auth/v1/token?grant_type=password"
    res = _json_request(
        "POST",
        token_url,
        bearer=None,
        body={"email": email, "password": password},
    )
    token = res.get("access_token")
    user = res.get("user") or {}
    uid = user.get("id")
    if not token or not uid:
        raise RuntimeError(f"No session after sign-in: {res}")
    return str(token), str(uid)


def _patch_profile(access_token: str, user_id: str) -> None:
    base = SUPABASE_URL.rstrip("/")
    now = datetime.now(timezone.utc).isoformat()
    location_string = f"SRID=4326;POINT({GRANOLLERS_LON} {GRANOLLERS_LAT})"
    url = f"{base}/rest/v1/profiles?user_id=eq.{user_id}"
    body = {
        "last_location": location_string,
        "last_seen_at": now,
        "is_location_opt_out": False,
    }
    data = json.dumps(body).encode("utf-8")
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }
    req = urllib.request.Request(url, data=data, headers=headers, method="PATCH")
    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, timeout=60, context=ctx) as resp:
            if resp.status not in (200, 204):
                raise RuntimeError(f"PATCH profiles unexpected status {resp.status}")
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"PATCH profiles HTTP {e.code}: {err_body}") from e


def _post_rest(access_token: str, table: str, row: dict) -> None:
    base = SUPABASE_URL.rstrip("/")
    url = f"{base}/rest/v1/{table}"
    data = json.dumps(row).encode("utf-8")
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, timeout=60, context=ctx) as resp:
            if resp.status not in (200, 201):
                raise RuntimeError(f"POST {table} unexpected status {resp.status}")
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"POST {table} HTTP {e.code}: {err_body}") from e


def _insert_item_and_photo(access_token: str, owner_id: str) -> tuple[str, str]:
    item_id = str(uuid4())
    photo_id = str(uuid4())
    now = datetime.now(timezone.utc).isoformat()
    item_data = {
        "id": item_id,
        "owner_id": owner_id,
        "title": "Test item — Granollers",
        "description": "Seed item for Granollers area (create_two_users_granollers.py).",
        "status": "available",
        "condition": "like_new",
        "exchange_type": "exchange",
        "created_at": now,
    }
    _post_rest(access_token, "items", item_data)
    photo_record = {
        "id": photo_id,
        "item_id": item_id,
        "path": PHOTO_PATH,
        "mime_type": "image/jpeg",
        "size_bytes": None,
        "created_at": now,
    }
    _post_rest(access_token, "item_photos", photo_record)
    return item_id, photo_id


def main() -> None:
    _utf8_stdio()
    created: list[dict] = []
    stamp = int(time.time())

    for idx in (1, 2):
        email = f"granollers_seed_{stamp}_u{idx}@seed.renomada"
        print(f"\n[*] User {idx}: {email}")

        access_token, user_id = _get_access_token(email, PASSWORD)
        time.sleep(1.2)

        _patch_profile(access_token, user_id)
        item_id, photo_id = _insert_item_and_photo(access_token, user_id)

        created.append(
            {
                "email": email,
                "password": PASSWORD,
                "user_id": user_id,
                "item_id": item_id,
                "item_photo_id": photo_id,
                "profile_location": {
                    "label": "Granollers, ES",
                    "latitude": GRANOLLERS_LAT,
                    "longitude": GRANOLLERS_LON,
                },
            }
        )

    print("\n" + "=" * 60)
    print(json.dumps(created, indent=2, ensure_ascii=False))
    print("=" * 60)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"\n[ERROR] {exc}", file=sys.stderr)
        raise
