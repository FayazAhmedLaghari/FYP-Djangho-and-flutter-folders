# MVVM Architecture Implementation

## Overview
This project now follows the MVVM (Model-View-ViewModel) architecture pattern for better code organization, maintainability, and separation of concerns.

## Project Structure

```
lib/
├── models/
│   └── subject_model.dart          # Data models for Subject, SubjectNote, SubjectMaterial
├── viewmodels/
│   └── dashboard_viewmodel.dart    # Business logic and state management
├── screens/
│   ├── subject_list_screen.dart    # Subject list view
│   ├── subject_detail_screen.dart  # Subject detail view with tabs
│   ├── upload_notes_tab.dart       # Upload notes functionality
│   ├── view_notes_tab.dart         # View notes and materials
│   ├── summary_flashcard_tab.dart  # AI summary and flashcard generation
│   ├── test_paper_tab.dart         # AI test paper generation
│   └── other_screens.dart          # Chat, Planner, Quiz, Groups screens
├── Dashboard.dart                  # Main dashboard with navigation
├── HomeScreen.dart                 # Chat with PDF functionality
└── main.dart                       # App entry point with providers
```

## Key Features

### 1. **Subject Management**
- Add, edit, and delete subjects
- Each subject can have multiple notes and materials
- Organized by subject with detailed management screens

### 2. **Note Management**
- Add text notes with different types (text, summary, formula, definition)
- Upload files (PDF, images, documents)
- View and manage all notes and materials

### 3. **AI-Powered Features**
- Generate summaries from uploaded materials
- Create flashcards for study
- Generate test papers with customizable settings

### 4. **Navigation**
- Dashboard with bottom navigation
- Drawer navigation with quick access
- Seamless integration between Dashboard and HomeScreen (Chat with PDF)

## MVVM Components

### Models (`models/`)
- **Subject**: Main subject entity with notes and materials
- **SubjectNote**: Text-based notes with different types
- **SubjectMaterial**: File-based materials (PDFs, images, etc.)

### ViewModels (`viewmodels/`)
- **DashboardViewModel**: Manages all subject-related state and business logic
- Uses ChangeNotifier for reactive UI updates
- Handles CRUD operations for subjects, notes, and materials

### Views (`screens/`)
- **SubjectListScreen**: Displays all subjects with add/delete functionality
- **SubjectDetailScreen**: Tabbed interface for subject management
- **UploadNotesTab**: File upload and text note creation
- **ViewNotesTab**: Display and manage notes/materials
- **SummaryFlashcardTab**: AI-powered content generation
- **TestPaperTab**: AI test paper generation with customization

## State Management

The app uses Provider pattern for state management:
- `DashboardViewModel` is provided at the app level
- Individual screens consume the viewmodel using `Consumer<DashboardViewModel>`
- State changes automatically trigger UI updates

## Navigation Flow

1. **Dashboard** (Main Entry Point)
   - Bottom navigation between different features
   - Drawer navigation for quick access
   - Link to HomeScreen (Chat with PDF)

2. **Subject Management**
   - Subject List → Subject Detail → Individual Tabs
   - Each tab provides specific functionality

3. **HomeScreen Integration**
   - Accessible from Dashboard via drawer or app bar
   - Maintains existing Chat with PDF functionality

## Key Benefits

1. **Separation of Concerns**: UI, business logic, and data are clearly separated
2. **Maintainability**: Easy to modify and extend individual components
3. **Testability**: ViewModels can be tested independently
4. **Reusability**: Components can be reused across different screens
5. **Scalability**: Easy to add new features following the same pattern

## Usage

1. **Adding Subjects**: Use the floating action button in Subject List
2. **Managing Notes**: Navigate to subject detail and use the Upload Notes tab
3. **Viewing Content**: Use the View Notes tab to see all uploaded content
4. **AI Features**: Use Summary/Flashcards and Test Paper tabs for AI-generated content
5. **Navigation**: Use drawer or bottom navigation to switch between features

## Future Enhancements

- File picker integration for actual file uploads
- Backend API integration for data persistence
- Real AI integration for summary and flashcard generation
- User authentication and data synchronization
- Study progress tracking and analytics

