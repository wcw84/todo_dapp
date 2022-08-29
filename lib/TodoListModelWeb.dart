import 'dart:convert';
import 'dart:core';
import 'package:js/js.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:todo_dapp/TodoListModelBase.dart';
import 'package:todo_dapp/Task.dart';
import 'package:flutter_web3/flutter_web3.dart';

class TodoListModel extends ChangeNotifier implements TodoListModelBase{
  @override
  List<Task> todos = [];
  @override
  bool isLoading = true;
  @override
  int taskCount = 0;

  @override
  bool isConnected = false;

  String _ownAddress = "";
  Web3Provider _web3provider = null;
  Signer _signer = null;
  //local ganache
  // final String _rpcUrl = "http://127.0.0.1:7545";
  // final String _wsUrl = "ws://127.0.0.1:7545/";
  //bsc testnet
  // final String _rpcUrl = "https://data-seed-prebsc-1-s1.binance.org:8545/";
  // final String _wsUrl = "";

  // final String _privateKey = "865b87c8ef6e108fb3f700b99cd68e5d57c408d6114851780dbc580be595c0eb";

  // Web3Client _client;
  String _abiCode;

  // String _walletConnectUri;
  final int _chainId = 97; //bsc testnet
  //
  // Credentials _credentials;
  // EthereumAddress _contractAddress;
  String _contractAddress;
  // EthereumAddress _ownAddress;
  // DeployedContract _contract;
  Contract _contract;
  // ContractFunction _taskCount;
  // ContractFunction _todos;
  // ContractFunction _createTask;
  // ContractFunction _updateTask;
  // ContractFunction _deleteTask;
  // ContractFunction _toggleComplete;

  TodoListModel() {
    init();

  }

  @override
  Future<void> disConnectWallet() async {
  }

  @override
  Future<void> connectWallet() async {
  }

  @override
  Future<void> callExternalWallet() async {
  }

  Future<void> init() async {
    debugPrint("TodoListModel_metamask init");

    // `Ethereum.isSupported` is the same as `ethereum != null`
    if (ethereum != null) {
      try {
        // Prompt user to connect to the provider, i.e. confirm the connection modal
        final accs = await ethereum.requestAccount(); // Get all accounts in node disposal
        debugPrint("get accounts from metamask: $accs");
        int chainId = await ethereum.getChainId();
        if (_chainId != chainId) {
          debugPrint("current chainId is $chainId, expect $_chainId, try switchChain");
          ethereum.walletSwitchChain(_chainId);
        }
        _ownAddress = accs[0]; // [foo,bar]

        if (ethereum == null) {
          print("oops ethereum is null");
        }
        _web3provider = Web3Provider.fromEthereum(ethereum);
        print(_web3provider.toString());

        int bn = await _web3provider.getBlockNumber(); // 9261427
        debugPrint("bn: $bn");

        // Subscribe to `chainChanged` event
        ethereum.onChainChanged((chainId) {
          if (_chainId != chainId) {
            debugPrint("onChainChanged: current chainId is $chainId, expect $_chainId, try switchChain");
            ethereum.walletSwitchChain(_chainId);
          }
        });

        // Subscribe to `accountsChanged` event.
        ethereum.onAccountsChanged((accounts) {
          print("onAccountsChanged: $accounts"); // ['0xbar']
        });

        // Subscribe to `message` event, need to convert JS message object to dart object.
        ethereum.on('message', (message) {
          print("on message: ${dartify(message)}"); // baz
        });

      } on EthereumUserRejected {
        print('User rejected the modal');
      }
    }

    // Get signer from provider
    _signer = _web3provider.getSigner();

    //for test 方便调试 todo
    // final wallet = Wallet("865b87c8ef6e108fb3f700b99cd68e5d57c408d6114851780dbc580be595c0eb");
    // // Connect wallet to network
    // _web3provider = JsonRpcProvider('https://data-seed-prebsc-2-s2.binance.org:8545/');
    // _signer = wallet.connect(_web3provider);
    // walletWithProvider;

    // Get account balance
    debugPrint("balance: ${await _signer.getBalance()}"); // 315752957360231815

    // Get account sent transaction count (not contract call)
    debugPrint("getTransactionCount: ${await _signer.getTransactionCount(BlockTag.latest)}"); // 1

    // test send transaction: Send 1000000000 wei to `0xcorge`
    // final tx = await signer.sendTransaction(
    //   TransactionRequest(
    //     to: '0x9f9cdf6ae8De9F76d2374FE33fF92Fa2aFE5AA1C',
    //     value: BigInt.from(1000000000),
    //   ),
    // );
    //
    // debugPrint("txHash: ${tx.hash}"); // 0xplugh
    //
    // final receipt = await tx.wait();
    // if (receipt is TransactionReceipt) { // true
    //   debugPrint("receipt is : $receipt");
    // }


    // _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
    //   return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    // });

    //test contract
    await initContract();
    await getTodos();
    // await getCredentials();
    // await getDeployedContract();
    // // await getWalletConnectUri();

    await testWalletConnect();
  }

  // Future<void> getChainId() async {
  //   debugPrint("getChainId");
  //   BigInt cid = await _client.getChainId();
  //   debugPrint("chainId: ${cid.toInt()}");
  //   _chainId = cid.toInt();
  // }
  //
  // Future<void> getWalletConnectUri() async {
  //   // Create a connector
  //   final connector = WalletConnect(
  //     bridge: 'https://bridge.walletconnect.org',
  //     clientMeta: const PeerMeta(
  //       name: 'Todo Dapp',
  //       description: 'Test Todo_dapp Developer App',
  //       url: 'https://todo.dapp.org',
  //       icons: [
  //         'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
  //       ],
  //     ),
  //   );
  //
  //   // Subscribe to events
  //   connector.on('connect', (session) => print(session));
  //   connector.on('session_update', (payload) => print(payload));
  //   connector.on('disconnect', (session) => print(session));
  //
  //   // Create a new session
  //   if (!connector.connected) {
  //     final session = await connector.createSession(
  //       chainId: 4160,
  //       onDisplayUri: (uri) {
  //         debugPrint(uri);
  //         _walletConnectUri = uri;
  //         // AppMehtods.openUrl(uri); //call the launchUrl(uri) method  TODO
  //       },
  //     );
  //   }
  // }
  //
  Future<void> initContract() async {
    String abiStringFile = await rootBundle.loadString("smartcontract/build/contracts/TodoContract.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    // // _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);   //local ganache
    _contractAddress = jsonAbi["networks"][_chainId.toString()]["address"];
    debugPrint("abi: $_abiCode, contractAddress: $_contractAddress");
    _contract = Contract(_contractAddress, _abiCode, _signer);
    if (_contract == null) {
      debugPrint("contract init failed");
    }

    // Call `balanceOf`
    final tc = await _contract.call<BigInt>(
      'taskCount',
    );
    debugPrint("taskCount: $tc");
  }
  //
  // Future<void> getCredentials() async {
  //   _credentials = await EthPrivateKey.fromHex(_privateKey);
  //   // _credentials = await _client.credentialsFromPrivateKey(_privateKey);
  //
  //   _ownAddress = await _credentials.extractAddress();
  //   debugPrint("_ownAddress: $_ownAddress");
  //
  // }
  //
  // Future<void> getDeployedContract() async {
  //   _contract = DeployedContract(
  //       ContractAbi.fromJson(_abiCode, "TodoList"), _contractAddress);
  //   _taskCount = _contract.function("taskCount");
  //   _updateTask = _contract.function("updateTask");
  //   _createTask = _contract.function("createTask");
  //   _deleteTask = _contract.function("deleteTask");
  //   _toggleComplete = _contract.function("toggleComplete");
  //   _todos = _contract.function("todos");
  //
  //
  //   await getTodos();
  // }

  @override
  getTodos() async {
    debugPrint("gettodos");
    final tc = await _contract.call<BigInt>(
      'taskCount',
    );
    todos.clear();
    for (var i = 0; i < tc.toInt(); i++) {
      var temp = await _contract.call<List<dynamic>>('todos', [i]);
      debugPrint("$i, temp=$temp");
      // debugPrint("${temp[0]}, ${temp[1]}, ${temp[2]}");
      // debugPrint(temp[0].runtimeType.toString());
      // final j = int.parse(temp[0].toString());
      // debugPrint("$j");
      //
      // debugPrint(temp[1].runtimeType.toString());
      // debugPrint(temp[2].runtimeType.toString());
      if (temp[1] != "") {
        todos.add(
          Task(
            id: int.parse(temp[0].toString()),
            taskName: temp[1],
            isCompleted: temp[2]
          )
        );
      }
      else {
        debugPrint('i = $i, null found');
      }
    }
    // List totalTaskList = await _client
    //     .call(contract: _contract, function: _taskCount, params: []);
    //
    // BigInt totalTask = totalTaskList[0];
    // taskCount = totalTask.toInt();
    // todos.clear();
    // for (var i = 0; i < totalTask.toInt(); i++) {
    //   var temp = await _client.call(
    //       contract: _contract, function: _todos, params: [BigInt.from(i)]);
    //   if (temp[1] != "") {
    //     todos.add(
    //       Task(
    //         id: (temp[0] as BigInt).toInt(),
    //         taskName: temp[1],
    //         isCompleted: temp[2],
    //       ),
    //     );
    //   }
    //   else {
    //     print('i = $i, null found');
    //   }
    // }
    isLoading = false;
    todos = todos.reversed.toList();
    notifyListeners();
  }

  Future<bool> waitTransaction(String txHash) async {
  //   debugPrint("[waitTransaction] $txHash");
  //   for (int i = 0; i < 10; i++) {
  //     debugPrint("[waitTransaction] i=$i");
  //     TransactionReceipt receipt = await _client.getTransactionReceipt(txHash);
  //     debugPrint("receipt: ${receipt.toString()}");
  //     if (receipt != null && receipt.blockNumber.blockNum > 10) { //通过blockNum已经出来了，来判断已经被确认
  //       debugPrint("receipt: return ${receipt.status}");
  //       return receipt.status;
  //     }
  //     debugPrint("sleep 1 sec");
  //     await Future.delayed(const Duration(seconds: 1));//  sleep(const Duration(seconds: 1));
  //   }
    return false;
  }

  @override
  addTask(String taskNameData) async {
    isLoading = true;
    notifyListeners();
    // String txHash = await _client.sendTransaction(
    //   _credentials,
    //   Transaction.callContract(
    //     contract: _contract,
    //     function: _createTask,
    //     parameters: [taskNameData],
    //   ),
    //   chainId: _chainId
    // );
    // debugPrint("addTask: txId = $txHash");
    // await waitTransaction(txHash);
    // await getTodos();
    final tx = await _contract.send(
      'createTask',
      [taskNameData]
    );

    debugPrint("txHash: ${tx.hash}");
    final receipt = await tx.wait();
    debugPrint("receipt: $receipt");
    await getTodos();
  }

  @override
  updateTask(int id, String taskNameData) async {
    isLoading = true;
    notifyListeners();
    // String txHash = await _client.sendTransaction(
    //   _credentials,
    //   Transaction.callContract(
    //     contract: _contract,
    //     function: _updateTask,
    //     parameters: [BigInt.from(id), taskNameData],
    //   ),
    //   chainId: _chainId
    // );
    // await waitTransaction(txHash);
    final tx = await _contract.send(
      "updateTask",
      [id, taskNameData]
    );
    debugPrint("txHash: ${tx.hash}");
    final receipt = await tx.wait();
    debugPrint("receipt: $receipt");
    await getTodos();
  }

  @override
  deleteTask(int id) async {
    isLoading = true;
    notifyListeners();
    // String txHash = await _client.sendTransaction(
    //   _credentials,
    //   Transaction.callContract(
    //     contract: _contract,
    //     function: _deleteTask,
    //     parameters: [BigInt.from(id)],
    //   ),
    //   chainId: _chainId
    // );
    //
    // await waitTransaction(txHash);
    final tx = await _contract.send(
      'deleteTask',
      [id]
    );
    debugPrint("txHash: ${tx.hash}");
    final receipt = await tx.wait();
    debugPrint("receipt: $receipt");
    await getTodos();
  }

  toggleComplete(int id) async {
    isLoading = true;
    notifyListeners();
    // String txHash = await _client.sendTransaction(
    //   _credentials,
    //   Transaction.callContract(
    //     contract: _contract,
    //     function: _toggleComplete,
    //     parameters: [BigInt.from(id)],
    //   ),
    //   chainId: _chainId
    // );
    // await waitTransaction(txHash);
    final tx = await _contract.send(
      'toggleComplete',
      [id]
    );
    debugPrint("txHash: ${tx.hash}");
    final receipt = await tx.wait();
    debugPrint("receipt: $receipt");
    await getTodos();
  }

  testWalletConnect() async {
    debugPrint("testWalletConnect");
    // From RPC
    // final wc = WalletConnectProvider.fromRpc(
    //   {_chainId: 'https://data-seed-prebsc-2-s2.binance.org:8545/'},
    //   chainId: _chainId,
    //   network: 'binance',
    // );
    final wc = WalletConnectProvider.binance();

    await wc.connect();

    final web3provider = Web3Provider.fromWalletConnect(wc);
    debugPrint("gasPrice: ${await web3provider.getBlockNumber()}"); // 5000000000
    // wc.disconnect();
  }
}