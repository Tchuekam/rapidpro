# One image for both RapidPro processes on Railway: the web app and the Celery worker. docker-entrypoint.sh picks which
# one to run from PROCESS_TYPE.

# the frontend dependencies (node_modules) are needed by collectstatic, since STATICFILES_DIRS points into them
FROM node:20-bookworm-slim AS frontend
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --network-timeout 600000

FROM python:3.10-slim-bookworm
ARG POETRY_VERSION=2.5.1

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_NO_INTERACTION=1 \
    DJANGO_SETTINGS_MODULE=temba.settings_railway \
    PROCESS_TYPE=web

# libgdal for GeoDjango, libmagic for python-magic, libpq for psycopg, ffmpeg for temba/msgs/media.py
RUN apt-get update \
 && apt-get install -y --no-install-recommends libgdal-dev libmagic1 libpq5 ffmpeg \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "poetry==${POETRY_VERSION}"

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN poetry install --only main --no-root

COPY . .
COPY --from=frontend /app/node_modules ./node_modules

# collectstatic loads the settings but never connects to a service, so placeholder values are enough here
RUN SECRET_KEY=build-only \
    DATABASE_URL=postgres://build:build@localhost:5432/build \
    REDIS_URL=redis://localhost:6379/15 \
    ELASTICSEARCH_URL=http://localhost:9200 \
    MAILROOM_URL=http://localhost:8090 \
    MAILROOM_AUTH_TOKEN=build-only \
    python manage.py collectstatic --noinput

EXPOSE 8000
ENTRYPOINT ["sh", "/app/docker-entrypoint.sh"]
