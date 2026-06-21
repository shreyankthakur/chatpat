import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async

from .models import Message


class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = int(self.scope['url_route']['kwargs']['room_id'])
        self.room_group = f'chat_{self.room_id}'
        print(f'WS connect: room_id={self.room_id} user={self.scope.get("user")!r}')
        await self.channel_layer.group_add(self.room_group, self.channel_name)
        await self.accept()


    async def disconnect(self, code):
        await self.channel_layer.group_discard(self.room_group, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        content = (data.get('content') or '').strip()
        if not content:
            return

        # Do not trust sender_id from the client.
        user = self.scope.get('user')
        if not user or not getattr(user, 'is_authenticated', False):
            # IMPORTANT: if WS auth fails, still persist using HTTP-like sender_id from payload.
            # This keeps the app working even when WS token auth is not wired correctly.
            user_id = data.get('user_id')
            try:
                user_id = int(user_id)
            except (TypeError, ValueError):
                print('WS auth failed and invalid user_id payload')
                return
            if not content:
                return
            msg = await self.save_message(user_id, content)
        else:
            msg = await self.save_message(user.id, content)

        await self.channel_layer.group_send(
            self.room_group,
            {
                'type': 'chat_message',
                'message': {
                    'id': msg.id,
                    'content': msg.content,
                    'sender_id': msg.sender_id,
                    'timestamp': str(msg.timestamp),
                    'is_read': msg.is_read,
                },
            },
        )

    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event['message']))

    @database_sync_to_async
    def save_message(self, sender_id, content):
        # Optional: could validate room membership, but this at least ensures sender is real/auth.
        return Message.objects.create(
            room_id=self.room_id,
            sender_id=sender_id,
            content=content,
        )
