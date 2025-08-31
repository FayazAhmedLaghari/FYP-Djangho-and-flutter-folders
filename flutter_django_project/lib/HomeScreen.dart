import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Store your API key securely (consider using flutter_secure_storage for production)
  //static const String apiKey =
  //  'http://10.0.2.2:8000/api/tasks/'; // Replace with your actual key
  Future<List<dynamic>> fetchTasks() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://192.168.43.11:8000/api/tasks/'),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to load tasks. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error details: $e');
      throw Exception('Network error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home Screen'),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: fetchTasks(),
          builder: (context, snapshot) {
            print(snapshot);
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final task = snapshot.data![index];
                  return ListTile(
                    title: Text(task['title']),
                    subtitle: Text('${task['id']}'),
                    trailing: Icon(
                      task['is_completed'] ? Icons.check : Icons.close,
                      color: task['is_completed'] ? Colors.green : Colors.red,
                    ),
                  );
                },
              );
            } else {
              return const Center(child: Text("No tasks found"));
            }
          },
        ));
  }
}
