import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_dapp/TodoList.dart';
import 'package:todo_dapp/TodoListModel.dart';

void main() {
  runApp(MyApp());

  if (kIsWeb) {
    debugPrint("isWeb");
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    debugPrint("IOS");
  } else if (defaultTargetPlatform == TargetPlatform.macOS) {
    debugPrint("isMacOS");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TodoListModel(),
      child: const MaterialApp(
        title: 'Flutter TODO',
        home: TodoList(),
      ),
    );
  }
}