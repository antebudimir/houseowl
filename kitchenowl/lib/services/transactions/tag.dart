import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/tag.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/storage/mem_storage.dart';
import 'package:houseowl/services/transaction.dart';

class TransactionTagGetAll extends Transaction<Set<Tag>> {
  final Household household;

  TransactionTagGetAll({DateTime? timestamp, required this.household})
      : super.internal(timestamp ?? DateTime.now(), "TransactionTagGetAll");

  @override
  Future<Set<Tag>> runLocal() async {
    return await MemStorage.getInstance().readTags(household) ?? {};
  }

  @override
  Future<Set<Tag>?> runOnline() async {
    final tags = await ApiService.getInstance().getAllTags(household);
    if (tags != null) {
      MemStorage.getInstance().writeTags(household, tags);
    }

    return tags;
  }
}
