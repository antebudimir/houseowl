import 'package:houseowl/models/user.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction.dart';

class TransactionUserGetAll extends Transaction<List<User>> {
  TransactionUserGetAll({DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionUserGetAll");

  @override
  Future<List<User>> runLocal() async {
    return const [];
  }

  @override
  Future<List<User>?> runOnline() async {
    return ApiService.getInstance().getAllUsers();
  }
}
