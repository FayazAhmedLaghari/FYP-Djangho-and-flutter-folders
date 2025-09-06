from django.urls import path
from . import views
urlpatterns = [
    path('documents/', views.upload_document, name='upload_document'),
    path('documents/list/', views.get_documents, name='get_documents'),
    path('documents/<int:document_id>/delete/', views.delete_document, name='delete_document'),
    path('ask/', views.ask_question, name='ask_question'),
    path('history/', views.get_query_history, name='get_query_history'),
]