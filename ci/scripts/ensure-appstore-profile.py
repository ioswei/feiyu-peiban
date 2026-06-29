#!/usr/bin/env python3
"""Ensure App Store distribution profile exists and install it for CI."""

from __future__ import annotations

import base64
import json
import os
import plistlib
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

try:
    import jwt
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "PyJWT", "cryptography"])
    import jwt


ROOT = Path(os.environ.get("GITHUB_WORKSPACE", Path(__file__).resolve().parents[2]))
CONFIG_DOC = ROOT / "docs" / "配置信息.md"
CONFIG_DIR = ROOT / "Config"
PROFILE_NAME = "feiyu_AppStore_CI"
BUNDLE_IDENTIFIER = "com.ivangaro.feiyuunte"


def read_config_value(pattern: str) -> str:
    lines = CONFIG_DOC.read_text(encoding="utf-8").splitlines()
    for index, line in enumerate(lines):
        if pattern in line and index + 1 < len(lines):
            return lines[index + 1].strip()
    return ""


def make_token(key_id: str, issuer_id: str, private_key: str) -> str:
    now = int(time.time())
    return jwt.encode(
        {"iss": issuer_id, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )


def api_request(token: str, method: str, path: str, body: dict | None = None, retries: int = 3) -> dict:
    payload = None if body is None else json.dumps(body).encode()
    last_error: Exception | None = None
    for attempt in range(retries):
        request = urllib.request.Request(
            f"https://api.appstoreconnect.apple.com{path}",
            data=payload,
            method=method,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(request, context=ssl.create_default_context(), timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            detail = error.read().decode()
            raise RuntimeError(f"App Store Connect API {method} {path} failed ({error.code}): {detail}") from error
        except Exception as error:  # noqa: BLE001
            last_error = error
            time.sleep(2 * (attempt + 1))
    raise RuntimeError(f"App Store Connect API {method} {path} failed after {retries} attempts") from last_error


def append_github_env(key: str, value: str) -> None:
    github_env = os.environ.get("GITHUB_ENV")
    if not github_env:
        return
    with open(github_env, "a", encoding="utf-8") as env_file:
        if any(ch.isspace() for ch in value):
            env_file.write(f"{key}<<EOF\n{value}\nEOF\n")
        else:
            env_file.write(f"{key}={value}\n")


def install_profile(content_b64: str) -> tuple[str, str]:
    profile_bytes = base64.b64decode(content_b64)
    temp_path = Path(os.environ.get("RUNNER_TEMP", "/tmp")) / "fetched.mobileprovision"
    temp_path.write_bytes(profile_bytes)
    plist_xml = subprocess.check_output(["security", "cms", "-D", "-i", str(temp_path)])
    profile_plist = plistlib.loads(plist_xml)
    profile_uuid = profile_plist["UUID"]
    profile_name = profile_plist["Name"]
    profile_dir = Path.home() / "Library/MobileDevice/Provisioning Profiles"
    profile_dir.mkdir(parents=True, exist_ok=True)
    profile_path = profile_dir / f"{profile_uuid}.mobileprovision"
    profile_path.write_bytes(profile_bytes)
    repo_profile = CONFIG_DIR / "AppStore.mobileprovision"
    repo_profile.write_bytes(profile_bytes)
    return profile_name, str(profile_path)


def main() -> None:
    issuer_id = read_config_value("Issuer ID")
    key_id = read_config_value("秘钥ID")
    p8_path = CONFIG_DIR / "Usr-P8" / f"AuthKey_{key_id}.p8"
    if not p8_path.is_file():
        raise SystemExit(f"Missing API key: {p8_path}")

    token = make_token(key_id, issuer_id, p8_path.read_text(encoding="utf-8"))

    bundle_response = api_request(
        token,
        "GET",
        f"/v1/bundleIds?filter[identifier]={BUNDLE_IDENTIFIER}&limit=1",
    )
    bundle_items = bundle_response.get("data", [])
    if not bundle_items:
        raise SystemExit(f"Bundle ID not found: {BUNDLE_IDENTIFIER}")
    bundle_id = bundle_items[0]["id"]

    profile_response = api_request(
        token,
        "GET",
        f"/v1/bundleIds/{bundle_id}/profiles?limit=20",
    )
    profiles = [
        profile
        for profile in profile_response.get("data", [])
        if profile.get("attributes", {}).get("name") == PROFILE_NAME
    ]

    if not profiles:
        cert_response = api_request(
            token,
            "GET",
            "/v1/certificates?filter[certificateType]=DISTRIBUTION&limit=20",
        )
        certs = cert_response.get("data", [])
        if not certs:
            raise SystemExit("No Apple Distribution certificate found in App Store Connect")
        cert_id = certs[0]["id"]
        create_response = api_request(
            token,
            "POST",
            "/v1/profiles",
            {
                "data": {
                    "type": "profiles",
                    "attributes": {
                        "name": PROFILE_NAME,
                        "profileType": "IOS_APP_STORE",
                    },
                    "relationships": {
                        "bundleId": {"data": {"type": "bundleIds", "id": bundle_id}},
                        "certificates": {"data": [{"type": "certificates", "id": cert_id}]},
                    },
                }
            },
        )
        profile = create_response["data"]
    else:
        profile_id = profiles[0]["id"]
        profile = api_request(token, "GET", f"/v1/profiles/{profile_id}")["data"]

    profile_name, profile_path = install_profile(profile["attributes"]["profileContent"])
    append_github_env("PROVISIONING_PROFILE_NAME", profile_name)
    append_github_env("IOS_RUNNER_PROFILE_NAME", profile_name)
    print(f"Installed provisioning profile: {profile_name}")
    print(f"Profile path: {profile_path}")


if __name__ == "__main__":
    main()
