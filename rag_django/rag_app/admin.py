from django.contrib import admin
from .models import Document, DocumentChunk, QueryHistory, Student

@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ['student_id', 'first_name', 'last_name', 'email', 'department', 'year_of_study', 'is_active', 'registration_date']
    list_filter = ['department', 'year_of_study', 'is_active', 'registration_date']
    search_fields = ['student_id', 'first_name', 'last_name', 'email']
    readonly_fields = ['registration_date']
    ordering = ['-registration_date']

@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'file', 'uploaded_at', 'processed']
    list_filter = ['processed', 'uploaded_at']
    search_fields = ['user__username', 'file']

@admin.register(DocumentChunk)
class DocumentChunkAdmin(admin.ModelAdmin):
    list_display = ['id', 'document', 'chunk_index']
    list_filter = ['document__user']
    search_fields = ['chunk_text']

@admin.register(QueryHistory)
class QueryHistoryAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'question', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__username', 'question']
    readonly_fields = ['created_at']
