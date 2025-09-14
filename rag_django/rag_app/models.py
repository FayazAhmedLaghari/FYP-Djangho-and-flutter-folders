from django.db import models
from django.contrib.auth.models import User
from django.core.validators import RegexValidator

class Student(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='student_profile')
    student_id = models.CharField(
        max_length=20, 
        unique=True,
        validators=[RegexValidator(
            regex=r'^[A-Z0-9]+$',
            message='Student ID must contain only uppercase letters and numbers'
        )]
    )
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(
        max_length=15,
        validators=[RegexValidator(
            regex=r'^\+?1?\d{9,15}$',
            message='Phone number must be entered in the format: "+999999999". Up to 15 digits allowed.'
        )]
    )
    date_of_birth = models.DateField()
    department = models.CharField(max_length=100)
    year_of_study = models.IntegerField(choices=[
        (1, 'First Year'),
        (2, 'Second Year'),
        (3, 'Third Year'),
        (4, 'Fourth Year'),
        (5, 'Fifth Year'),
    ])
    registration_date = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)
    
    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.student_id})"
    
    class Meta:
        ordering = ['-registration_date']

class Document(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    file = models.FileField(upload_to='documents/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
    processed = models.BooleanField(default=False)

class DocumentChunk(models.Model):
    document = models.ForeignKey(Document, on_delete=models.CASCADE)
    chunk_text = models.TextField()
    chunk_index = models.IntegerField()

class QueryHistory(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    question = models.TextField()
    answer = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)