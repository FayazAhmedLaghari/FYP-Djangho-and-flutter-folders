import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../models/subject_model.dart';
import '../ApiService.dart';

class ViewNotesTab extends StatefulWidget {
  final Subject subject;

  const ViewNotesTab({super.key, required this.subject});

  @override
  State<ViewNotesTab> createState() => _ViewNotesTabState();
}

class _ViewNotesTabState extends State<ViewNotesTab> {
  List<dynamic> _serverDocuments = [];
  bool _isLoadingDocuments = false;

  @override
  void initState() {
    super.initState();
    _loadServerDocuments();
  }

  Future<void> _loadServerDocuments() async {
    setState(() {
      _isLoadingDocuments = true;
    });
    final result = await ApiService.getDocuments();
    if (!mounted) return;
    setState(() {
      _isLoadingDocuments = false;
      if (result['success'] == true) {
        _serverDocuments = result['data'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, child) {
        final currentSubject = viewModel.getSubjectById(widget.subject.id);
        final notes = currentSubject?.notes ?? [];
        final materials = currentSubject?.materials ?? [];

        return Column(
          children: [
            // Server documents section (same source as HomeScreen)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.cloud, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  const Text('Server Documents',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _isLoadingDocuments ? null : _loadServerDocuments,
                    icon: const Icon(Icons.refresh),
                  )
                ],
              ),
            ),
            if (_isLoadingDocuments)
              const LinearProgressIndicator(minHeight: 2),
            SizedBox(
              height: 160,
              child: RefreshIndicator(
                onRefresh: _loadServerDocuments,
                child: _serverDocuments.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: Text(
                              'No documents yet. Use Dashboard → AI Chat to upload.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _serverDocuments.length,
                        itemBuilder: (context, index) {
                          final doc = _serverDocuments[index];
                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              elevation: 2,
                              child: ListTile(
                                leading: const Icon(Icons.picture_as_pdf,
                                    color: Colors.red),
                                title: Text(_getFileName(doc['file'] ?? ''),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  _formatDateString(doc['uploaded_at'] ?? ''),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: doc['processed'] == true
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      color: Colors.grey.shade100,
                      child: const TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        labelColor: Colors.deepPurple,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.deepPurple,
                        tabs: [
                          Tab(text: 'Notes'),
                          Tab(text: 'Materials'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildNotesList(notes, viewModel),
                          _buildMaterialsList(materials, viewModel),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildNotesList(
      List<SubjectNote> notes, DashboardViewModel viewModel) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notes,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No notes yet",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getNoteTypeColor(note.type),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getNoteTypeIcon(note.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              note.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(note.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      note.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getNoteTypeColor(note.type),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteNoteDialog(context, note, viewModel);
                } else if (value == 'view') {
                  _showNoteDetail(context, note);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _showNoteDetail(context, note),
          ),
        );
      },
    );
  }

  Widget _buildMaterialsList(
      List<SubjectMaterial> materials, DashboardViewModel viewModel) {
    if (materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_file,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No materials yet",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getMaterialTypeColor(material.type),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getMaterialTypeIcon(material.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              material.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(material.uploadedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.storage,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatFileSize(material.fileSize),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            material.isProcessed ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        material.isProcessed ? 'Processed' : 'Processing',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      material.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getMaterialTypeColor(material.type),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteMaterialDialog(context, material, viewModel);
                } else if (value == 'view') {
                  _viewMaterial(context, material);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _viewMaterial(context, material),
          ),
        );
      },
    );
  }

  void _showDeleteNoteDialog(
      BuildContext context, SubjectNote note, DashboardViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              viewModel.removeNoteFromSubject(widget.subject.id, note.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Note "${note.title}" deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteMaterialDialog(BuildContext context, SubjectMaterial material,
      DashboardViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              viewModel.removeMaterialFromSubject(widget.subject.id, material.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Material "${material.title}" deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNoteDetail(BuildContext context, SubjectNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note.title),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: SingleChildScrollView(
            child: Text(note.content),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewMaterial(BuildContext context, SubjectMaterial material) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${material.title}'),
      ),
    );
  }

  Color _getNoteTypeColor(String type) {
    switch (type) {
      case 'text':
        return Colors.blue;
      case 'summary':
        return Colors.green;
      case 'formula':
        return Colors.orange;
      case 'definition':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getNoteTypeIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.notes;
      case 'summary':
        return Icons.summarize;
      case 'formula':
        return Icons.functions;
      case 'definition':
        return Icons.book;
      default:
        return Icons.note;
    }
  }

  Color _getMaterialTypeColor(String type) {
    switch (type) {
      case 'pdf':
        return Colors.red;
      case 'image':
        return Colors.green;
      case 'video':
        return Colors.purple;
      case 'document':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getMaterialTypeIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'document':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
