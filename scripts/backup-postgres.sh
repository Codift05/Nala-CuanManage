#!/usr/bin/env bash
set -euo pipefail

compose_file="${NALA_COMPOSE_FILE:-docker-compose.prod.yml}"
backup_dir="${NALA_BACKUP_DIR:-backups}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="$backup_dir/nala_$timestamp.dump"
temporary="$(mktemp "${TMPDIR:-/tmp}/nala-backup.XXXXXX")"
compose=(docker compose -f "$compose_file")
if [[ -n "${NALA_ENV_FILE:-}" ]]; then
  compose=(docker compose --env-file "$NALA_ENV_FILE" -f "$compose_file")
fi

trap 'rm -f "$temporary"' EXIT
mkdir -p "$backup_dir"

"${compose[@]}" exec -T db sh -eu -c \
  'pg_dump --format=custom --compress=6 --no-owner --no-acl -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  > "$temporary"
test -s "$temporary"
mv "$temporary" "$backup"
(cd "$backup_dir" && sha256sum "$(basename "$backup")" > "$(basename "$backup").sha256")
chmod 600 "$backup" "$backup.sha256"

echo "$backup"
