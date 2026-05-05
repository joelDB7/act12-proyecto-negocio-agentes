import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserCrudScreen extends StatefulWidget {
  const UserCrudScreen({super.key});

  @override
  State<UserCrudScreen> createState() => _UserCrudScreenState();
}

class _UserCrudScreenState extends State<UserCrudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _editing = false;
  String? _docId;

  final _db = FirebaseFirestore.instance;

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _editing = true);

    final data = {
      'nombre': _nameCtrl.text.trim(),
      'apellido': _apellidoCtrl.text.trim(),
      'edad': int.tryParse(_edadCtrl.text.trim()) ?? 0,
      'telefono': _phoneCtrl.text.trim(),
    };

    try {
      if (_docId == null) {
        await _db.collection('usuarios').add(data);
      } else {
        await _db.collection('usuarios').doc(_docId).update({
          ...data,
          'activo': FieldValue.delete(),
          'creadoEn': FieldValue.delete(),
        });
      }
      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _editing = false);
    }
  }

  void _editUser(DocumentSnapshot doc) {
    _docId = doc.id;
    _nameCtrl.text = doc['nombre'] ?? '';
    _apellidoCtrl.text = doc['apellido'] ?? '';
    _edadCtrl.text = (doc['edad'] ?? 0).toString();
    _phoneCtrl.text = doc['telefono'] ?? '';
    setState(() => _editing = true);
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(title: const Text('Eliminar'), content: const Text('¿Seguro que deseas eliminar este usuario?'), actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
      ]),
    );
    if (confirm == true) {
      await _db.collection('usuarios').doc(id).delete();
    }
  }

  void _clearForm() {
    _nameCtrl.clear();
    _apellidoCtrl.clear();
    _edadCtrl.clear();
    _phoneCtrl.clear();
    _docId = null;
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD Usuarios')),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _apellidoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Apellido',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _edadCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Edad',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return 'Requerido';
                            final num = int.tryParse(v);
                            if (num == null || num <= 0) return 'Edad inválida';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_editing ? Icons.save : Icons.add),
                        onPressed: _saveUser,
                      ),
                      if (_editing) IconButton(icon: const Icon(Icons.clear), onPressed: _clearForm),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('usuarios').orderBy('nombre').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No hay usuarios registrados'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: Colors.white,
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text('${data['nombre'] ?? 'Sin nombre'} ${data['apellido'] ?? ''}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edad: ${data['edad'] ?? 0}'),
                            Text('Teléfono: ${data['telefono'] ?? 'Sin teléfono'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _editUser(doc)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteUser(doc.id)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}