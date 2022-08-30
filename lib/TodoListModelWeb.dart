import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Provider _provider;
  Signer _signer;
  //local ganache
  // final String _rpcUrl = "http://127.0.0.1:7545";
  // final String _wsUrl = "ws://127.0.0.1:7545/";

  //bsc testnet
  final String _rpcUrl = 'https://data-seed-prebsc-2-s2.binance.org:8545/';
  // final String _wsUrl = "";

  final int _chainId = 97; //bsc testnet
  Contract _contract;

  TodoListModel() {
    init();
  }

  @override
  Future<void> disConnectWallet() async {
  }

  @override
  Future<void> connectWallet() async {
    // await _connectWalletByInternalWallet();
    await _connectWalletByMetamask();
    // await _connectWalletByWalletConnect();

    // some test
    debugPrint("balance: ${await _signer.getBalance()}"); // 315752957360231815
    // Get account sent transaction count (not contract call)
    debugPrint("getTransactionCount: ${await _signer.getTransactionCount(BlockTag.latest)}"); // 1
  }

  Future<void> _connectWalletByMetamask() async {
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
        isConnected = true;
        _ownAddress = accs[0]; // [foo,bar]
        debugPrint("account address: $_ownAddress");

        _provider = Web3Provider.fromEthereum(ethereum);

        int bn = await _provider.getBlockNumber();  //9261427
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
          debugPrint("onAccountsChanged: $accounts"); // ['0xbar']
        });

        // Subscribe to `message` event, need to convert JS message object to dart object.
        ethereum.on('message', (message) {
          debugPrint("on message: ${dartify(message)}"); // baz
        });

      } on EthereumUserRejected {
        debugPrint('User rejected the modal');
      }
    }

    // Get signer from provider
    _signer = (_provider as Web3Provider).getSigner();
  }

  Future<void> _connectWalletByInternalWallet() async {
    final wallet = Wallet("865b87c8ef6e108fb3f700b99cd68e5d57c408d6114851780dbc580be595c0eb");
    _provider = JsonRpcProvider(_rpcUrl);
    _signer = wallet.connect(_provider);
  }

  Future<void> _connectWalletByWalletConnect() async {
    // From RPC
    final wc = WalletConnectProvider.fromRpc(
      {_chainId: _rpcUrl},
      chainId: _chainId,
      network: 'bsc-testnet',
    );
    // final wc = WalletConnectProvider.binance();
    // Web3Provider web3provider;
    await wc.connect();
    if (wc.connected) {
      _provider = Web3Provider.fromWalletConnect(wc);
    }

    // Get signer from provider
    _signer = (_provider as Web3Provider).getSigner();
  }

  Future<void> init() async {
    debugPrint("TodoListModel_metamask init");

    await connectWallet();
    await _initContract();
    await getTodos();
    // await testWalletConnect();
  }

  Future<void> _initContract() async {
    String abiStringFile = await rootBundle.loadString("smartcontract/build/contracts/TodoContract.json");
    var jsonAbi = jsonDecode(abiStringFile);
    var abiCode = jsonEncode(jsonAbi["abi"]);
    // contractAddress = EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);   //local ganache
    var contractAddress = jsonAbi["networks"][_chainId.toString()]["address"];
    // debugPrint("abi: $abiCode, contractAddress: $_contractAddress");
    _contract = Contract(contractAddress, abiCode, _signer);
    if (_contract == null) {
      debugPrint("contract init failed");
    }
  }

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

    isLoading = false;
    todos = todos.reversed.toList();
    notifyListeners();
  }

  @override
  addTask(String taskNameData) async {
    isLoading = true;
    notifyListeners();
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
    final tx = await _contract.send(
      'deleteTask',
      [id]
    );
    debugPrint("txHash: ${tx.hash}");
    final receipt = await tx.wait();
    debugPrint("receipt: $receipt");
    await getTodos();
  }

  @override
  toggleComplete(int id) async {
    isLoading = true;
    notifyListeners();
    final tx = await _contract.send(
      'toggleComplete',
      [id]
    );
    debugPrint("txHash: ${tx.hash}");
    final receipt = await tx.wait();
    debugPrint("receipt: $receipt");
    await getTodos();
  }

  test() async {
    debugPrint("testWalletConnect");
    // From RPC
    final wc = WalletConnectProvider.fromRpc(
      {_chainId: 'https://data-seed-prebsc-2-s2.binance.org:8545/'},
      chainId: _chainId,
      network: 'bsc-testnet',
    );
    // final wc = WalletConnectProvider.binance();
    // Web3Provider web3provider;
    await wc.connect();
    if (wc.connected) {
      _provider = Web3Provider.fromWalletConnect(wc);
    }
    debugPrint("gasPrice: ${await _provider.getBlockNumber()}"); // 5000000000
    // wc.disconnect();
  }
}