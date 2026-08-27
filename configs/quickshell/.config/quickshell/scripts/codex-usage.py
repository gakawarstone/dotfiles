#!/usr/bin/env python3
import json
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlencode
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann"
FETCH_ATTEMPTS = 3


def format_reset(seconds):
    if seconds is None:
        return "?"

    if seconds <= 0:
        return "now"

    minutes = seconds // 60
    if minutes < 60:
        return f"{minutes}m"

    hours = minutes // 60
    remaining_minutes = minutes % 60
    if hours < 48:
        if remaining_minutes:
            return f"{hours}h {remaining_minutes}m"
        return f"{hours}h"

    return f"{hours // 24}d"


def format_duration_clock(seconds):
    if seconds is None:
        return "?"
    if seconds <= 0:
        return "0:00"

    minutes = seconds // 60
    return f"{minutes // 60}:{minutes % 60:02d}"


def format_reset_at(seconds):
    if seconds is None:
        return "?"
    if seconds <= 0:
        return "now"

    reset_at = datetime.now() + timedelta(seconds=seconds)
    return f"{reset_at.day} {reset_at:%b %H:%M}"


def auth_path():
    return Path.home() / ".codex" / "auth.json"


def load_auth():
    auth = json.loads(auth_path().read_text())
    tokens = auth.get("tokens") or {}
    return auth, tokens.get("access_token"), tokens.get("account_id")


def save_refreshed_auth(auth, refreshed):
    tokens = auth.setdefault("tokens", {})
    tokens["access_token"] = refreshed["access_token"]
    tokens["refresh_token"] = refreshed.get("refresh_token", tokens.get("refresh_token"))
    tokens["id_token"] = refreshed.get("id_token", tokens.get("id_token"))
    auth["last_refresh"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    auth_path().write_text(json.dumps(auth, indent=2) + "\n")


def refresh_auth(auth):
    refresh_token = (auth.get("tokens") or {}).get("refresh_token")
    if not refresh_token:
        raise RuntimeError("missing Codex refresh token")

    body = urlencode({
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
        "client_id": CLIENT_ID,
    }).encode("utf-8")

    request = Request(
        "https://auth.openai.com/oauth/token",
        data=body,
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json",
            "User-Agent": "quickshell-codex-usage",
        },
    )
    with urlopen(request, timeout=10) as response:
        refreshed = json.loads(response.read().decode("utf-8"))

    if not refreshed.get("access_token"):
        raise RuntimeError("missing refreshed Codex access token")

    save_refreshed_auth(auth, refreshed)
    return refreshed["access_token"]


def is_expired_token_error(error):
    if error.code != 401:
        return False

    try:
        payload = json.loads(error.read().decode("utf-8"))
    except json.JSONDecodeError:
        return False

    return (payload.get("error") or {}).get("code") == "token_expired"


def fetch_usage_with_token(token, account_id):
    if not token or not account_id:
        raise RuntimeError("missing Codex auth")

    request = Request(
        "https://chatgpt.com/backend-api/codex/usage",
        headers={
            "Authorization": f"Bearer {token}",
            "ChatGPT-Account-Id": account_id,
            "Accept": "application/json",
            "User-Agent": "quickshell-codex-usage",
        },
    )
    with urlopen(request, timeout=10) as response:
        return json.loads(response.read().decode("utf-8"))


def fetch_usage():
    auth, token, account_id = load_auth()
    try:
        return fetch_usage_with_token(token, account_id)
    except HTTPError as error:
        if not is_expired_token_error(error):
            raise

    return fetch_usage_with_token(refresh_auth(auth), account_id)


last_error = None
for attempt in range(FETCH_ATTEMPTS):
    try:
        usage = fetch_usage()
        break
    except (OSError, HTTPError, URLError, RuntimeError, json.JSONDecodeError) as error:
        last_error = error
        if attempt + 1 < FETCH_ATTEMPTS:
            time.sleep(0.5 * (attempt + 1))
else:
    print(
        f"Codex usage unavailable: {type(last_error).__name__}: {last_error}",
        file=sys.stderr,
    )
    print(json.dumps({"ok": False, "text": "--", "color": "muted"}))
    raise SystemExit(0)

limits = usage.get("rate_limit") or {}
primary = limits.get("primary_window") or {}
secondary = limits.get("secondary_window") or {}
reserve_limit = next(
    (
        limit.get("rate_limit") or {}
        for limit in usage.get("additional_rate_limits") or []
        if limit.get("limit_name") == "gpt-reserve"
    ),
    None,
)
reserve = (reserve_limit or {}).get("primary_window") or {}
primary_used = round(primary.get("used_percent") or 0)
secondary_used = round(secondary.get("used_percent") or 0)
reserve_used = round(reserve.get("used_percent") or 0)
primary_remaining = max(0, 100 - primary_used)
secondary_remaining = max(0, 100 - secondary_used)
reserve_remaining = max(0, 100 - reserve_used)
reserve_available = reserve_limit is not None and bool(reserve)
reserve_allowed = reserve_available and bool(reserve_limit.get("allowed"))
lowest = min(primary_remaining, secondary_remaining)
standard_exhausted = bool(limits.get("limit_reached")) or lowest == 0
using_reserve = standard_exhausted and reserve_allowed and reserve_remaining > 0

if using_reserve:
    color = "luna"
elif lowest <= 30:
    color = "red"
elif lowest <= 50:
    color = "yellow"
else:
    color = "green"

print(json.dumps({
    "ok": True,
    "text": f"L{reserve_remaining}" if using_reserve else str(primary_remaining),
    "color": color,
    "primary": primary_remaining,
    "secondary": secondary_remaining,
    "primary_used": primary_used,
    "secondary_used": secondary_used,
    "primary_reset": format_duration_clock(primary.get('reset_after_seconds')),
    "secondary_reset": format_reset_at(secondary.get('reset_after_seconds')),
    "reserve_available": reserve_available,
    "reserve_allowed": reserve_allowed,
    "reserve_used": reserve_used,
    "reserve": reserve_remaining,
    "reserve_reset": format_reset_at(reserve.get('reset_after_seconds')),
    "reserve_limit_reached": bool((reserve_limit or {}).get("limit_reached")),
    "detail": f"5h resets {format_reset(primary.get('reset_after_seconds'))} | weekly resets {format_reset(secondary.get('reset_after_seconds'))}",
    "plan": usage.get("plan_type") or "",
}))
