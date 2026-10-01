# /etc/tower/settings.py - base settings shared by awx-web, awx-task and awx-init.
# Secrets come from the environment (docker/.env), so this file can live in git.

import os
import socket

from django_auth_ldap.config import *  # noqa: F401,F403  LDAP settings are set through the API

ADMINS = ()
STATIC_ROOT = '/var/lib/awx/public/static'
STATIC_URL = '/static/'
PROJECTS_ROOT = '/var/lib/awx/projects'
JOBOUTPUT_ROOT = '/var/lib/awx/job_status'

SECRET_KEY = os.environ['AWX_SECRET_KEY']
ALLOWED_HOSTS = ['*']
INTERNAL_API_URL = 'http://127.0.0.1:8052'

# Not on Kubernetes: jobs run on the task node through receptor + podman,
# the same way a VM install works.
IS_K8S = False
AWX_PROOT_ENABLED = False
CLUSTER_HOST_ID = socket.gethostname()

# Job containers share the task container's network. Simpler than
# rootless networking inside a container, and the task container is
# already the trust boundary.
DEFAULT_CONTAINER_RUN_OPTIONS = ['--network', 'host']

# Redis (cache, broker, channel layer) uses AWX's default unix socket
# /var/run/redis/redis.sock, shared with the redis container via a volume.

CSRF_COOKIE_SECURE = False      # set True once TLS is terminated in front of AWX
SESSION_COOKIE_SECURE = False
USE_X_FORWARDED_PORT = True
BROADCAST_WEBSOCKET_PORT = 8052
BROADCAST_WEBSOCKET_PROTOCOL = 'http'

# Mail used by email notification templates
EMAIL_HOST = os.environ.get('AWX_EMAIL_HOST', 'localhost')
EMAIL_PORT = int(os.environ.get('AWX_EMAIL_PORT', 25))
DEFAULT_FROM_EMAIL = os.environ.get('AWX_EMAIL_FROM', 'awx@localhost')
SERVER_EMAIL = DEFAULT_FROM_EMAIL
EMAIL_SUBJECT_PREFIX = '[AWX] '
