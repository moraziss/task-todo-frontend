import 'dart:io'; // Нужен для проверки Platform
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Импортируем FFI для Desktop

import 'services/task_provider.dart';
import 'screens/main_screen.dart';

void main() {
  // 1. Обязательно инициализируем биндинги Флаттера
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Если запускаем на Windows, macOS или Linux — включаем правильный движок БД
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => TaskProvider()..initialize(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo App',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}