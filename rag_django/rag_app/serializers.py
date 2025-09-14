from rest_framework import serializers
from .models import Document, QueryHistory, Student
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.core.exceptions import ValidationError

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']

class StudentRegistrationSerializer(serializers.ModelSerializer):
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True)
    
    class Meta:
        model = Student
        fields = [
            'username', 'password', 'password_confirm',
            'student_id', 'first_name', 'last_name', 'email',
            'phone_number', 'date_of_birth', 'department', 'year_of_study'
        ]
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError("Passwords don't match")
        return attrs
    
    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("Username already exists")
        return value
    
    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email already exists")
        return value
    
    def validate_student_id(self, value):
        if Student.objects.filter(student_id=value).exists():
            raise serializers.ValidationError("Student ID already exists")
        return value
    
    def create(self, validated_data):
        # Remove password_confirm from validated_data
        validated_data.pop('password_confirm')
        
        # Create User first
        user = User.objects.create_user(
            username=validated_data.pop('username'),
            password=validated_data.pop('password'),
            email=validated_data['email'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name']
        )
        
        # Create Student profile
        student = Student.objects.create(user=user, **validated_data)
        return student

class StudentSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    
    class Meta:
        model = Student
        fields = [
            'id', 'username', 'student_id', 'first_name', 'last_name',
            'email', 'phone_number', 'date_of_birth', 'department',
            'year_of_study', 'registration_date', 'is_active'
        ]
        read_only_fields = ['registration_date']

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