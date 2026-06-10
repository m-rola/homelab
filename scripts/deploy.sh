#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$HOMELAB_DIR/logs/deploy.log"

mkdir -p "$HOMELAB_DIR/logs"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

trap 'log "DEPLOY FAILED"; "$SCRIPT_DIR/telegram.sh" "❌ Deploy FAILED on rpi — check $LOG_FILE" 2>/dev/null || true' ERR

cd "$HOMELAB_DIR"

log "Checking .env..."
if [[ ! -f "$HOMELAB_DIR/.env" ]]; then
  log "ERROR: Missing $HOMELAB_DIR/.env"
  exit 1
fi

log "Pulling latest changes..."
git pull --ff-only

log "Updating services..."
"$SCRIPT_DIR/update.sh"

log "Deploy completed."
echo ""
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
