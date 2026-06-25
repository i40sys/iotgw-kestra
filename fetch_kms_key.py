#!/usr/bin/env python3
"""Fetch a device's SSH private key from Cosmian KMS (KMIP 2.1 JSON-TTLV) and
materialize it as an OpenSSH keys/id_rsa (mode 600). Runs INSIDE the Kestra
runner pod (label app.kubernetes.io/managed-by=kestra) which the KMS
NetworkPolicy admits on :9998. Reuses the iotgw-ui backend KMS contract
(apps/backend/src/services/kms.ts getDeviceSshPublicKey): a KMIP `Get` with
KeyFormatType=PKCS8 returns hex-encoded PKCS8 DER in the `KeyMaterial` node.
Fails loudly (non-zero exit) rather than silently falling back to a stale key.
"""
import json, os, sys, urllib.request, urllib.error
from cryptography.hazmat.primitives import serialization

kms_url = os.environ.get("KMS_URL", "http://cosmian-kms.kms.svc.cluster.local:9998").rstrip("/")
key_id = os.environ.get("SSH_KEY_ID", "").strip()
token = os.environ.get("KMS_AUTH_TOKEN", "").strip()

if not key_id:
    sys.exit("fetch_kms_key: SSH_KEY_ID is empty - refusing to fetch (no static fallback)")

body = {"tag": "Get", "type": "Structure", "value": [
    {"tag": "UniqueIdentifier", "type": "TextString", "value": key_id},
    {"tag": "KeyFormatType", "type": "Enumeration", "value": "PKCS8"},
]}
headers = {"Content-Type": "application/json"}
if token:
    headers["Authorization"] = "Bearer " + token
req = urllib.request.Request(kms_url + "/kmip/2_1", data=json.dumps(body).encode(),
                             headers=headers, method="POST")
try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        payload = json.load(resp)
except urllib.error.HTTPError as e:
    sys.exit("fetch_kms_key: KMS HTTP %s for key %s: %s" % (e.code, key_id, e.read()[:200]))

def find(node, tag):
    if isinstance(node, dict):
        if node.get("tag") == tag:
            return node
        for v in node.values():
            r = find(v, tag)
            if r is not None:
                return r
    elif isinstance(node, list):
        for v in node:
            r = find(v, tag)
            if r is not None:
                return r
    return None

km = find(payload, "KeyMaterial")
if not km or "value" not in km:
    sys.exit("fetch_kms_key: KeyMaterial not found in KMS response for key %s" % key_id)

der = bytes.fromhex(km["value"])
key = serialization.load_der_private_key(der, password=None)
pem = key.private_bytes(encoding=serialization.Encoding.PEM,
                        format=serialization.PrivateFormat.OpenSSH,
                        encryption_algorithm=serialization.NoEncryption())
os.makedirs("keys", exist_ok=True)
fd = os.open("keys/id_rsa", os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, "wb") as f:
    f.write(pem)
os.chmod("keys/id_rsa", 0o600)
sys.stderr.write("fetch_kms_key: materialized keys/id_rsa from KMS key %s\n" % key_id)
