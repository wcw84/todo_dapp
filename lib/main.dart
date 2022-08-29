import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

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
        // home: Material(
        //   child: Center(
        //     child: ElevatedButton(
        //       onPressed: _launchUrl,
        //       child: Text('Show Flutter homepage'),
        //     ),
        //   ),
        // ),
      ),
    );
  }
}

// Future<void> _launchUrl() async {
//   const String prefix = 'https://metamask.app.link/dapp';
//   debugPrint("gUri: $gUri");
//   //https://metamask.app.link/dapp/payment/0x16bB66eAF844e9c095929Ee6693dccbbD8ce6643?amount=10000
//   final Uri _url = Uri.parse("$gUri");
//   debugPrint("_url: $_url");
//   if (!await launchUrl(_url)) {
//     throw "could not launch $_url";
//   }
// }