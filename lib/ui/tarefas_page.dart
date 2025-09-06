import 'package:flutter/material.dart';
import '../main.dart';
import '../models.dart';
import '../repository.dart';
import 'widgets.dart';

class TarefasPage extends StatefulWidget {
  const TarefasPage({super.key});

  @override
  State<TarefasPage> createState() => _TarefasPageState();
}

class _TarefasPageState extends State<TarefasPage> {
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
    final list = repo.tarefas
        .where((t) => t.nome.toLowerCase().contains(q.toLowerCase()))
        .toList();

    return AppScaffold(
      title: 'Tarefas',
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
                      hintText: 'Pesquisar por nome',
                    ),
                    onChanged: (v) => setState(() => q = v),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _editarTarefaDialog(context, repo),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova Tarefa'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final t = list[i];
                  return Card(
                    child: ListTile(
                      title: Text(t.nome),
                      subtitle: t.descricao == null ? null : Text(t.descricao!),
                      leading: Icon(
                        t.ativa
                            ? Icons.check_circle
                            : Icons.pause_circle_filled,
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _editarTarefaDialog(context, repo, original: t),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removerTarefa(context, repo, t),
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

  void _removerTarefa(BuildContext context, Repository repo, Tarefa t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover tarefa'),
        content: Text(
          'Tem a certeza que pretende remover "${t.nome}"? Será removida das empresas e históricos.',
        ),
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
    if (ok == true) setState(() => repo.removeTarefa(t.id));
  }

  void _editarTarefaDialog(
    BuildContext context,
    Repository repo, {
    Tarefa? original,
  }) {
    final nome = TextEditingController(text: original?.nome ?? '');
    final desc = TextEditingController(text: original?.descricao ?? '');
    bool ativa = original?.ativa ?? true;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              original == null ? 'Nova Tarefa' : 'Editar Tarefa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nome,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: desc,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: ativa,
              onChanged: (v) => ativa = v,
              title: const Text('Ativa'),
              subtitle: const Text(
                'Tarefas inativas não aparecem no Controlo Interno.',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  if (nome.text.trim().isEmpty) return;
                  if (original == null) {
                    repo.addTarefa(
                      Tarefa(
                        nome: nome.text.trim(),
                        descricao:
                            desc.text.trim().isEmpty ? null : desc.text.trim(),
                        ativa: ativa,
                      ),
                    );
                  } else {
                    repo.updateTarefa(
                      original,
                      nome: nome.text.trim(),
                      descricao:
                          desc.text.trim().isEmpty ? null : desc.text.trim(),
                      ativa: ativa,
                    );
                  }
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
