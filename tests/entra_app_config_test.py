#!/usr/bin/env python3
"""Validate BCM-010 Entra app configuration without calling Azure."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

GUID = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
BC_APP_ID = "996def3d-b36c-4153-8607-a6fd3c01b89f"
GRAPH_APP_ID = "00000003-0000-0000-c000-000000000000"
REQUIRED_APP = {
    "API.ReadWrite.All": "a42b0b75-311e-488d-b67e-8fe84f924341",
    "Automation.ReadWrite.All": "d365bc00-a990-0000-00bc-160000000001",
}
REQUIRED_DELEGATED = {
    "Financials.ReadWrite.All": "2fb13c28-9d89-417f-9af2-ec3065bc16e6",
}
REQUIRED_GRAPH = {"openid", "profile", "email", "offline_access", "User.Read"}


def fail(message: str) -> None:
    raise AssertionError(message)


def require_permissions(entries: list[dict], required: dict[str, str], label: str) -> None:
    found = {item["value"]: item["id"] for item in entries}
    for name, perm_id in required.items():
        if name not in found:
            fail(f"Missing {label} permission: {name}")
        if found[name] != perm_id:
            fail(f"{label} {name} must use id {perm_id}")


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    config_path = repo / "config" / "entra-app.json"
    env_example = repo / ".env.example"
    docs = repo / "docs" / "entra-app.md"
    script = repo / "scripts" / "Register-EntraApp.ps1"

    for path in (config_path, env_example, docs, script):
        if not path.is_file():
            fail(f"Missing {path.relative_to(repo)}")

    raw = config_path.read_text(encoding="utf-8")
    if re.search(r'(?i)(client_secret|password)\s*[:=]\s*["\'][^"\']{8,}', raw):
        fail("config/entra-app.json must not contain a secret value")

    config = json.loads(raw)
    if config.get("signInAudience") != "AzureADMultipleOrgs":
        fail("SaaS sign-in audience must be AzureADMultipleOrgs")
    if config["businessCentralResource"]["resourceAppId"] != BC_APP_ID:
        fail("Unexpected Business Central resource app id")
    if config["microsoftGraph"]["resourceAppId"] != GRAPH_APP_ID:
        fail("Unexpected Microsoft Graph resource app id")

    for item in config["applicationPermissions"]:
        if item["type"] != "Role" or not GUID.match(item["id"]):
            fail(f"Invalid application permission: {item}")
    for item in config["delegatedPermissions"]:
        if item["type"] != "Scope" or not GUID.match(item["id"]):
            fail(f"Invalid delegated permission: {item}")

    require_permissions(config["applicationPermissions"], REQUIRED_APP, "application")
    require_permissions(config["delegatedPermissions"], REQUIRED_DELEGATED, "delegated")

    graph_values = {item["value"] for item in config["microsoftGraph"]["delegatedPermissions"]}
    missing_graph = REQUIRED_GRAPH - graph_values
    if missing_graph:
        fail(f"Missing Graph delegated permissions: {sorted(missing_graph)}")

    sets = config["businessCentralApplicationCard"]["recommendedPermissionSets"]
    if "SUPER" in sets:
        fail("Do not recommend SUPER")

    env_text = env_example.read_text(encoding="utf-8")
    for key in (
        "AUTH_MICROSOFT_ENTRA_ID_ID",
        "AUTH_MICROSOFT_ENTRA_ID_SECRET",
        "BC_CLIENT_ID",
        "BC_CLIENT_SECRET",
        "BC_TOKEN_SCOPE",
    ):
        if key not in env_text:
            fail(f".env.example is missing {key}")

    print("BCM-010 entra-app config tests passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
