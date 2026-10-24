/// Raised when the server rejects a transaction payload that conflicts with
/// existing state, e.g. adding an item whose name already exists.
/// Unlike a network failure this must not be queued for offline retry.
class TransactionConflictException implements Exception {
  final String message;

  const TransactionConflictException(this.message);

  @override
  String toString() => 'TransactionConflictException: $message';
}
