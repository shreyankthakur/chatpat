import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from urllib.parse import parse_qs
import chat.routing
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from rest_framework.authtoken.models import Token


@database_sync_to_async
def _get_user_from_token(token_key: str):
    try:
        token_obj = Token.objects.select_related('user').get(key=token_key)
        return token_obj.user
    except Token.DoesNotExist:
        return AnonymousUser()


class TokenAuthMiddleware:
    def __init__(self, inner):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        qs = parse_qs(scope.get('query_string', b'').decode('utf-8'))
        token_key = None
        if 'token' in qs and qs['token']:
            token_key = qs['token'][0]

        user = AnonymousUser()
        if token_key:
            user = await _get_user_from_token(token_key)

        scope['user'] = user
        return await self.inner(scope, receive, send)


application = ProtocolTypeRouter({
    'http': get_asgi_application(),
    'websocket': TokenAuthMiddleware(
        URLRouter(chat.routing.websocket_urlpatterns)
    ),
})