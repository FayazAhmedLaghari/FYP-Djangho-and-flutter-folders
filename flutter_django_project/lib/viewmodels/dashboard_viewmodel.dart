import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/subject_model.dart';
class DashboardViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  List<Subject> _subjects = [];
  bool _isLoading = false;
  String? _error;
  static const String _subjectsKey = 'saved_subjects';

  // Getters
  int get selectedIndex => _selectedIndex;
  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Navigation
  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // Subject Management
  void addSubject(String name, {String description = ''}) {
    final newSubject = Subject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
    
    _subjects.add(newSubject);
    _saveSubjects();
    notifyListeners();
  }

  void removeSubject(String subjectId) {
    _subjects.removeWhere((subject) => subject.id == subjectId);
    _saveSubjects();
    notifyListeners();
  }

  void updateSubject(String subjectId, String name, {String? description}) {
    final index = _subjects.indexWhere((subject) => subject.id == subjectId);
    if (index != -1) {
      _subjects[index] = _subjects[index].copyWith(
        name: name,
        description: description,
      );
      _saveSubjects();
      notifyListeners();
    }
  }

  Subject? getSubjectById(String subjectId) {
    try {
      return _subjects.firstWhere((subject) => subject.id == subjectId);
    } catch (e) {
      return null;
    }
  }

  // Note Management
  void addNoteToSubject(String subjectId, SubjectNote note) {
    final subject = getSubjectById(subjectId);
    if (subject != null) {
      final updatedNotes = List<SubjectNote>.from(subject.notes)..add(note);
      final updatedSubject = subject.copyWith(notes: updatedNotes);
      final index = _subjects.indexWhere((s) => s.id == subjectId);
      if (index != -1) {
        _subjects[index] = updatedSubject;
        notifyListeners();
      }
    }
  }

  void removeNoteFromSubject(String subjectId, String noteId) {
    final subject = getSubjectById(subjectId);
    if (subject != null) {
      final updatedNotes = subject.notes.where((note) => note.id != noteId).toList();
      final updatedSubject = subject.copyWith(notes: updatedNotes);
      final index = _subjects.indexWhere((s) => s.id == subjectId);
      if (index != -1) {
        _subjects[index] = updatedSubject;
        notifyListeners();
      }
    }
  }

  // Material Management
  void addMaterialToSubject(String subjectId, SubjectMaterial material) {
    final subject = getSubjectById(subjectId);
    if (subject != null) {
      final updatedMaterials = List<SubjectMaterial>.from(subject.materials)..add(material);
      final updatedSubject = subject.copyWith(materials: updatedMaterials);
      final index = _subjects.indexWhere((s) => s.id == subjectId);
      if (index != -1) {
        _subjects[index] = updatedSubject;
        notifyListeners();
      }
    }
  }

  void removeMaterialFromSubject(String subjectId, String materialId) {
    final subject = getSubjectById(subjectId);
    if (subject != null) {
      final updatedMaterials = subject.materials.where((material) => material.id != materialId).toList();
      final updatedSubject = subject.copyWith(materials: updatedMaterials);
      final index = _subjects.indexWhere((s) => s.id == subjectId);
      if (index != -1) {
        _subjects[index] = updatedSubject;
        notifyListeners();
      }
    }
  }

  // Loading and Error States
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Persistence methods
  Future<void> _saveSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subjectsJson = _subjects.map((subject) => subject.toJson()).toList();
      await prefs.setString(_subjectsKey, jsonEncode(subjectsJson));
    } catch (e) {
      print('Error saving subjects: $e');
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subjectsJson = prefs.getString(_subjectsKey);
      if (subjectsJson != null) {
        final List<dynamic> subjectsList = jsonDecode(subjectsJson);
        _subjects = subjectsList.map((json) => Subject.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading subjects: $e');
    }
  }

  // Load subjects on initialization
  Future<void> initialize() async {
    setLoading(true);
    await _loadSubjects();
    setLoading(false);
  }

  // Sample data for testing (only if no subjects exist)
  void loadSampleData() {
    if (_subjects.isEmpty) {
      _subjects = [
        Subject(
          id: '1',
          name: 'Mathematics',
          description: 'Advanced calculus and algebra',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          notes: [
            SubjectNote(
              id: '1',
              title: 'Calculus Notes',
              content: 'Basic concepts of derivatives and integrals',
              type: 'text',
              createdAt: DateTime.now().subtract(const Duration(days: 3)),
            ),
          ],
          materials: [
            SubjectMaterial(
              id: '1',
              title: 'Calculus Textbook.pdf',
              type: 'pdf',
              filePath: '/documents/calculus.pdf',
              fileSize: 2048000,
              uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
              isProcessed: true,
            ),
          ],
        ),
        Subject(
          id: '2',
          name: 'Physics',
          description: 'Mechanics and thermodynamics',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          notes: [],
          materials: [],
        ),
      ];
      _saveSubjects();
      notifyListeners();
    }
  }
}
