import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;

  MongoService._internal();

  late final Db _db;
  bool _initialized = false;

  /// Inicializa la conexión leyendo la variable MONGODB_URI del .env
  Future<void> init() async {
    if (_initialized) return;
    final uri = dotenv.env['MONGODB_URI'];
    if (uri == null || uri.isEmpty) {
      throw Exception('MONGODB_URI no está definida en .env');
    }
    _db = await Db.create(uri);
    await _db.open();
    _initialized = true;
  }

  /// Obtiene una colección por su nombre.
  DbCollection collection(String name) {
    if (!_initialized) {
      throw Exception(
        'MongoService no está inicializado. Llama a init() primero.',
      );
    }
    return _db.collection(name);
  }

  /// Cierra la conexión.
  Future<void> dispose() async {
    if (_initialized) {
      await _db.close();
      _initialized = false;
    }
  }
}
