import 'package:flutter/material.dart';
import '../models/subject_model.dart';

class TestPaperTab extends StatefulWidget {
  final Subject subject;

  const TestPaperTab({super.key, required this.subject});

  @override
  State<TestPaperTab> createState() => _TestPaperTabState();
}

class _TestPaperTabState extends State<TestPaperTab> {
  bool _isGenerating = false;
  int _selectedQuestionCount = 10;
  String _selectedDifficulty = 'medium';
  String _selectedQuestionType = 'mixed';

  void _generateTestPaper() {
    setState(() {
      _isGenerating = true;
    });

    // Simulate AI processing
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isGenerating = false;
      });

      _showTestPaperDialog();
    });
  }

  void _showTestPaperDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generated Test Paper'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Test Paper for ${widget.subject.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildQuestionPreview(
                    '1. What is the main concept discussed in this subject?',
                    'Multiple Choice'),
                const SizedBox(height: 12),
                _buildQuestionPreview(
                    '2. Explain the key principles and their applications.',
                    'Short Answer'),
                const SizedBox(height: 12),
                _buildQuestionPreview(
                    '3. Calculate the following using the given formula...',
                    'Problem Solving'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Paper Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('• Total Questions: $_selectedQuestionCount'),
                      Text('• Difficulty: ${_selectedDifficulty.toUpperCase()}'),
                      Text(
                          '• Question Types: ${_selectedQuestionType.toUpperCase()}'),
                      Text(
                          '• Estimated Time: ${_selectedQuestionCount * 2} minutes'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test paper saved to materials'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPreview(String question, String type) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getQuestionTypeColor(type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getQuestionTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'multiple choice':
        return Colors.blue;
      case 'short answer':
        return Colors.green;
      case 'problem solving':
        return Colors.orange;
      case 'essay':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Test Paper Generator Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.article_outlined,
                          color: Colors.teal.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Test Paper Generator',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Create customized test papers from your study materials',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Configuration Options
                  Text(
                    'Test Configuration:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Number of Questions
                  Text(
                    'Number of Questions:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _selectedQuestionCount.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: _selectedQuestionCount.toString(),
                    onChanged: (value) {
                      setState(() {
                        _selectedQuestionCount = value.round();
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Difficulty Level
                  Text(
                    'Difficulty Level:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value ?? 'medium';
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Question Type
                  Text(
                    'Question Types:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedQuestionType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'mixed', child: Text('Mixed Types')),
                      DropdownMenuItem(
                          value: 'multiple_choice',
                          child: Text('Multiple Choice Only')),
                      DropdownMenuItem(
                          value: 'short_answer',
                          child: Text('Short Answer Only')),
                      DropdownMenuItem(
                          value: 'problem_solving',
                          child: Text('Problem Solving Only')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedQuestionType = value ?? 'mixed';
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateTestPaper,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.quiz),
                      label: Text(_isGenerating
                          ? 'Generating...'
                          : 'Generate Test Paper'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Study Tips Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: Colors.amber.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Test Taking Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Read all questions before starting\n• Manage your time effectively\n• Answer easy questions first\n• Review your answers before submitting\n• Practice with generated test papers regularly',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.5,
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
