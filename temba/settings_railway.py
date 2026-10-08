# Production settings for running RapidPro on Railway. Anything that differs per deployment is read from environment
# variables; everything else is inherited from settings_common so the upstream defaults stay in one place.
import os

import dj_database_url

from .settings_common import *  # noqa
from .settings_security import *  # noqa


def env_list(name):
    return [v.strip() for v in os.environ.get(name, "").split(",") if v.strip()]


DEBUG = False
SECRET_KEY = os.environ["SECRET_KEY"]

HOSTNAME = os.environ.get("HOSTNAME", "localhost")
ALLOWED_HOSTS = env_list("ALLOWED_HOSTS") or [HOSTNAME]
CSRF_TRUSTED_ORIGINS = [f"https://{host}" for host in ALLOWED_HOSTS if not host.startswith("*")]

# postgres://user:password@host:port/name, e.g. the Postgres service's private domain
_db = dj_database_url.parse(os.environ["DATABASE_URL"], conn_max_age=60)
for _alias in ("default", "readonly"):
    DATABASES[_alias].update(
        NAME=_db["NAME"], USER=_db["USER"], PASSWORD=_db["PASSWORD"], HOST=_db["HOST"], PORT=_db["PORT"]
    )

# the cache and the Celery broker share one Redis instance, as in settings_common
REDIS_URL = os.environ["REDIS_URL"]
CACHES["default"]["LOCATION"] = REDIS_URL
CELERY_BROKER_URL = REDIS_URL

ELASTICSEARCH_URL = os.environ["ELASTICSEARCH_URL"]

MAILROOM_URL = os.environ["MAILROOM_URL"]
MAILROOM_AUTH_TOKEN = os.environ["MAILROOM_AUTH_TOKEN"]

# uploads and exports are still written to this container's disk; object storage is a separate step
STORAGE_URL = os.environ.get("STORAGE_URL", f"https://{HOSTNAME}/media")

if os.environ.get("EMAIL_HOST"):
    EMAIL_HOST = os.environ["EMAIL_HOST"]
    EMAIL_HOST_USER = os.environ.get("EMAIL_HOST_USER", "")
    EMAIL_HOST_PASSWORD = os.environ.get("EMAIL_HOST_PASSWORD", "")
    DEFAULT_FROM_EMAIL = os.environ.get("DEFAULT_FROM_EMAIL", EMAIL_HOST_USER)
else:
    # no SMTP server configured yet, so log outgoing mail instead of failing against settings_common's placeholder
    EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# gunicorn serves the collected static files itself, WhiteNoise must sit directly after SecurityMiddleware
_security = MIDDLEWARE.index("django.middleware.security.SecurityMiddleware") + 1
MIDDLEWARE = MIDDLEWARE[:_security] + ("whitenoise.middleware.WhiteNoiseMiddleware",) + MIDDLEWARE[_security:]
