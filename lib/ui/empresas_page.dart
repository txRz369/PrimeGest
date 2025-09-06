import 'package:flutter/material.dart';
import '../main.dart';
import '../models.dart';
import '../repository.dart';
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
                  return Card(
                    child: ListTile(
                      title: Text(e.nome),
                      subtitle: Text(
                        '${e.nif} • ${e.periodicidade.label} • Imp. ${e.importancia}/5',
                      ),
                      trailing: Wrap(
                        spacing: 8,
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
                              if (changed == true && mounted) setState(() {});
                            },
                          ),
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
                            onPressed: () => _removerEmpresa(context, repo, e),
                            tooltip: 'Remover',
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: EmpresaEditor(
          original: original,
          onSave: (e) {
            if (original == null) {
              setState(() => repo.addEmpresa(e));
            } else {
              setState(
                () => repo.updateEmpresa(
                  original,
                  nif: e.nif,
                  nome: e.nome,
                  periodicidade: e.periodicidade,
                  importancia: e.importancia,
                ),
              );
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
