import os
from django.core.wsgi import get_wsgi_application

# Make sure this line uses lowercase:
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'rag_django.settings')

application = get_wsgi_application()