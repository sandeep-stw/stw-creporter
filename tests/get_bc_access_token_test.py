#!/usr/bin/env python3
"""BCM-011 tests for Get-BCAccessToken.ps1 (no live Entra tenant required)."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import parse_qs

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts" / "Get-BCAccessToken.ps1"


def fail(message: str) -> None:
    raise AssertionError(message)


def run_pwsh(code: str, extra_env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    merged = os.environ.copy()
    for key in (
        "BC_TENANT_ID",
        "BC_CLIENT_ID",
        "BC_CLIENT_SECRET",
        "ENTRA_TENANT_ID",
        "AUTH_MICROSOFT_ENTRA_ID_ID",
        "AUTH_MICROSOFT_ENTRA_ID_SECRET",
        "BC_TOKEN_SCOPE",
    ):
        merged[key] = ""
    if extra_env:
        merged.update(extra_env)
    return subprocess.run(
        ["pwsh", "-NoProfile", "-Command", code],
        cwd=REPO,
        env=merged,
        text=True,
        capture_output=True,
        check=False,
    )


def test_script_exists() -> None:
    if not SCRIPT.is_file():
        fail("Missing scripts/Get-BCAccessToken.ps1")
    text = SCRIPT.read_text(encoding="utf-8")
    for needle in ("BC_TENANT_ID", "BC_CLIENT_ID", "BC_CLIENT_SECRET", "client_credentials", "oauth2/v2.0/token"):
        if needle not in text:
            fail(f"Script is missing {needle}")
    if "never-commit-this-secret" in text.lower():
        fail("Script must not contain a real secret")


def test_missing_env() -> None:
    code = f"""
$ErrorActionPreference = 'Stop'
. '{SCRIPT}'
try {{
    Get-BCAccessToken | Out-Null
    Write-Output 'UNEXPECTED_SUCCESS'
}} catch {{
    Write-Output $_.Exception.Message
}}
"""
    proc = run_pwsh(code)
    if proc.returncode != 0 and "UNEXPECTED" not in (proc.stdout + proc.stderr):
        # pwsh may fail if Get-BCAccessToken throws at parse; still inspect output
        pass
    combined = proc.stdout + proc.stderr
    if "UNEXPECTED_SUCCESS" in combined:
        fail("Get-BCAccessToken should fail without credentials")
    if "BC_TENANT_ID" not in combined or "BC_CLIENT_SECRET" not in combined:
        fail(f"Missing-variable error should name required vars. Output:\n{combined}")


def test_placeholder_guid() -> None:
    code = f"""
$ErrorActionPreference = 'Stop'
. '{SCRIPT}'
try {{
    Get-BCAccessToken -TenantId '00000000-0000-0000-0000-000000000000' -ClientId '11111111-1111-1111-1111-111111111111' -ClientSecret 'x' | Out-Null
    Write-Output 'UNEXPECTED_SUCCESS'
}} catch {{
    Write-Output $_.Exception.Message
}}
"""
    proc = run_pwsh(code)
    combined = proc.stdout + proc.stderr
    if "UNEXPECTED_SUCCESS" in combined:
        fail("Placeholder tenant id should be rejected")
    if "placeholder" not in combined.lower():
        fail(f"Expected placeholder error. Output:\n{combined}")


def test_error_redaction() -> None:
    code = f"""
$ErrorActionPreference = 'Stop'
. '{SCRIPT}'
$raw = 'error=invalid_client&client_secret=super-secret-value&error_description=bad'
Get-BCSafeAuthErrorMessage -Raw $raw
"""
    proc = run_pwsh(code)
    if proc.returncode != 0:
        fail(f"Redaction helper failed: {proc.stderr}")
    if "super-secret-value" in proc.stdout:
        fail("Client secret leaked in error message")
    if "client_secret=***" not in proc.stdout:
        fail(f"Expected redacted client_secret. Output:\n{proc.stdout}")


def test_token_from_mock_endpoint() -> None:
    captured: dict[str, str] = {}

    class Handler(BaseHTTPRequestHandler):
        def do_POST(self) -> None:  # noqa: N802
            length = int(self.headers.get("Content-Length", "0"))
            body = self.rfile.read(length).decode("utf-8")
            captured.update({k: v[0] for k, v in parse_qs(body).items()})
            payload = json.dumps(
                {
                    "access_token": "mock-bc-token",
                    "token_type": "Bearer",
                    "expires_in": 3600,
                }
            ).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        def log_message(self, format: str, *args: object) -> None:  # noqa: A003
            return

    server = HTTPServer(("127.0.0.1", 0), Handler)
    port = server.server_address[1]
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        with tempfile.NamedTemporaryFile("w", delete=False, encoding="utf-8") as handle:
            handle.write("BC_TENANT_ID=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa\n")
            handle.write("BC_CLIENT_ID=bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb\n")
            handle.write("BC_CLIENT_SECRET=unit-test-secret\n")
            env_path = handle.name
        code = f"""
$ErrorActionPreference = 'Stop'
. '{SCRIPT}'
$result = Get-BCAccessToken -EnvPath '{env_path}' -TokenEndpoint 'http://127.0.0.1:{port}/oauth2/v2.0/token'
Write-Output $result.AccessToken
Write-Output $result.TokenType
"""
        proc = run_pwsh(code)
        if proc.returncode != 0:
            fail(f"Mock token request failed: {proc.stdout}\n{proc.stderr}")
        if "mock-bc-token" not in proc.stdout:
            fail(f"Expected mock access token. Output:\n{proc.stdout}")
        if captured.get("grant_type") != "client_credentials":
            fail(f"Expected client_credentials grant, got {captured}")
        if captured.get("client_secret") != "unit-test-secret":
            fail("Mock endpoint did not receive client_secret from env file")
    finally:
        server.shutdown()
        Path(env_path).unlink(missing_ok=True)


def main() -> int:
    tests = [
        test_script_exists,
        test_missing_env,
        test_placeholder_guid,
        test_error_redaction,
        test_token_from_mock_endpoint,
    ]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print("BCM-011 Get-BCAccessToken tests passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
