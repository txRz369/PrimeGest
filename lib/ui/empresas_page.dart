import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import '../main.dart';
import '../models.dart';
import '../repository.dart';
import '../supabase_config.dart';
import 'widgets.dart';

class EmpresasPage extends StatefulWidget {
  const EmpresasPage({super.key});

  @override
  State<EmpresasPage> createState() => _EmpresasPageState();
}

class _EmpresasPageState extends State<EmpresasPage> {
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
    final list = repo.empresas
        .where(
          (e) =>
              e.nome.toLowerCase().contains(q.toLowerCase()) ||
              e.nif.contains(q),
        )
        .toList();

    return AppScaffold(
      title: 'Empresas',
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
                      hintText: 'Pesquisar por nome/NIF',
                    ),
                    onChanged: (v) => setState(() => q = v),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _editarEmpresaDialog(context, repo),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova Empresa'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final e = list[i];

                  ImageProvider? logo;
                  if (e.logoUrl != null && e.logoUrl!.isNotEmpty) {
                    logo = NetworkImage(e.logoUrl!);
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: logo,
                                child: logo == null
                                    ? const Icon(Icons.apartment)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.nome,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.expand_more),
                                onPressed: () {
                                  // apenas efeito visual (card é fixo)
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${e.nif} • ${e.periodicidade.label} • Imp. ${e.importancia}',
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.fact_check),
                                label: const Text('Atribuir Tarefas'),
                                onPressed: () async {
                                  final changed = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AtribuirTarefasDialog(
                                      repo: repo,
                                      empresa: e,
                                    ),
                                  );
                                  if (changed == true && mounted)
                                    setState(() {});
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarEmpresaDialog(
                                  context,
                                  repo,
                                  original: e,
                                ),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _removerEmpresa(context, repo, e),
                                tooltip: 'Remover',
                              ),
                            ],
                          ),
                          if (e.tarefaIds.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text('Sem tarefas atribuídas.'),
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

  void _removerEmpresa(BuildContext context, Repository repo, Empresa e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover empresa'),
        content: Text('Tem a certeza que pretende remover "${e.nome}"?'),
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
    if (ok == true) {
      setState(() => repo.removeEmpresa(e.id));
    }
  }

  void _editarEmpresaDialog(
    BuildContext context,
    Repository repo, {
    Empresa? original,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: EmpresaEditor(
          original: original,
          repo: repo,
          onSave: (e, tarefasSel, logoBytes, logoName) async {
            String? logoUrl;
            if (logoBytes != null) {
              final ext = (logoName ?? 'logo.png').split('.').last;
              final path = 'logos/${makeId('logo')}.$ext';
              logoUrl = await Supa.uploadImageBytes(
                bucket: 'logos',
                path: path,
                bytes: logoBytes,
                contentType: lookupMimeType(path),
              );
              e.logoUrl = logoUrl ?? e.logoUrl;
            }
            if (original == null) {
              setState(() => repo.addEmpresa(e, tarefaIds: tarefasSel));
            } else {
              setState(() {
                repo.updateEmpresa(
                  original,
                  nif: e.nif,
                  nome: e.nome,
                  periodicidade: e.periodicidade,
                  importancia: e.importancia,
                  logoUrl: logoUrl,
                );
                repo.setEmpresaTarefas(original.id, tarefasSel);
              });
            }
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
