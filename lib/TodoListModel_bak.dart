import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class TodoListModel extends ChangeNotifier {
  List<Task> todos = [];
  bool isLoading = true;
  int taskCount;
  //local ganache
  // final String _rpcUrl = "http://127.0.0.1:7545";
  // final String _wsUrl = "ws://127.0.0.1:7545/";
  //bsc testnet
  final String _rpcUrl = "https://data-seed-prebsc-1-s1.binance.org:8545/";
  final String _wsUrl = "";

  final String _privateKey =
      "865b87c8ef6e108fb3f700b99cd68e5d57c408d6114851780dbc580be595c0eb";

  Web3Client _client;
  String _abiCode;
  String _walletConnectUri;
  int _chainId;

  Credentials _credentials;
  EthereumAddress _contractAddress;
  EthereumAddress _ownAddress;
  DeployedContract _contract;

  ContractFunction _taskCount;
  ContractFunction _todos;
  ContractFunction _createTask;
  ContractFunction _updateTask;
  ContractFunction _deleteTask;
  ContractFunction _toggleComplete;

  TodoListModel() {
    init();
  }

  Future<void> init() async {
    _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });

    await getAbi();
    await getCredentials();
    await getDeployedContract();
    // await getWalletConnectUri();

    await getChainId();
  }

  Future<void> getChainId() async {
    debugPrint("getChainId");
    BigInt cid = await _client.getChainId();
    debugPrint("chainId: ${cid.toInt()}");
    _chainId = cid.toInt();
  }

  Future<void> getWalletConnectUri() async {
    // Create a connector
    final connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
        name: 'Todo Dapp',
        description: 'Test Todo_dapp Developer App',
        url: 'https://todo.dapp.org',
        icons: [
          'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
        ],
      ),
    );

    // Subscribe to events
    connector.on('connect', (session) => print(session));
    connector.on('session_update', (payload) => print(payload));
    connector.on('disconnect', (session) => print(session));

    // Create a new session
    if (!connector.connected) {
      final session = await connector.createSession(
        chainId: 4160,
        onDisplayUri: (uri) {
          debugPrint(uri);
          _walletConnectUri = uri;
          // AppMehtods.openUrl(uri); //call the launchUrl(uri) method  TODO
        },
      );
    }
  }

  Future<void> getAbi() async {
    String abiStringFile = await rootBundle
        .loadString("smartcontract/build/contracts/TodoContract.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    // _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);   //local ganache
    _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"]["97"]["address"]);
  }

  Future<void> getCredentials() async {
    _credentials = await EthPrivateKey.fromHex(_privateKey);
    // _credentials = await _client.credentialsFromPrivateKey(_privateKey);

    _ownAddress = await _credentials.extractAddress();
    debugPrint("_ownAddress: $_ownAddress");

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
    await getTodos();
  }

  getTodos() async {
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
      debugPrint("[waitTransaction] i=$i");
      TransactionReceipt receipt = await _client.getTransactionReceipt(txHash);
      debugPrint("receipt: ${receipt.toString()}");
      if (receipt != null && receipt.blockNumber.blockNum > 10) { //通过blockNum已经出来了，来判断已经被确认
        debugPrint("receipt: return ${receipt.status}");
        return receipt.status;
      }
      debugPrint("sleep 1 sec");
      await Future.delayed(const Duration(seconds: 1));//  sleep(const Duration(seconds: 1));
    }
    return false;
  }

  addTask(String taskNameData) async {
    isLoading = true;
    notifyListeners();
    String txHash = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _createTask,
        parameters: [taskNameData],
      ),
      chainId: _chainId
    );
    debugPrint("addTask: txId = $txHash");
    await waitTransaction(txHash);
    await getTodos();
  }

  updateTask(int id, String taskNameData) async {
    isLoading = true;
    notifyListeners();
    String txHash = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _updateTask,
        parameters: [BigInt.from(id), taskNameData],
      ),
      chainId: _chainId
    );
    await waitTransaction(txHash);
    await getTodos();
  }

  deleteTask(int id) async {
    isLoading = true;
    notifyListeners();
    String txHash = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _deleteTask,
        parameters: [BigInt.from(id)],
      ),
      chainId: _chainId
    );

    await waitTransaction(txHash);
    await getTodos();
  }

  toggleComplete(int id) async {
    isLoading = true;
    notifyListeners();
    String txHash = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _toggleComplete,
        parameters: [BigInt.from(id)],
      ),
      chainId: _chainId
    );
    await waitTransaction(txHash);
    await getTodos();
  }
}

class Task {
  final int id;
  final String taskName;
  final bool isCompleted;
  Task({this.id, this.taskName, this.isCompleted});
}