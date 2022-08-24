import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:convert/convert.dart';

class TodoListModel extends ChangeNotifier {
  List<Task> todos = [];
  bool isLoading = true;
  int taskCount = 0;

  String _ownAddress;
  // Provider _web3provider = null;
  // Signer _signer = null;
  //local ganache
  // final String _rpcUrl = "http://127.0.0.1:7545";
  // final String _wsUrl = "ws://127.0.0.1:7545/";
  //bsc testnet
  final String _rpcUrl = "https://data-seed-prebsc-1-s1.binance.org:8545/";
  final String _wsUrl = "";
  // final String _privateKey = "865b87c8ef6e108fb3f700b99cd68e5d57c408d6114851780dbc580be595c0eb";

  Web3Client _client;
  String _abiCode;

  // String _walletConnectUri;
  final int _chainId = 97; //bsc testnet
  //
  // Credentials _credentials;
  EthereumAddress _contractAddress;
  // String _contractAddress;
  // EthereumAddress _ownAddress;

  DeployedContract _contract;
  // Contract _contract;
  ContractFunction _taskCount;
  ContractFunction _todos;
  ContractFunction _createTask;
  ContractFunction _updateTask;
  ContractFunction _deleteTask;
  ContractFunction _toggleComplete;

  EthereumWalletConnectProvider _provider;
  WalletConnect _connector;

  TodoListModel() {
    init();
  }

  bool get isConnected => _connector != null && _connector.connected;
  // bool isConnected = false;
  String _externalWalletUri = '';
  Future<void> callExternalWallet() async {
    // const String prefix = 'https://metamask.app.link/dapp';
    debugPrint("callExternalWallet: $_externalWalletUri");
    //https://metamask.app.link/dapp/payment/0x16bB66eAF844e9c095929Ee6693dccbbD8ce6643?amount=10000
    final Uri url = Uri.parse(_externalWalletUri);
    if (!await launchUrl(url)) {
      throw "could not launch $url";
    }
  }

  Future<void> test() async {
    debugPrint("test2");
    _provider = EthereumWalletConnectProvider(_connector, chainId: _chainId);
    String from = _ownAddress;
    String to = '0x43CA6B6f0AAF1B8d2A5FBFC1049c37f9Ad6b802C';
    String value = '0x${555000.toRadixString(16)}';
    // debugPrint("from: $_ownAddress, to: $to, value: $value");
    //
    // final result = await _provider.sendTransaction(
    //   from: from,
    //   to: to,
    //   value: BigInt.parse(value)
    // );
    // debugPrint("txhash1: $result");
    //
    // String v = '0x${555000.toRadixString(16)}';
    // debugPrint("value: $v");

    // final result = await _connector.sendCustomRequest(
    //   method: 'eth_sendTransaction',
    //   params: [
    //     {
    //       'from': from,
    //       // if (data != null) 'data': hex.encode(List<int>.from(data)),
    //       'to': to,
    //       // if (gas != null) 'gas': '0x${gas.toRadixString(16)}',
    //       // if (gasPrice != null) 'gasPrice': '0x${gasPrice.toRadixString(16)}',
    //       // if (value != null) 'value': '0x${value.toRadixString(16)}',
    //       'value': value,
    //       // if (nonce != null) 'nonce': '0x${nonce.toRadixString(16)}',
    //     }
    //   ],
    // );
    // debugPrint("txhash1: $result");

    String data = hex.encode(List<int>.from(_taskCount.encodeCall([])));
    final result2 = await _connector.sendCustomRequest(
        method: 'eth_call',
        params: [
        {
        'from': from,
        'to': _contractAddress.toString(),
        'data': data
        }]);
    debugPrint("call _taskCount result: $result2");
    var list = _taskCount.decodeReturnValues(result2);
    debugPrint("call result: $list");
    BigInt totalTask = list[0];
    data = hex.encode(List<int>.from(_todos.encodeCall([totalTask])));
    String resultx;
    resultx = await _connector.sendCustomRequest(
        method: 'eth_call',
        params: [
          {
            'from': from,
            'to': _contractAddress.toString(),
            'data': data
          }]);
    list = _todos.decodeReturnValues(resultx);
    debugPrint("call result: $list");

    // debugPrint("start create task");
    // Uint8List datax = _createTask.encodeCall(['taskNewAdded']);
    // debugPrint("data: ${datax.toString()}");
    // String resultx = await _provider.sendTransaction(
    //   from: from,
    //   to: _contractAddress.toString(),
    //   // value: BigInt.parse(value)
    //   data: datax
    // );
    // debugPrint("txhash1: $resultx");

    // String v = '0x${555000.toRadixString(16)}';
    // debugPrint("value: $v");
    // debugPrint("start create task again");
    // resultx = await _connector.sendCustomRequest(
    //     method: 'eth_sendTransaction',
    //     params: [
    //     {
    //     'from': from,
    //     'to': _contractAddress.toString(),
    //     'data': hex.encode(List<int>.from(datax))
    //   }]);
    // debugPrint("_createTask again result: $resultx");

    // Sign the transaction
    // final signedBytes = await _provider.signTransaction(
    //   tx.toBytes(),
    //   params: {
    //     'message': 'Optional description message',
    //   },
    // );
    //
    // // Broadcast the transaction
    // final txId = await algorand.sendRawTransactions(
    //   signedBytes,
    //   waitForConfirmation: true,
    // );

  }

  Future<void> getAbi() async {
    String abiStringFile = await rootBundle
        .loadString("smartcontract/build/contracts/TodoContract.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    // _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);   //local ganache
    _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"][_chainId.toString()]["address"]);
    debugPrint("getAbi: contractAddress: ${_contractAddress.toString()}");
  }

  Future<void> getDeployedContract() async {
    _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode, "TodoList"), _contractAddress);
    _taskCount = _contract.function("taskCount");
    _updateTask = _contract.function("updateTask");
    _createTask = _contract.function("createTask");
    _deleteTask = _contract.function("deleteTask");
    _toggleComplete = _contract.function("toggleComplete");
    _todos = _contract.function("todos");

    // await getTodos();
  }

  Future<void> connectWallet() async {
    debugPrint("connectWallet");

    // Create a connector
    final connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
        name: 'Todo_dapp',
        description: 'Test Todo_dapp Developer App',
        url: 'https://todo.dapp.org',
        icons: [
          'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
        ],
      ),
    );
    _connector = connector;

    // Subscribe to events
    connector.on('connect', (SessionStatus sessionStatus) {
      debugPrint("onConnect: SessionStatus=$sessionStatus");
      _ownAddress = (sessionStatus).accounts[0];
      if (sessionStatus.chainId != _chainId) {
        debugPrint("Please change current chainId to $_chainId");
      }
      // isConnected = true;
      _provider = EthereumWalletConnectProvider(_connector, chainId: _chainId);
      getTodos();
    });

    connector.on('session_update', (payload) {
      debugPrint("onSession_update: payload=$payload");
    });
    connector.on('disconnect', (session) {
      debugPrint("onDisconnect: session=$session");
    });

    // Create a new session
    if (!connector.connected) {
      final session = await connector.createSession(
          chainId: _chainId,
          onDisplayUri: (uri) {
            _externalWalletUri = uri;
            debugPrint("uri=$uri");
            // AppMehtods.openUrl(uri); //call the launchUrl(uri) method
            callExternalWallet();
          }
      );
      //stuck here????
    }
// Kill the session
//     connector.killSession();
  }

  Future<void> disConnectWallet() async {
    if (isConnected) {
      isLoading = true;
      notifyListeners();
      await _connector.killSession();
      _provider = null;
      await getTodos();
    }
  }

  Future<void> init() async {
    debugPrint("TodoListModel init");
    _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });

    await getAbi();
    await getDeployedContract();
    await getTodos();

    // //for test 方便调试 todo
    // final wallet = Wallet("865b87c8ef6e108fb3f700b99cd68e5d57c408d6114851780dbc580be595c0eb");
    // // Connect wallet to network
    // _web3provider = JsonRpcProvider('https://data-seed-prebsc-2-s2.binance.org:8545/');
    // _signer = wallet.connect(_web3provider);
    // // walletWithProvider;
    //
    // // Get account balance
    // debugPrint("balance: ${await _signer.getBalance()}"); // 315752957360231815
    //
    // // Get account sent transaction count (not contract call)
    // debugPrint("getTransactionCount: ${await _signer.getTransactionCount(BlockTag.latest)}"); // 1
    //
    // // test send transaction: Send 1000000000 wei to `0xcorge`
    // // final tx = await signer.sendTransaction(
    // //   TransactionRequest(
    // //     to: '0x9f9cdf6ae8De9F76d2374FE33fF92Fa2aFE5AA1C',
    // //     value: BigInt.from(1000000000),
    // //   ),
    // // );
    // //
    // // debugPrint("txHash: ${tx.hash}"); // 0xplugh
    // //
    // // final receipt = await tx.wait();
    // // if (receipt is TransactionReceipt) { // true
    // //   debugPrint("receipt is : $receipt");
    // // }
    //
    //
    // // _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
    // //   return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    // // });
    //
    // //test contract
    // await initContract();
    // await getTodos();
    // // await getCredentials();
    // // await getDeployedContract();
    // // // await getWalletConnectUri();
    //
    // await testWalletConnect();
  }

  getTodos() async {
    debugPrint("gettodos");

    //通过walletconnect + web3dart
    // if (_connector == null || _connector.connected == false) {
    //   debugPrint("walletConnector not connected, try to connect first!");
    //   return;
    // }
    // var list = await ethCallWrapped(_connector, _ownAddress, _contractAddress.toString(), _taskCount, []);
    // BigInt taskCount = list[0];
    // debugPrint("call result: taskCount=$taskCount");
    // todos.clear();
    // for (var i = 0; i < taskCount.toInt(); i++) {
    //   var temp = await ethCallWrapped(_connector, _ownAddress, _contractAddress.toString(), _todos, [BigInt.from(i)]);
    //   debugPrint("${temp[0]}, ${temp[1]}, ${temp[2]}");
    //   if (temp[1] != "") {
    //     todos.add(
    //         Task(
    //             id: int.parse(temp[0].toString()),
    //             taskName: temp[1],
    //             isCompleted: temp[2]
    //         )
    //     );
    //   }
    //   else {
    //     debugPrint('i = $i, null found');
    //   }
    // }

    //通过web3dart
    List totalTaskList = await _client
        .call(contract: _contract, function: _taskCount, params: []);

    BigInt totalTask = totalTaskList[0];
    taskCount = totalTask.toInt();
    todos.clear();
    for (var i = 0; i < totalTask.toInt(); i++) {
      var temp = await _client.call(
          contract: _contract, function: _todos, params: [BigInt.from(i)]);
      if (temp[1] != "") {
        todos.add(
          Task(
            id: (temp[0] as BigInt).toInt(),
            taskName: temp[1],
            isCompleted: temp[2],
          ),
        );
      }
      else {
        print('i = $i, null found');
      }
    }
    isLoading = false;
    todos = todos.reversed.toList();
    notifyListeners();
  }

  Future<bool> waitTransaction(String txHash) async {
    debugPrint("[waitTransaction] $txHash");
    for (int i = 0; i < 10; i++) {
      TransactionReceipt receipt = await _client.getTransactionReceipt(txHash);
      debugPrint("[waitTransaction] i=$i, receipt: ${receipt.toString()}");
      if (receipt != null && receipt.blockNumber.blockNum > 10) { //通过blockNum已经出来了，来判断已经被确认
        debugPrint("receipt: return ${receipt.status}");
        return receipt.status;
      }
      // debugPrint("sleep 1 sec");
      await Future.delayed(const Duration(seconds: 1));//  sleep(const Duration(seconds: 1));
    }
    return false;
  }
  //
  addTask(String taskNameData) async {
    isLoading = true;
    notifyListeners();
    debugPrint("addTask");
    var txHash = await ethSendTxWrapped(_connector, _ownAddress, _contractAddress.toString(), _createTask, [taskNameData]);
    debugPrint("txHash: $txHash");
    final receipt = await waitTransaction(txHash);
    debugPrint("receipt: $receipt");
    await getTodos();
  }

  updateTask(int id, String taskNameData) async {
    isLoading = true;
    notifyListeners();
    debugPrint("updateTask");
    var txHash = await ethSendTxWrapped(_connector, _ownAddress, _contractAddress.toString(), _updateTask, [BigInt.from(id), taskNameData]);
    debugPrint("txHash: $txHash");
    final receipt = await waitTransaction(txHash);
    debugPrint("receipt: $receipt");
    await getTodos();
  }

  deleteTask(int id) async {
    isLoading = true;
    notifyListeners();
    debugPrint("deleteTask");
    var txHash = await ethSendTxWrapped(_connector, _ownAddress, _contractAddress.toString(), _deleteTask, [BigInt.from(id)]);
    debugPrint("txHash: $txHash");
    final receipt = await waitTransaction(txHash);
    debugPrint("receipt: $receipt");
    await getTodos();
  }

  toggleComplete(int id) async {
    isLoading = true;
    notifyListeners();
    debugPrint("toggleComplete");
    var txHash = await ethSendTxWrapped(_connector, _ownAddress, _contractAddress.toString(), _toggleComplete, [BigInt.from(id)]);
    debugPrint("txHash: $txHash");
    final receipt = await waitTransaction(txHash);
    debugPrint("receipt: $receipt");
    await getTodos();
  }

  Future<String> ethSendTxWrapped(WalletConnect connector,String fromAddress, String contractAddress, ContractFunction fn, List<dynamic> params) async{
    if (!isConnected) {
      debugPrint("try to connect wallet first");
      await connectWallet();
    }
    debugPrint("[ethSendTxWrapped] fn=$fn, params=$params");
    String data = hex.encode(List<int>.from(fn.encodeCall(params)));
    debugPrint("data: $data");
    callExternalWallet();
    final result = await connector.sendCustomRequest(
        method: 'eth_sendTransaction',
        params: [{
          'from': fromAddress,
          'to': contractAddress,
          'data': data
        }]);
    // debugPrint("sendTx result: $result");
    // var temp = fn.decodeReturnValues(result);
    // debugPrint("call result: $result, after decoded: $temp");
    return result;
  }

  Future<List> ethCallWrapped(WalletConnect connector,String fromAddress, String contractAddress, ContractFunction fn, List<dynamic> params) async{
    debugPrint("fn=$fn, params=$params");
    String data = hex.encode(List<int>.from(fn.encodeCall(params)));
    debugPrint("data: $data");
    final result = await connector.sendCustomRequest(
        method: 'eth_call',
        params: [{
          'from': fromAddress,
          'to': contractAddress,
          'data': data
        }]);
    // debugPrint("call result: $result");
    var temp = fn.decodeReturnValues(result);
    debugPrint("call result: $result, after decoded: $temp");
    return temp;
  }

}

class Task {
  final int id;
  final String taskName;
  final bool isCompleted;
  Task({this.id, this.taskName, this.isCompleted});
}