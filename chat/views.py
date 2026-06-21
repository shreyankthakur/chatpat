from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Room, Message
from .serializers import RoomSerializer, MessageSerializer
from accounts.models import User

class RoomListView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        rooms = request.user.rooms.all()
        return Response(RoomSerializer(rooms, many=True).data)

class GetOrCreateRoomView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        other = User.objects.get(id=request.data['user_id'])
        # find existing room with exactly these 2 participants
        common = request.user.rooms.filter(participants=other)
        if common.exists():
            room = common.first()
        else:
            room = Room.objects.create()
            room.participants.add(request.user, other)
        return Response(RoomSerializer(room).data)

class MessageListView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request, room_id):
        msgs = Message.objects.filter(room_id=room_id)
        # mark as read
        msgs.exclude(sender=request.user).update(is_read=True)
        return Response(MessageSerializer(msgs, many=True).data)
    

class SendMessageView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request, room_id):
        content = request.data.get('content', '')
        if not content:
            return Response({'error': 'Empty message'}, status=400)
        msg = Message.objects.create(
            room_id=room_id,
            sender=request.user,
            content=content
        )
        return Response(MessageSerializer(msg).data)