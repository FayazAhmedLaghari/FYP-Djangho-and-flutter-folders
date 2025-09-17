import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../ApiService.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../models/subject_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isUploading = false;
  List<dynamic> _documents = [];
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final result = await ApiService.getDocuments();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _documents = result['data'] ?? [];
      });
    }
  }

  Future<void> _uploadPdf() async {
    try {
      if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a subject first')),
        );
        return;
      }
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _isUploading = true;
        });

        File file = File(result.files.single.path!);
        final uploadResult = await ApiService.uploadPdf(file);

        if (!mounted) return;
        setState(() {
          _isUploading = false;
        });

        if (uploadResult['success'] == true) {
          await _loadDocuments();
          if (!mounted) return;
          // Map server doc -> SubjectMaterial and add to selected subject
          final data = uploadResult['data'] ?? {};
          final filePath = data['file'] ?? '';
          final uploadedAt = data['uploaded_at'] ?? DateTime.now().toIso8601String();
          final processed = data['processed'] == true;
          final material = SubjectMaterial(
            id: (data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString()),
            title: _getFileName(filePath),
            type: 'pdf',
            filePath: filePath,
            fileSize: 0,
            uploadedAt: DateTime.tryParse(uploadedAt) ?? DateTime.now(),
            isProcessed: processed,
          );
          if (!mounted) return;
          Provider.of<DashboardViewModel>(context, listen: false)
              .addMaterialToSubject(_selectedSubjectId!, material);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF uploaded successfully')),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(uploadResult['error'] ?? 'Upload failed')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e')),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isUploading ? null : _uploadPdf,
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload PDF (same as Home)',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
          children: [
                Expanded(child: _buildSubjectPicker()),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              icon: const Icon(Icons.chat),
                  label: const Text('Open Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: LinearProgressIndicator(),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDocuments,
              child: _documents.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('No documents uploaded yet', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final document = _documents[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                            title: Text(_getFileName(document['file'] ?? '')),
                            subtitle: Text('Uploaded: ${_formatDate(document['uploaded_at'] ?? '')}'),
                            trailing: document['processed'] == true
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadPdf,
        label: const Text('Upload PDF'),
        icon: const Icon(Icons.upload_file),
      ),
    );
  }

  Widget _buildSubjectPicker() {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        final subjects = vm.subjects;
        if (subjects.isEmpty) {
          return Text('No subjects yet. Add one in Subjects tab.',
              style: TextStyle(color: Colors.grey.shade700));
        }
        _selectedSubjectId ??= subjects.first.id;
        return DropdownButtonFormField<String>(
          value: _selectedSubjectId,
          decoration: const InputDecoration(
            labelText: 'Select Subject for Upload',
            border: OutlineInputBorder(),
          ),
          items: subjects
              .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedSubjectId = v),
        );
      },
    );
  }
}

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 80,
              color: Colors.deepPurple.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              '📅 Study Planner Screen',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Plan your study schedule and track progress',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Study planner feature coming soon!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.schedule),
              label: const Text('Create Study Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              size: 80,
              color: Colors.deepPurple.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              '📝 Quizzes Screen',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Take quizzes and test your knowledge',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quiz feature coming soon!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.quiz),
              label: const Text('Start Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Groups'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups,
              size: 80,
              color: Colors.deepPurple.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              '👥 Study Groups Screen',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Join study groups and collaborate with peers',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Study groups feature coming soon!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.group_add),
              label: const Text('Join Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
