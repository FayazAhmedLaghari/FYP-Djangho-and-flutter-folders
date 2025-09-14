import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'HomeScreen.dart';
import 'Dashboard.dart';
import 'viewmodels/dashboard_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DashboardViewModel()),
      ],
      child: MaterialApp(
        title: 'AI-Powered Study Assistant',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const Dashboard(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/dashboard': (context) => const Dashboard(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
