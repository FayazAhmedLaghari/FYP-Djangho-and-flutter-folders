import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../models/subject_model.dart';
import 'upload_notes_tab.dart';
import 'view_notes_tab.dart';
import 'summary_flashcard_tab.dart';
import 'test_paper_tab.dart';

class SubjectDetailScreen extends StatelessWidget {
  final Subject subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(subject.name),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.upload_file), text: "Upload Notes"),
              Tab(icon: Icon(Icons.notes), text: "View Notes"),
              Tab(icon: Icon(Icons.auto_stories), text: "Summary / Flashcards"),
              Tab(icon: Icon(Icons.article), text: "Test Paper"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            UploadNotesTab(subject: subject),
            ViewNotesTab(subject: subject),
            SummaryFlashcardTab(subject: subject),
            TestPaperTab(subject: subject),
          ],
        ),
      ),
    );
  }
}
