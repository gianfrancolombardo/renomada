#!/usr/bin/env python3
"""
Patch only the two seed items (shorter title/description). Uses anon key + password grant.
Run: python scripts/patch_granollers_seed_items.py
"""

from __future__ import annotations

import json
import ssl
import sys
import urllib.error
import urllib.request

SUPABASE_URL = "https://izyqrmpoyxnjzoqlgjoa.supabase.co"
SUPABASE_ANON_KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6eXFybXBveXhuanpvcWxnam9hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NDI1MjksImV4cCI6MjA3NDMxODUyOX0.JnRB967BxmS6l4xx29zbZzCqjGeaBimt-bfaLqDQS3k"
)

PASSWORD = "123456.a"

# Created by create_two_users_granollers.py (run 1)
USERS_ITEMS = [
    {
        "email": "granollers_seed_1774465279_u1@seed.renomada",
        "item_id": "fbb5c6e9-9bd9-4b7d-970f-2a79f080cbfd",
    },
    {
        "email": "granollers_seed_1774465279_u2@seed.renomada",
        "item_id": "a446477b-c893-4f91-98b4-72b828da92b4",
    },
]

NEW_TITLE_1 = "Lámpara"
NEW_DESC_1 = "Lámpara de pie, Granollers."
NEW_TITLE_2 = "Mesa"
NEW_DESC_2 = "Mesa pequeña, Granollers."


def _utf8_stdio() -> None:
    if sys.platform == "win32":
        import codecs

        sys.stdout = codecs.getwriter("utf-8")(sys.stdout.buffer, "strict")
        sys.stderr = codecs.getwriter("utf-8")(sys.stderr.buffer, "strict")


def _json_request(method: str, url: str, *, bearer: str | None, body: dict | None = None) -> dict:
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json",
        "Authorization": f"Bearer {bearer or SUPABASE_ANON_KEY}",
    }
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, timeout=60, context=ctx) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {e.code} {url}: {err_body}") from e


def _token(email: str) -> str:
    base = SUPABASE_URL.rstrip("/")
    url = f"{base}/auth/v1/token?grant_type=password"
    res = _json_request("POST", url, bearer=None, body={"email": email, "password": PASSWORD})
    t = res.get("access_token")
    if not t:
        raise RuntimeError(f"No token for {email}: {res}")
    return str(t)


def _patch_item(token: str, item_id: str, title: str, description: str) -> None:
    base = SUPABASE_URL.rstrip("/")
    url = f"{base}/rest/v1/items?id=eq.{item_id}"
    body = {"title": title, "description": description}
    data = json.dumps(body).encode("utf-8")
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }
    req = urllib.request.Request(url, data=data, headers=headers, method="PATCH")
    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, timeout=60, context=ctx) as resp:
            if resp.status not in (200, 204):
                raise RuntimeError(f"PATCH status {resp.status}")
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"PATCH items HTTP {e.code}: {err_body}") from e


def main() -> None:
    _utf8_stdio()
    updates = [
        (USERS_ITEMS[0], NEW_TITLE_1, NEW_DESC_1),
        (USERS_ITEMS[1], NEW_TITLE_2, NEW_DESC_2),
    ]
    for row, title, desc in updates:
        email = row["email"]
        iid = row["item_id"]
        print(f"[*] {email} -> item {iid}")
        tok = _token(email)
        _patch_item(tok, iid, title, desc)
        print(f"    OK: title={title!r}")
    print("\n[OK] Items actualizados.")


if __name__ == "__main__":
    main()
