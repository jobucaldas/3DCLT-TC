# Tech Challenge - Fase 3

## Local Development

1. Clone the repos

```bash
# With SSH
git clone -b t2 git@github.com:jobucaldas/3DCLT-TC.git
git clone -b t2 git@github.com:jobucaldas/auth-service.git
git clone -b t2 git@github.com:jobucaldas/analytics-service.git
git clone -b t2 git@github.com:jobucaldas/evaluation-service.git
git clone -b t2 git@github.com:jobucaldas/flag-service.git
git clone -b t2 git@github.com:jobucaldas/targeting-service.git

# With HTTPS
git clone -b t2 https://github.com/jobucaldas/3DCLT-TC.git
git clone -b t2 https://github.com/jobucaldas/auth-service.git
git clone -b t2 https://github.com/jobucaldas/analytics-service.git
git clone -b t2 https://github.com/jobucaldas/evaluation-service.git
git clone -b t2 https://github.com/jobucaldas/flag-service.git
git clone -b t2 https://github.com/jobucaldas/targeting-service.git
```

2.

## Notes

- Removed ``github.com/jackc/pgx/v4/stdlib v4.18.3`` from ``go.mod`` on auth-service as it triggered an error when running ``go mod tidy``
- Added ``setuptools`` to python requirements as gunicorn fails with error ``ModuleNotFoundError`` because of it
- Removed package imports on go services to make build work
- Pinned Werkzeug and setuptools on python to avoid errors with gunicorn and flask
