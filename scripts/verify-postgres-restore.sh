#!/usr/bin/env bash
set -euo pipefail

backup="${1:-}"
if [[ -z "$backup" || ! -f "$backup" ]]; then
  echo "Usage: scripts/verify-postgres-restore.sh <backup.dump>" >&2
  exit 1
fi
if [[ -f "$backup.sha256" ]]; then
  (cd "$(dirname "$backup")" && sha256sum --check "$(basename "$backup").sha256")
fi

container="nala-restore-verify-$$"
trap 'docker rm -f "$container" >/dev/null 2>&1 || true' EXIT
docker run --rm -d --name "$container" \
  --tmpfs /var/lib/postgresql/data:rw,uid=70,gid=70,mode=0700 \
  -e POSTGRES_PASSWORD=restore-verification-only \
  postgres:15-alpine >/dev/null

for _ in {1..30}; do
  if docker exec "$container" pg_isready -U postgres >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
docker exec "$container" pg_isready -U postgres >/dev/null
docker exec "$container" createdb -U postgres nala_restore
docker cp "$backup" "$container:/tmp/nala.dump" >/dev/null
docker exec "$container" pg_restore --exit-on-error --no-owner --no-acl \
  -U postgres -d nala_restore /tmp/nala.dump

table_count="$(docker exec "$container" psql -U postgres -d nala_restore -Atc \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';")"
migration_count="$(docker exec "$container" psql -U postgres -d nala_restore -Atc \
  'SELECT COUNT(*) FROM "_prisma_migrations";')"
if (( table_count == 0 || migration_count == 0 )); then
  echo "Restore verification failed: empty schema or migration history" >&2
  exit 1
fi

echo "Restore verified: $table_count tables, $migration_count migrations"
