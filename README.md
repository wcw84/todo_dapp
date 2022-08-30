# todo_dapp

该dapp是这样一个demo：
- 基于flutter框架开发，实现了跨web、ios和android等多个终端
- 支持evm兼容链上数据交互，支持内置钱包，也支持调用外部钱包，包括浏览器上metamask插件和wallet connect协议
- 使用了truffle来创建管理智能合约

## Getting Started

该项目的搭建过程也是个学习过程，学习过程参考了：
- [Create a To-Do dApp with Flutter](https://learn.figment.io/tutorials/create-a-todo-dapp-with-flutter) 本项目是在该教程的基础上演进而来
- [flutter_web3插件](https://pub.dev/packages/flutter_web3) 插件实现了PC浏览器上调用外部Metamask和wallet connect协议的支持，比较遗憾的是flutter_web3不支持native环境. [辅助参考](https://medium.com/@flutterguide/how-to-connect-your-flutter-web-app-with-metamask-web3-tutorial-f60b7d53299)
- [walletconnect_dart插件](https://pub.dev/packages/walletconnect_dart) 实现了Native环境下通过wallet connect协议实现调用手机上的Metamask，或者扫码连接授权的功能。但该插件的提供功能不够丰富，再配合[web3dart插件](https://pub.dev/packages/web3dart) 可以更好的完成对智能合约的交互。
- [web3dart插件](https://pub.dev/packages/web3dart) 对web3js的功能全面兼容，也支持web和native，包括本地钱包等，但比较遗憾的未封装对外部钱包的调用。

