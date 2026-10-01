# /etc/tower/conf.d/credentials.py
import os

DATABASES = {
    'default': {
        'ATOMIC_REQUESTS': True,
        'ENGINE': 'awx.main.db.profiled_pg',
        'NAME': os.environ['AWX_PG_DATABASE'],
        'USER': os.environ['AWX_PG_USER'],
        'PASSWORD': os.environ['AWX_PG_PASSWORD'],
        'HOST': os.environ.get('AWX_PG_HOST', 'postgres'),
        'PORT': os.environ.get('AWX_PG_PORT', '5432'),
        'OPTIONS': {'sslmode': 'prefer'},
    }
}

LISTENER_DATABASES = {
    'default': {
        'OPTIONS': {
            'keepalives': 1,
            'keepalives_idle': 5,
            'keepalives_interval': 5,
            'keepalives_count': 5,
        },
    }
}

BROADCAST_WEBSOCKET_SECRET = os.environ['AWX_BROADCAST_WEBSOCKET_SECRET']
