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

class Call(models.Model):
    CALL_TYPES = [('audio', 'Audio'), ('video', 'Video')]
    STATUS     = [
        ('calling',  'Calling'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
        ('ended',    'Ended'),
        ('missed',   'Missed'),
    ]

    caller     = models.ForeignKey(User, on_delete=models.CASCADE, related_name='outgoing_calls')
    receiver   = models.ForeignKey(User, on_delete=models.CASCADE, related_name='incoming_calls')
    call_type  = models.CharField(max_length=10, choices=CALL_TYPES, default='audio')
    status     = models.CharField(max_length=10, choices=STATUS, default='calling')
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at   = models.DateTimeField(null=True, blank=True)

    def duration(self):
        if self.ended_at and self.started_at:
            return (self.ended_at - self.started_at).seconds
        return 0

    def __str__(self):
        return f"{self.caller} → {self.receiver} ({self.call_type})"