#!/bin/sh
# Starts one RapidPro process, chosen by PROCESS_TYPE: "web" (default) or "worker".
set -e

case "$PROCESS_TYPE" in
  web)
    # the web service is the only one that migrates, so the worker never races it on the schema
    python manage.py migrate --noinput
    exec gunicorn temba.wsgi:application \
      --bind "0.0.0.0:${PORT:-8000}" \
      --workers "${WEB_CONCURRENCY:-2}" \
      --timeout 120 \
      --access-logfile -
    ;;
  worker)
    # -B runs the Celery beat scheduler inside this process, so the worker service must stay at one replica
    exec celery -A temba.temba_celery worker -B \
      --loglevel "${CELERY_LOG_LEVEL:-info}" \
      --concurrency "${CELERY_CONCURRENCY:-4}"
    ;;
  *)
    echo "unknown PROCESS_TYPE '$PROCESS_TYPE' (expected web or worker)" >&2
    exit 1
    ;;
esac
