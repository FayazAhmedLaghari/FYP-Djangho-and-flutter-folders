import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../models/subject_model.dart';

class UploadNotesTab extends StatefulWidget {
  final Subject subject;
  
  const UploadNotesTab({super.key, required this.subject});

  @override
  State<UploadNotesTab> createState() => _UploadNotesTabState();
}

class _UploadNotesTabState extends State<UploadNotesTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedType = 'text';
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _uploadFile() {
    // TODO: Implement file picker logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker functionality will be implemented')),
    );
  }

  void _addTextNote() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some content'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Simulate upload delay
    Future.delayed(const Duration(seconds: 1), () {
      final note = SubjectNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        createdAt: DateTime.now(),
      );

      context.read<DashboardViewModel>().addNoteToSubject(widget.subject.id, note);

      setState(() {
        _isUploading = false;
        _titleController.clear();
        _contentController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upload File Section
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload File',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload PDF, images, or other documents',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadFile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text("Choose File"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Add Text Note Section
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Text Note',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Note Type Selection
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Note Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'text', child: Text('Text Note')),
                      DropdownMenuItem(value: 'summary', child: Text('Summary')),
                      DropdownMenuItem(value: 'formula', child: Text('Formula')),
                      DropdownMenuItem(value: 'definition', child: Text('Definition')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value ?? 'text';
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title Field
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Note Title',
                      hintText: 'Enter a title for your note',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Content Field
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Note Content',
                      hintText: 'Enter your note content here...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Add Note Button
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _addTextNote,
                    icon: _isUploading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(_isUploading ? 'Adding...' : 'Add Note'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
