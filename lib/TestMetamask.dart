import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

String gUri = '';
testMetaMask() async {
  // Create a connector
  final connector = WalletConnect(
    bridge: 'https://bridge.walletconnect.org',
    clientMeta: PeerMeta(
      name: 'Todo_dapp',
      description: 'Test Todo_dapp Developer App',
      url: 'https://todo.dapp.org',
      icons: [
        'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
      ],
    ),
  );
  // connector.sendCustomRequest(method: method, params: params)
// Subscribe to events
  connector.on('connect', (session) => print(session));
  connector.on('session_update', (payload) => print(payload));
  connector.on('disconnect', (session) => print(session));

// Create a new session
  if (!connector.connected) {
    final session = await connector.createSession(
      chainId: 4160,
      onDisplayUri: (uri) {
        // debugPrint(uri);
        gUri = uri;
        debugPrint("connected: uri=$uri");
        // AppMehtods.openUrl(uri); //call the launchUrl(uri) method  TODO

        }

    );
    debugPrint("session: ${session}");
  }


//
//   final sender = Address.fromAlgorandAddress(address: session.accounts[0]);
//
// // Fetch the suggested transaction params
//   final params = await algorand.getSuggestedTransactionParams();
//
// // Build the transaction
//   final transaction = await (PaymentTransactionBuilder()
//     ..sender = sender
//     ..noteText = 'Signed with WalletConnect'
//     ..amount = Algo.toMicroAlgos(0.0001)
//     ..receiver = sender
//     ..suggestedParams = params)
//       .build();
//
// // Sign the transaction
//   final txBytes = Encoder.encodeMessagePack(transaction.toMessagePack());
//   final signedBytes = await connector.signTransaction(
//     txBytes,
//     params: {
//       'message': 'Optional description message',
//     },
//   );
//
// // Broadcast the transaction
//   final txId = await algorand.sendRawTransactions(
//     signedBytes,
//     waitForConfirmation: true,
//   );
//   print(txId);

// Kill the session
  connector.killSession();
}
