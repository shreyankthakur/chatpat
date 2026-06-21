from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    phone    = models.CharField(max_length=15, unique=True)
    avatar   = models.ImageField(upload_to='avatars/', null=True, blank=True)
    about    = models.CharField(max_length=139, default='Hey there!')
    is_online = models.BooleanField(default=False)
    last_seen = models.DateTimeField(null=True, blank=True)