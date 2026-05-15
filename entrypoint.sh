#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Write multica auth config. The daemon's resolveAuth() always reads from
# ~/.multica/config.json (default profile = empty string), NOT from env vars.
# MULTICA_TOKEN is the K8s env var holding the PAT value.
# ---------------------------------------------------------------------------
mkdir -p "${HOME}/.multica"
printf '{"token":"%s"}\n' "${MULTICA_TOKEN}" \
  > "${HOME}/.multica/config.json"

# ---------------------------------------------------------------------------
# Use stable pod name as device name (MY_POD_NAME injected via downward API)
# ---------------------------------------------------------------------------
export MULTICA_DAEMON_DEVICE_NAME="${MY_POD_NAME:-multica-agent}"

# ---------------------------------------------------------------------------
# Verify claude is on PATH
# ---------------------------------------------------------------------------
if ! which claude > /dev/null 2>&1; then
  echo "ERROR: claude not found in PATH"
  exit 1
fi
echo "claude found: $(claude --version 2>/dev/null || echo 'version unknown')"

# ---------------------------------------------------------------------------
# Create workspaces root on PVC
# ---------------------------------------------------------------------------
mkdir -p "${MULTICA_WORKSPACES_ROOT:-/workspace/multica_workspaces}"

# ---------------------------------------------------------------------------
# Start daemon in foreground (required for container PID 1)
# ---------------------------------------------------------------------------
echo "Starting multica daemon (device: ${MULTICA_DAEMON_DEVICE_NAME})"
echo "  Server: ${MULTICA_SERVER_URL:-http://multica-backend:8080}"

exec multica daemon start --foreground
