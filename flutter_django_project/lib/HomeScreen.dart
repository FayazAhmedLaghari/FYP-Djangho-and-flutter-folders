import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ApiService.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<dynamic> _documents = [];
  List<dynamic> _queryHistory = [];
  String _answer = '';
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isProcessing = false;
  bool _isUploading = false;
  bool _isAskingQuestion = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final isLoggedIn = await ApiService.isLoggedIn();
      setState(() {
        _isLoggedIn = isLoggedIn;
      });

      if (_isLoggedIn) {
        _loadDocuments();
        _loadQueryHistory();
      }
    } catch (e) {
      print('Error checking login status: $e');
    }
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        setState(() {
          _isLoggedIn = true;
        });
        _loadDocuments();
        _loadQueryHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await ApiService.logout();
      setState(() {
        _isLoggedIn = false;
        _documents = [];
        _queryHistory = [];
        _answer = '';
        _usernameController.clear();
        _passwordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged out successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout error: $e')),
      );
    }
  }

  Future<void> _loadDocuments() async {
    try {
      final result = await ApiService.getDocuments();

      if (result['success']) {
        setState(() {
          _documents = result['data'] ?? [];
        });
      } else {
        if (result['error']?.contains('Authentication failed') ?? false) {
          // Token expired, log out user
          await _logout();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['error'] ?? 'Failed to load documents')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading documents: $e')),
      );
    }
  }

  Future<void> _loadQueryHistory() async {
    try {
      final result = await ApiService.getQueryHistory();

      if (result['success']) {
        setState(() {
          _queryHistory = result['data'] ?? [];
        });
      } else {
        if (result['error']?.contains('Authentication failed') ?? false) {
          await _logout();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['error'] ?? 'Failed to load history')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading history: $e')),
      );
    }
  }

  Future<void> _uploadPdf() async {
    try {
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

        setState(() {
          _isUploading = false;
        });

        if (uploadResult['success']) {
          await _loadDocuments(); // Reload documents list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF uploaded successfully')),
          );
        } else {
          if (uploadResult['error']?.contains('Authentication failed') ??
              false) {
            await _logout();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(uploadResult['error'] ?? 'Upload failed')),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e')),
      );
    }
  }

  Future<void> _askQuestion() async {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    setState(() {
      _isAskingQuestion = true;
    });

    try {
      final result = await ApiService.askQuestion(_questionController.text);

      setState(() {
        _isAskingQuestion = false;
      });

      if (result['success']) {
        setState(() {
          _answer = result['data']['answer'] ?? 'No answer received';
        });
        await _loadQueryHistory(); // Reload query history
        _questionController.clear();
      } else {
        if (result['error']?.contains('Authentication failed') ?? false) {
          await _logout();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Failed to get answer')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isAskingQuestion = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error asking question: $e')),
      );
    }
  }

  Future<void> _deleteDocument(int documentId) async {
    try {
      final result = await ApiService.deleteDocument(documentId);

      if (result['success']) {
        await _loadDocuments(); // Reload documents list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document deleted successfully')),
        );
      } else {
        if (result['error']?.contains('Authentication failed') ?? false) {
          await _logout();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['error'] ?? 'Failed to delete document')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete error: $e')),
      );
    }
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Chat with PDF',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          SizedBox(height: 15),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          SizedBox(height: 20),
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: Text('Login'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () {
              // Demo credentials hint
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Use your Django admin credentials')),
              );
            },
            child: Text('Forgot credentials?'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        AppBar(
          title: Text('Chat with PDF'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.chat), text: 'Chat'),
                    Tab(icon: Icon(Icons.history), text: 'History'),
                    Tab(icon: Icon(Icons.folder), text: 'Documents'),
                  ],
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildChatTab(),
                      _buildHistoryTab(),
                      _buildDocumentsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    labelText: 'Ask a question about your PDFs',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _isAskingQuestion ? null : _askQuestion,
                    ),
                  ),
                  onSubmitted: (_) => _askQuestion(),
                  enabled: !_isAskingQuestion,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _isAskingQuestion
              ? Center(child: CircularProgressIndicator())
              : Expanded(
                  child: _answer.isNotEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              child: Text(
                                _answer,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            'Ask a question to get started',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadQueryHistory,
      child: _queryHistory.isEmpty
          ? Center(
              child: Text(
                'No query history yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _queryHistory.length,
              itemBuilder: (context, index) {
                final query = _queryHistory[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(
                      query['question'] ?? 'No question',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(query['answer'] ?? 'No answer'),
                    trailing: Text(
                      _formatDate(query['created_at'] ?? ''),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDocumentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isUploading
              ? CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadPdf,
                  icon: Icon(Icons.upload_file),
                  label: Text('Upload PDF'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDocuments,
            child: _documents.isEmpty
                ? Center(
                    child: Text(
                      'No documents uploaded yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final document = _documents[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading:
                              Icon(Icons.picture_as_pdf, color: Colors.red),
                          title: Text(_getFileName(document['file'] ?? '')),
                          subtitle: Text(
                            'Uploaded: ${_formatDate(document['uploaded_at'] ?? '')}',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              document['processed'] == true
                                  ? Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                              SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _showDeleteDialog(document['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(int documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Document'),
        content: Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDocument(documentId);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoggedIn ? _buildMainContent() : _buildLoginForm(),
    );
  }
}
