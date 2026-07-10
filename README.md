# Tech Challenge - Fase 2

## Local Development

1. Clone the repos

```bash
# With SSH
git clone git@github.com:jobucaldas/3DCLT-TC.git
git clone git@github.com:jobucaldas/auth-service.git
git clone git@github.com:jobucaldas/analytics-service.git
git clone git@github.com:jobucaldas/evaluation-service.git
git clone git@github.com:jobucaldas/flag-service.git
git clone git@github.com:jobucaldas/targeting-service.git

# With HTTPS
git clone https://github.com/jobucaldas/3DCLT-TC.git
git clone https://github.com/jobucaldas/auth-service.git
git clone https://github.com/jobucaldas/analytics-service.git
git clone https://github.com/jobucaldas/evaluation-service.git
git clone https://github.com/jobucaldas/flag-service.git
git clone https://github.com/jobucaldas/targeting-service.git
```

2. Create a `.env` file in the root of each directory with the following content:

```bash
mv .env.example .env
```

3. Start the databases and services:

```bash
docker-compose up -d
```

4. Set up the services:

4.1. Create a new key for the evaluation service:

```bash
# Create key
curl -X POST http://localhost:8001/admin/keys \
-H "Content-Type: application/json" \
-H "Authorization: Bearer admin-secreto-123" \
-d '{"name": "evaluation-service-key"}'

# Validate the key
curl http://localhost:8001/validate \
-H "Authorization: Bearer tm_key_a1b2c3d4..."
```

4.2

## Testing

1. Run curl on the services to check health:

```bash
curl http://localhost:8001/health # Auth Service
curl http://localhost:8002/health # Flag Service
curl http://localhost:8003/health # Targeting Service
curl http://localhost:8004/health # Evaluation Service
curl http://localhost:8005/health # Analytics Service
```

2. Check your created auth key:

```bash
# Validate that incorrect keys are denied
curl http://localhost:8001/validate \
-H "Authorization: Bearer tm_wrongKey"
```

3. Create a new key to test the flag service:

```bash

curl -X POST http://localhost:8001/admin/keys \
-H "Content-Type: application/json" \
-H "Authorization: Bearer admin-secreto-123" \
-d '{"name": "admin-para-flag-service"}'
```

## Notes

- Removed ``github.com/jackc/pgx/v4/stdlib v4.18.3`` from ``go.mod`` on auth-service as it triggered an error when running ``go mod tidy``
- Added ``setuptools`` to python requirements as gunicorn fails with error ``ModuleNotFoundError`` because of it
- Removed package imports on go services to make build work
- Pinned Werkzeug and setuptools on python to avoid errors with gunicorn and flask
