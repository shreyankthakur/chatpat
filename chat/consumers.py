import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from .models import Message


class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id   = int(self.scope['url_route']['kwargs']['room_id'])
        self.room_group = f'chat_{self.room_id}'
        print(f'WS connect: room_id={self.room_id} user={self.scope.get("user")!r}')
        await self.channel_layer.group_add(self.room_group, self.channel_name)
        await self.accept()

    async def disconnect(self, code):
        await self.channel_layer.group_discard(self.room_group, self.channel_name)

    async def receive(self, text_data):
        data    = json.loads(text_data)
        content = (data.get('content') or '').strip()
        if not content:
            return

        user = self.scope.get('user')
        if not user or not getattr(user, 'is_authenticated', False):
            user_id = data.get('user_id')
            try:
                user_id = int(user_id)
            except (TypeError, ValueError):
                print('WS auth failed and invalid user_id payload')
                return
            msg = await self.save_message(user_id, content)
        else:
            msg = await self.save_message(user.id, content)

        await self.channel_layer.group_send(
            self.room_group,
            {
                'type': 'chat_message',
                'message': {
                    'id':        msg.id,
                    'content':   msg.content,
                    'sender_id': msg.sender_id,
                    'timestamp': str(msg.timestamp),
                    'is_read':   msg.is_read,
                },
            },
        )

    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event['message']))

    @database_sync_to_async
    def save_message(self, sender_id, content):
        return Message.objects.create(
            room_id=self.room_id,
            sender_id=sender_id,
            content=content,
        )


class CallConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user_id = self.scope['url_route']['kwargs']['user_id']
        self.room    = f'call_{self.user_id}'
        await self.channel_layer.group_add(self.room, self.channel_name)
        await self.accept()
        print(f'Call WS connect: user_id={self.user_id}')

    async def disconnect(self, code):
        await self.channel_layer.group_discard(self.room, self.channel_name)

    async def receive(self, text_data):
        data      = json.loads(text_data)
        msg_type  = data.get('type')
        target_id = str(data.get('target_id', ''))
        target_room = f'call_{target_id}'

        if msg_type == 'call_user':
            await self.channel_layer.group_send(target_room, {
                'type':        'call_received',
                'caller_id':   data['caller_id'],
                'caller_name': data['caller_name'],
                'call_type':   data.get('call_type', 'audio'),
                'room_id':     data['room_id'],
            })

        elif msg_type == 'call_accepted':
            await self.channel_layer.group_send(target_room, {
                'type':    'call_accepted',
                'room_id': data['room_id'],
            })

        elif msg_type == 'call_rejected':
            await self.channel_layer.group_send(target_room, {
                'type':    'call_rejected',
                'room_id': data['room_id'],
            })

        elif msg_type == 'call_ended':
            await self.channel_layer.group_send(target_room, {
                'type':    'call_ended',
                'room_id': data['room_id'],
            })

        elif msg_type == 'offer':
            await self.channel_layer.group_send(target_room, {
                'type':    'call_offer',
                'data':    data.get('data'),
                'room_id': data['room_id'],
            })

        elif msg_type == 'answer':
            await self.channel_layer.group_send(target_room, {
                'type':    'call_answer',
                'data':    data.get('data'),
                'room_id': data['room_id'],
            })

        elif msg_type == 'ice_candidate':
            await self.channel_layer.group_send(target_room, {
                'type':    'call_ice',
                'data':    data.get('data'),
                'room_id': data['room_id'],
            })

    async def call_received(self, event):
        await self.send(text_data=json.dumps(event))

    async def call_accepted(self, event):
        await self.send(text_data=json.dumps(event))

    async def call_rejected(self, event):
        await self.send(text_data=json.dumps(event))

    async def call_ended(self, event):
        await self.send(text_data=json.dumps(event))

    async def call_offer(self, event):
        await self.send(text_data=json.dumps(event))

    async def call_answer(self, event):
        await self.send(text_data=json.dumps(event))

    async def call_ice(self, event):
        await self.send(text_data=json.dumps(event))