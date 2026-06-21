from django.urls import path
from . import views
urlpatterns = [
    path('register/', views.RegisterView.as_view()),
    path('login/',    views.LoginView.as_view()),
    path('users/',    views.UserListView.as_view()),
]