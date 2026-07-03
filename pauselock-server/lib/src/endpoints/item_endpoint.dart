import 'package:pauselock_server/src/generated/protocol.dart';
import 'package:pauselock_server/src/services/deadlock_api_service.dart';
import 'package:serverpod/serverpod.dart';

class ItemEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<List<ItemData>> getAllItems(Session session) async {
    final service = DeadlockApiService();
    return service.getItems();
  }

  Future<List<ItemData>> getItemsBySlotType(Session session,
      {required String slotType}) async {
    final service = DeadlockApiService();
    return service.getItemsBySlotType(slotType);
  }

  Future<List<ItemData>> getItemsByTier(Session session,
      {required int tier}) async {
    final service = DeadlockApiService();
    return service.getItemsByTier(tier);
  }

  Future<ItemData?> getItemById(Session session,
      {required int itemId}) async {
    final service = DeadlockApiService();
    return service.getItemById(itemId);
  }
}
