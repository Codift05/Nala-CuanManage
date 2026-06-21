#!/usr/bin/env bash
set -Eeuo pipefail

backend_port="${BACKEND_PORT:-3001}"
device="${1:-}"

if [[ -z "$device" ]]; then
  device="$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')"
fi

if [[ -z "$device" ]]; then
  echo "Tidak ada perangkat Android yang terhubung."
  exit 1
fi

echo "Menghubungkan ${device} ke backend host port ${backend_port}..."
adb -s "$device" reverse "tcp:${backend_port}" "tcp:${backend_port}"

exec flutter run \
  --device-id "$device" \
  --dart-define "API_BASE_URL=http://127.0.0.1:${backend_port}/api"
