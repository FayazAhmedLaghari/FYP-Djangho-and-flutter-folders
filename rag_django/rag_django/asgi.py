import os
from django.core.asgi import get_asgi_application

# Make sure this line uses lowercase:
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'rag_django.settings')

application = get_asgi_application()