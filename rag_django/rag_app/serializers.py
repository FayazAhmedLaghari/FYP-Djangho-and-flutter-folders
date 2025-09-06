from rest_framework import serializers
from .models import Document, QueryHistory
from django.contrib.auth.models import User
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']

class DocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Document
        fields = ['id', 'file', 'uploaded_at', 'processed']
        read_only_fields = ['uploaded_at', 'processed']

class QueryHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = QueryHistory
        fields = ['id', 'question', 'answer', 'created_at']
        read_only_fields = ['created_at']