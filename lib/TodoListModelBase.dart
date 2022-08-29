
import 'package:todo_dapp/Task.dart';

abstract class TodoListModelBase  {
  List<Task> todos = [];
  bool isLoading = true;
  int taskCount = 0;
  bool get isConnected;

  Future<void> callExternalWallet() ;
  // Future<void> test() ;
  Future<void> disConnectWallet();
  Future<void> connectWallet();

  getTodos();
  deleteTask(int id);
  toggleComplete(int id);
  updateTask(int id, String taskNameData);
  addTask(String taskNameData);

}
