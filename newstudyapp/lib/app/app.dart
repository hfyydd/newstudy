import 'package:flutter/material.dart';
import 'package:newstudyapp/config/api_config.dart';
import 'package:newstudyapp/pages/home/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const title = '费曼学习法';
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(
        title: title,
        backendBaseUrl: apiBaseUrl,
      ),
    );
  }
}
