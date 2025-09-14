import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'screens/subject_list_screen.dart';
import 'screens/other_screens.dart';
import 'HomeScreen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<Dashboard> {
  static const List<Widget> _pages = <Widget>[
    SubjectListScreen(),
    ChatScreen(),
    PlannerScreen(),
    QuizScreen(),
    GroupsScreen(),
  ];

  static const List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Subjects'),
    BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI Chat'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Planner'),
    BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quizzes'),
    BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Groups'),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DashboardViewModel(),
      child: Consumer<DashboardViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('AI-Powered Study Assistant'),
              centerTitle: true,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  },
                  tooltip: 'Go to Chat with PDF',
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    color: const Color(0xFF001E62), // Dark blue background
                    child: Column(children: [
                      // Header Section
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        decoration: BoxDecoration(color: Color(0xFF001E62)),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person,
                                  size: 50, color: Color(0xFF001E62)),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Study Assistant',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Manage your subjects and notes',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Chat with PDF'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder),
                    title: const Text('My Subjects'),
                    onTap: () {
                      Navigator.pop(context);
                      viewModel.setSelectedIndex(0);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.smart_toy),
                    title: const Text('AI Chat'),
                    onTap: () {
                      Navigator.pop(context);
                      viewModel.setSelectedIndex(1);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Study Planner'),
                    onTap: () {
                      Navigator.pop(context);
                      viewModel.setSelectedIndex(2);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.quiz),
                    title: const Text('Quizzes'),
                    onTap: () {
                      Navigator.pop(context);
                      viewModel.setSelectedIndex(3);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.groups),
                    title: const Text('Study Groups'),
                    onTap: () {
                      Navigator.pop(context);
                      viewModel.setSelectedIndex(4);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('LogOut'),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        'loginOnly',
                        (route) => false, // removes all previous routes
                      );
                    },
                  ),
                ],
              ),
            ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _pages[viewModel.selectedIndex],
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: _bottomNavItems,
              currentIndex: viewModel.selectedIndex,
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.grey,
              onTap: viewModel.setSelectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 10,
            ),
          );
        },
      ),
    );
  }
}
