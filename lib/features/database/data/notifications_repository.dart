import 'package:mongo_dart/mongo_dart.dart';
import 'collections.dart';
import '../../notifications/domain/models/notification_models.dart';
import 'mongo_service.dart';

class NotificationsRepository {
  final DbCollection _collection = MongoService().collection(
    Collections.notifications,
  );

  Future<List<AppNotification>> getAll() async {
    final docs = await _collection.find().toList();
    return docs.map((doc) => AppNotification.fromMap(doc)).toList();
  }

  Future<void> insert(AppNotification notification) async {
    await _collection.insertOne(notification.toMap());
  }

  // Add more CRUD methods as needed.
}
