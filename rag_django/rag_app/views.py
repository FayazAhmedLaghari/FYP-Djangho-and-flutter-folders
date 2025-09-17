import os
from PyPDF2 import PdfReader
import PyPDF2
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication, SessionAuthentication
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from rest_framework_simplejwt.authentication import JWTAuthentication
from langchain_community.vectorstores import FAISS
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.chains.question_answering import load_qa_chain
from langchain.prompts import PromptTemplate
from django.conf import settings
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Document, DocumentChunk, QueryHistory, Student
from .serializers import DocumentSerializer, QueryHistorySerializer, StudentRegistrationSerializer, StudentSerializer
from django.db import DatabaseError
from django.core.exceptions import ObjectDoesNotExist
import requests
import tempfile
import traceback
# Check internet connection
def check_internet_connection():
    try:
        requests.get("https://www.google.com", timeout=5)
        return True
    except:
        return False

# --- Unicode sanitization helper ---
def _sanitize_text(value):
    """
    Remove surrogate code points and replace invalid sequences so the text
    is safe for UTF-8 encoding, DB storage, and JSON serialization.
    """
    if value is None:
        return ""
    if not isinstance(value, str):
        try:
            value = str(value)
        except Exception:
            return ""
    # Replace isolated surrogates and ensure valid UTF-8
    # Encode with surrogatepass then decode ignoring invalids to drop any leftovers
    try:
        safe = value.encode('utf-8', 'surrogatepass').decode('utf-8', 'ignore')
    except Exception:
        # Fallback path if above fails for some reason
        safe = value.encode('utf-8', 'ignore').decode('utf-8', 'ignore')
    # Also normalize whitespace a bit
    return safe.replace('\r\n', '\n').replace('\r', '\n')

# Extract text from PDF - FIXED to handle Django FileField

# If you want to process the file directly without saving to database first
# utils.py
import PyPDF2
import os

def get_pdf_text(file_path):
    """
    Extract text from a PDF file given its path
    """
    try:
        print(f"📄 Reading PDF from path: {file_path}")
        
        # Check if file exists
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"PDF file not found at path: {file_path}")
        
        text = ""
        with open(file_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            
            for page_num in range(len(pdf_reader.pages)):
                page = pdf_reader.pages[page_num]
                extracted = page.extract_text() or ""
                # Sanitize page text to avoid surrogate errors
                extracted = _sanitize_text(extracted)
                text += extracted
                
                # Add page separator for better readability
                if page_num < len(pdf_reader.pages) - 1:
                    text += "\n\n--- Page Break ---\n\n"
        
        text = _sanitize_text(text)
        print(f"✅ Successfully extracted {len(text)} characters from PDF")
        return text
        
    except FileNotFoundError as e:
        print(f"❌ File not found error: {e}")
        raise e
    except Exception as e:
        print(f"❌ Error reading PDF: {e}")
        raise Exception(f"Error reading PDF: {str(e)}")

# Then in your view:
# raw_text = get_pdf_text_from_file(file)  # Use this if you don't want to save first

# Split text into chunks
def get_text_chunks(text):
    text = _sanitize_text(text)
    if not text.strip():
        raise Exception("No text extracted from PDF.")
    
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=10000, 
        chunk_overlap=1000
    )
    chunks = text_splitter.split_text(text)
    # Sanitize each chunk defensively
    return [_sanitize_text(c) for c in chunks if isinstance(c, str)]

# Create vector store
def get_vector_store(text_chunks):
    if not text_chunks:
        raise Exception("No text chunks to process.")
    
    try:
        # Ensure all texts are sanitized to avoid any embedding/serialize issues
        safe_texts = [_sanitize_text(t) for t in text_chunks]
        embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2",
            model_kwargs={'device': 'cpu'}
        )
        
        vector_store = FAISS.from_texts(safe_texts, embedding=embeddings)
        # Create directory if it doesn't exist
        os.makedirs(os.path.join(settings.BASE_DIR, "faiss_index"), exist_ok=True)
        vector_store.save_local(os.path.join(settings.BASE_DIR, "faiss_index"))
        return True
    except Exception as e:
        raise Exception(f"Error creating vector store: {str(e)}")

# Get conversational chain
def get_conversational_chain():
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise Exception("Google API key not found.")    
    prompt_template = """
    Answer the question as detailed as possible from the provided context, make sure to provide all the details, if the answer is not in
    provided context just say, "answer is not available in the context", don't provide the wrong answer\n\n
    Context:\n {context}?\n
    Question: \n{question}\n

    Answer:
    """

    model = ChatGoogleGenerativeAI(
        model="gemini-1.5-flash",
        temperature=0.3,
        google_api_key=api_key
    )

    prompt = PromptTemplate(
        template=prompt_template, 
        input_variables=["context", "question"]
    )
    chain = load_qa_chain(model, chain_type="stuff", prompt=prompt)
    return chain

# Process user question
def process_user_question(user_question):
    try:
        embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2",
            model_kwargs={'device': 'cpu'}
        )
        
        faiss_index_path = os.path.join(settings.BASE_DIR, "faiss_index")
        if not os.path.exists(faiss_index_path):
            raise Exception("Please process PDF documents first before asking questions.")
            
        new_db = FAISS.load_local(
            faiss_index_path, 
            embeddings, 
            allow_dangerous_deserialization=True
        )
        
        docs = new_db.similarity_search(user_question)
        chain = get_conversational_chain()
        
        response = chain(
            {"input_documents": docs, "question": user_question},
            return_only_outputs=True
        )
        
        return response["output_text"]
    except Exception as e:
        raise Exception(f"Error processing your question: {str(e)}")
    # views.py

# views.py
@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def upload_document(request):
    try:
        if not check_internet_connection():
            return Response(
                {"error": "No internet connection detected."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if 'file' not in request.FILES:
            return Response(
                {"error": "No file provided."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        file = request.FILES['file']
        if not file.name.endswith('.pdf'):
            return Response(
                {"error": "Only PDF files are allowed."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check file size
        if file.size > 10 * 1024 * 1024:  # 10MB limit
            return Response(
                {"error": "File size too large. Maximum 10MB allowed."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        document = None
        try:
            # Save document first to get the file path
            document = Document(user=request.user, file=file)
            document.save()
            print(f"✅ Document saved: {document.file.name}")
            print(f"📁 File path: {document.file.path}")
            
            # Process document - pass the actual file path, not the file object
            print("📖 Extracting text from PDF...")
            
            # FIX: Use the saved file path instead of the file object
            raw_text = get_pdf_text(document.file.path)  # Pass the file path
            raw_text = _sanitize_text(raw_text)
            print(f"✅ Text extracted: {len(raw_text)} characters")
            
            print("✂️ Splitting text into chunks...")
            text_chunks = get_text_chunks(raw_text)
            print(f"✅ Created {len(text_chunks)} text chunks")
            
            # Save chunks to database
            print("💾 Saving chunks to database...")
            for i, chunk in enumerate(text_chunks):
                chunk = _sanitize_text(chunk)
                DocumentChunk.objects.create(
                    document=document,
                    chunk_text=chunk,
                    chunk_index=i
                )
            print("✅ Chunks saved to database")
            
            # Create vector store
            print("🔧 Creating vector store...")
            all_chunks = DocumentChunk.objects.filter(document__user=request.user)
            all_texts = [chunk.chunk_text for chunk in all_chunks]
            get_vector_store(all_texts)
            print("✅ Vector store created")
            
            document.processed = True
            document.save()
            print("✅ Document marked as processed")
            
            serializer = DocumentSerializer(document)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        except Exception as e:
            print(f"❌ ERROR in upload_document: {str(e)}")
            print("🔍 Full traceback:")
            import traceback
            traceback.print_exc()
            
            # Clean up the document if processing failed
            if document and document.pk:
                print("🧹 Cleaning up failed document...")
                document.delete()
            
            return Response(
                {"error": f"Failed to process PDF: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
    except Exception as e:
        print(f"❌ UNHANDLED EXCEPTION in upload_document: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response(
            {"error": "Internal server error"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
    #ask question
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def ask_question(request):
    if not check_internet_connection():
        return Response(
            {"error": "No internet connection detected."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    question = request.data.get('question', '')
    if not question:
        return Response(
            {"error": "No question provided."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Check if documents have been processed
    if not Document.objects.filter(user=request.user, processed=True).exists():
        return Response(
            {"error": "Please process PDF documents first before asking questions."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        answer = process_user_question(question)
        
        # Save query to history
        query_history = QueryHistory.objects.create(
            user=request.user,
            question=question,
            answer=answer
        )
        
        return Response({
            "question": question,
            "answer": answer
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        print(f"Error answering question: {str(e)}")
        print(traceback.format_exc())
        
        return Response(
            {"error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_documents(request):
    documents = Document.objects.filter(user=request.user)
    serializer = DocumentSerializer(documents, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_query_history(request):
    queries = QueryHistory.objects.filter(user=request.user).order_by('-created_at')
    serializer = QueryHistorySerializer(queries, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_document(request, document_id):
    try:
        document = Document.objects.get(id=document_id, user=request.user)
        document.delete()
        
        # Recreate vector store with remaining documents
        all_chunks = DocumentChunk.objects.filter(document__user=request.user)
        if all_chunks.exists():
            all_texts = [chunk.chunk_text for chunk in all_chunks]
            get_vector_store(all_texts)
        else:
            # Remove FAISS index if no documents left
            faiss_index_path = os.path.join(settings.BASE_DIR, "faiss_index")
            if os.path.exists(faiss_index_path):
                import shutil
                shutil.rmtree(faiss_index_path)
        
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    except Document.DoesNotExist:
        return Response(
            {"error": "Document not found."},
            status=status.HTTP_404_NOT_FOUND
        )

# Add debug endpoint
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def debug_status(request):
    """Debug endpoint to check system status"""
    status_info = {
        'has_google_api_key': os.getenv("GOOGLE_API_KEY") is not None,
        'faiss_index_exists': os.path.exists(os.path.join(settings.BASE_DIR, "faiss_index")),
        'processed_documents': Document.objects.filter(user=request.user, processed=True).count(),
        'total_documents': Document.objects.filter(user=request.user).count(),
        'document_chunks': DocumentChunk.objects.filter(document__user=request.user).count(),
    }
    return Response(status_info)

# Add test endpoint for PDF processing
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def test_pdf_processing(request):
    """Test endpoint to debug PDF processing"""
    try:
        # Test with sample text
        test_text = "This is a test document about artificial intelligence. AI is transforming various industries including healthcare, finance, and education. Machine learning algorithms can now recognize patterns and make predictions with remarkable accuracy."
        
        chunks = get_text_chunks(test_text)
        print(f"Test chunks created: {len(chunks)}")
        
        # Test vector store
        get_vector_store(chunks)
        print("Test vector store created")
        
        return Response({
            "success": True,
            "message": "PDF processing components working correctly",
            "chunks_count": len(chunks)
        })
        
    except Exception as e:
        error_trace = traceback.format_exc()
        print(f"PDF processing test failed: {error_trace}")
        
        return Response({
            "success": False,
            "error": str(e),
            "traceback": error_trace
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Student Registration Views
@api_view(['POST'])
@permission_classes([])  # No authentication required for registration
def student_register(request):
    """
    Register a new student
    """
    try:
        serializer = StudentRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            student = serializer.save()
            return Response({
                "message": "Student registered successfully",
                "student": StudentSerializer(student).data
            }, status=status.HTTP_201_CREATED)
        else:
            return Response({
                "error": "Registration failed",
                "details": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            "error": "Registration failed",
            "details": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_student_profile(request):
    """
    Get current student's profile
    """
    try:
        if hasattr(request.user, 'student_profile'):
            student = request.user.student_profile
            serializer = StudentSerializer(student)
            return Response(serializer.data, status=status.HTTP_200_OK)
        else:
            return Response({
                "error": "Student profile not found"
            }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            "error": "Failed to retrieve profile",
            "details": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_student_profile(request):
    """
    Update current student's profile
    """
    try:
        if hasattr(request.user, 'student_profile'):
            student = request.user.student_profile
            serializer = StudentSerializer(student, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response({
                    "message": "Profile updated successfully",
                    "student": serializer.data
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    "error": "Update failed",
                    "details": serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
        else:
            return Response({
                "error": "Student profile not found"
            }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            "error": "Failed to update profile",
            "details": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_students(request):
    """
    List all students (admin only - you might want to add admin permission check)
    """
    try:
        students = Student.objects.filter(is_active=True)
        serializer = StudentSerializer(students, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            "error": "Failed to retrieve students",
            "details": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)