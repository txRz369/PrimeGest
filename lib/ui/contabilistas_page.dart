import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import '../main.dart';
import '../models.dart';
import '../repository.dart';
import '../supabase_config.dart';
import 'widgets.dart';
import 'package:file_picker/file_picker.dart';

class ContabilistasPage extends StatefulWidget {
  const ContabilistasPage({super.key});

  @override
  State<ContabilistasPage> createState() => _ContabilistasPageState();
}

class _ContabilistasPageState extends State<ContabilistasPage> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Acesso restrito ao Administrador.')),
      );
    }
    final repo = app.repo;
    final list = repo.contabilistas
        .where(
          (c) =>
              c.nome.toLowerCase().contains(q.toLowerCase()) ||
              c.username.toLowerCase().contains(q.toLowerCase()),
        )
        .toList();

    return AppScaffold(
      title: 'Contabilistas',
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Pesquisar por nome/utilizador',
                    ),
                    onChanged: (v) => setState(() => q = v),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _editarDialog(context, repo),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Contabilista'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = list[i];

                  ImageProvider? img;
                  if (c.fotoUrl != null && c.fotoUrl!.isNotEmpty) {
                    img = NetworkImage(c.fotoUrl!);
                  }

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: img,
                        child:
                            img == null ? Text(c.nome.substring(0, 1)) : null,
                      ),
                      title: Text('${c.nome} • ${c.nivel.label}'),
                      subtitle: Text(
                        '${c.username} • Nasc. ${c.nascimento.day.toString().padLeft(2, '0')}/${c.nascimento.month.toString().padLeft(2, '0')}/${c.nascimento.year}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _editarDialog(context, repo, original: c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _remover(context, repo, c),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _remover(BuildContext context, Repository repo, Contabilista c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover contabilista'),
        content: Text('Tem a certeza que pretende remover "${c.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => repo.removeContabilista(c.id));
  }

  void _editarDialog(
    BuildContext context,
    Repository repo, {
    Contabilista? original,
  }) {
    final nome = TextEditingController(text: original?.nome ?? '');
    final username = TextEditingController(text: original?.username ?? '');
    DateTime nasc = original?.nascimento ?? DateTime(1990, 1, 1);
    NivelProf nivel = original?.nivel ?? NivelProf.junior;

    Uint8List? fotoBytes;
    String? fotoFilename;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          ImageProvider? img;
          if (fotoBytes != null) {
            img = MemoryImage(fotoBytes!);
          } else if (original?.fotoUrl != null) {
            img = NetworkImage(original!.fotoUrl!);
          }

          return AlertDialog(
            title: Text(
                original == null ? 'Novo Contabilista' : 'Editar Contabilista'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: img,
                        child: img == null ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text('Importar foto'),
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (res != null && res.files.single.bytes != null) {
                            setStateDialog(() {
                              fotoBytes = res.files.single.bytes!;
                              fotoFilename = res.files.single.name;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nome,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: username,
                    decoration: const InputDecoration(labelText: 'Utilizador'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<NivelProf>(
                          value: nivel,
                          onChanged: (v) => nivel = v ?? nivel,
                          items: NivelProf.values
                              .map(
                                (n) => DropdownMenuItem(
                                  value: n,
                                  child: Text(n.label),
                                ),
                              )
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: 'Nível Profissional',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cake),
                          label: Text(
                            'Nascimento: ${nasc.day.toString().padLeft(2, '0')}/${nasc.month.toString().padLeft(2, '0')}/${nasc.year}',
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: nasc,
                              firstDate: DateTime(1950),
                              lastDate:
                                  DateTime(DateTime.now().year - 18, 12, 31),
                            );
                            if (picked != null) {
                              nasc = picked;
                              setStateDialog(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              FilledButton(
                onPressed: () async {
                  if (nome.text.trim().isEmpty || username.text.trim().isEmpty)
                    return;

                  String? fotoUrl = original?.fotoUrl;
                  if (fotoBytes != null) {
                    final ext = (fotoFilename ?? 'avatar.jpg').split('.').last;
                    final path = 'avatars/${makeId('avatar')}.$ext';
                    fotoUrl = await Supa.uploadImageBytes(
                      bucket: 'avatars',
                      path: path,
                      bytes: fotoBytes!,
                      contentType: lookupMimeType(path),
                    );
                  }

                  if (original == null) {
                    repo.addContabilista(
                      Contabilista(
                        nome: nome.text.trim(),
                        nascimento: nasc,
                        nivel: nivel,
                        fotoUrl: fotoUrl,
                        username: username.text.trim(),
                      ),
                    );
                  } else {
                    repo.updateContabilista(
                      original,
                      nome: nome.text.trim(),
                      nascimento: nasc,
                      nivel: nivel,
                      fotoUrl: fotoUrl,
                      username: username.text.trim(),
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
