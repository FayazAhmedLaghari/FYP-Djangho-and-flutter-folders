from django.urls import path
from . import views

urlpatterns = [
    # Document management
    path('documents/', views.upload_document, name='upload_document'),
    path('documents/list/', views.get_documents, name='get_documents'),
    path('documents/<int:document_id>/delete/', views.delete_document, name='delete_document'),
    
    # RAG functionality
    path('ask/', views.ask_question, name='ask_question'),
    path('history/', views.get_query_history, name='get_query_history'),
    
    # Student registration and management
    path('register/', views.student_register, name='student_register'),
    path('profile/', views.get_student_profile, name='get_student_profile'),
    path('profile/update/', views.update_student_profile, name='update_student_profile'),
    path('students/', views.list_students, name='list_students'),
]