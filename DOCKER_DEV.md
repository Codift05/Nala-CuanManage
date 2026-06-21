# NALA development

Docker is used only for PostgreSQL, Redis, and the Node backend. Flutter and
the Android emulator run natively on the developer machine for smaller
downloads, faster startup, and reliable hot reload.

## Start the backend stack

Docker Compose is the only prerequisite for the backend. Optionally copy
`.env.example` to `.env` to customize credentials or resource limits.

```bash
docker compose up --build
```

The backend health endpoint is <http://localhost:3001/health>. PostgreSQL and
Redis are available only on the private Compose network, not on host ports.

## Run Flutter natively

Connect an Android device over USB (or start an emulator), then run:

```bash
cd mobile
flutter pub get
./dev-run.sh
```

The script selects the first connected Android device, creates an ADB reverse
tunnel to backend port `3001`, and starts Flutter with the matching API URL.
Pass a device ID as the first argument when multiple devices are connected.

## Safe lifecycle

```bash
docker compose ps
docker compose logs -f backend
docker compose restart backend
docker compose down
```

`docker compose down` preserves database volumes. Only use
`docker compose down -v` when intentionally erasing all Docker-managed
development data. Logs are rotated, services have health checks and restart
policies, and resource limits can be adjusted in `.env`.
