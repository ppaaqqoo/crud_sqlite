import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(SqliteApp());
}

class SqliteApp extends StatefulWidget {
  const SqliteApp({Key? key}) : super(key: key);

  @override
  _SqliteAppState createState() => _SqliteAppState();
}

class _SqliteAppState extends State<SqliteApp> {
  int? selectedId;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primaryColor: Color.fromRGBO(27, 57, 106, 1.0),
        ),
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(fontSize: 20.0, color: Colors.blueGrey),

              hintText: 'Ingresa una nueva tarea',
            ),
            style: TextStyle(
               color: Colors.white,
            ),
            cursorColor: Colors.white,
            
            controller: textController,
          ),
        ),
        body: Center(
          child: FutureBuilder<List<Tarea>>(
              future: DatabaseHelper.instance.getTareas(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Tarea>> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: Text('Cargando...'));
                }
                return snapshot.data!.isEmpty
                    ? Center(child: Text('Lista de tareas vacía.'))
                    : ListView(
                        children: snapshot.data!.map((tarea) {
                          return Center(
                            child: Card(
                              color: selectedId == tarea.id
                                  ? Colors.white70
                                  : Colors.white,
                              child: ListTile(
                                title: Text(tarea.tarea),
                                onTap: () {
                                  setState(() {
                                    
                                    if (selectedId == null) {
                                      textController.text = tarea.tarea;
                                      textController.selection = TextSelection.fromPosition(TextPosition(offset: textController.text.length));
                                      selectedId = tarea.id;
                                    } else {
                                      textController.text = '';
                                      selectedId = null;
                                    }
                                  });
                                },
                                onLongPress: () {
                                  setState(() {
                                    DatabaseHelper.instance.borrarTarea(tarea.id!, textController);
                                  });
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
              }),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(textController.text == "" ? Icons.save : Icons.edit),
          backgroundColor: textController.text == "" ? Colors.green : Colors.blue,
          onPressed: () async {
            selectedId != null
                ? await DatabaseHelper.instance.actualizarTarea(
                    Tarea(id: selectedId, tarea: textController.text),
                  )
                : await DatabaseHelper.instance.agregarTarea(
                    Tarea(tarea: textController.text),
                  );
            setState(() {
              textController.clear();
              selectedId = null;
            });
          },
        ),
      ),
    );
  }
}

class Tarea {
  final int? id;
  final String tarea;

  Tarea({this.id, required this.tarea});

  factory Tarea.fromMap(Map<String, dynamic> json) => new Tarea(
        id: json['id'],
        tarea: json['tarea'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tarea': tarea,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'tareas.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tareas(
          id INTEGER PRIMARY KEY,
          tarea TEXT
      )
      ''');
  }

  Future<List<Tarea>> getTareas() async {
    Database db = await instance.database;
    var tareas = await db.query('tareas', orderBy: 'tarea');
    List<Tarea> listaTareas = tareas.isNotEmpty
        ? tareas.map((c) => Tarea.fromMap(c)).toList()
        : [];
    return listaTareas;
  }

  Future<int> agregarTarea(Tarea tarea) async {
    Database db = await instance.database;
    return await db.insert('tareas', tarea.toMap());
  }

  Future<int> borrarTarea(int id, TextEditingController textController) async {
    Database db = await instance.database;
    textController.text = "";
    return await db.delete('tareas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> actualizarTarea(Tarea tarea) async {
    Database db = await instance.database;
    return await db.update('tareas', tarea.toMap(),
        where: "id = ?", whereArgs: [tarea.id]);
  }
}