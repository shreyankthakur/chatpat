from django.db import models
from accounts.models import User

class Room(models.Model):
    participants = models.ManyToManyField(User, related_name='rooms')
    created_at   = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Room {self.id}"

class Message(models.Model):
    room      = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='messages')
    sender    = models.ForeignKey(User, on_delete=models.CASCADE)
    content   = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read   = models.BooleanField(default=False)

    class Meta:
        ordering = ['timestamp']