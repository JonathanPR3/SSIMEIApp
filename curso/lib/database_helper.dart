import 'package:sqflite/sqflite.dart';  // Para Android
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  // Crear base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;

    // Si la base de datos no existe, la creamos
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar base de datos
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            correo TEXT UNIQUE,
            contrasena TEXT,
            tutorial_completado INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // Función para insertar un nuevo usuario
  Future<void> insertarUsuario(Map<String, dynamic> usuario) async {
    final db = await database;
    await db.insert(
      'usuarios',
      usuario,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Función para obtener un usuario por correo
  Future<Map<String, dynamic>?> obtenerUsuario(String correo) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correo],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Función para actualizar el estado del tutorial
  Future<void> actualizarTutorialPorCorreo(String correo, int estado) async {
    final db = await database;
    await db.update(
      'usuarios',
      {'tutorial_completado': estado},
      where: 'correo = ?',
      whereArgs: [correo],
    );
  }


}
