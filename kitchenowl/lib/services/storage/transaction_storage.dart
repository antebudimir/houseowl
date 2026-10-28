import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:houseowl/services/transaction.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;

class TransactionStorage {
  static TransactionStorage? _instance;

  TransactionStorage._internal();
  static TransactionStorage getInstance() {
    _instance ??= TransactionStorage._internal();

    return _instance!;
  }

  Future<String> get _localPath async {
    return pathProvider
        .getApplicationSupportDirectory()
        .then((dir) => dir.path);
  }

  Future<File> get _localFile async {
    final path = await _localPath;

    return File('$path/transactions.json');
  }

  Future<List<Transaction>> readTransactions() async {
    if (!kIsWeb) {
      try {
        final file = await _localFile;
        final String content = await file.readAsString();

        return List<Transaction>.from(
          json.decode(content).map((e) => Transaction.fromJson(e)),
        );
      } catch (_) {}
    }

    return [];
  }

  Future<void> clearTransactions() async {
    if (!kIsWeb) {
      try {
        final file = await _localFile;
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Writes the queue atomically (temp file + rename): the app being killed
  /// mid-write must never leave a truncated queue behind, which
  /// [readTransactions] would silently treat as an empty one.
  Future<void> setTransaction(List<Transaction> transactions) async {
    if (!kIsWeb) {
      final file = await _localFile;
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(
        json.encode(transactions.map((t) => t.toJson()).toList()),
        flush: true,
      );
      await tmp.rename(file.path);
    }
  }

  Future<void> addTransaction(Transaction t) async {
    if (!kIsWeb) {
      final transactions = (await readTransactions());
      transactions.add(t);
      await setTransaction(transactions);
    }
  }
}
