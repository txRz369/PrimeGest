import 'package:flutter/material.dart';
import '../main.dart';
import '../models.dart';
import '../repository.dart';
import 'widgets.dart';

class EquipasPage extends StatefulWidget {
  const EquipasPage({super.key});

  @override
  State<EquipasPage> createState() => _EquipasPageState();
}

class _EquipasPageState extends State<EquipasPage> {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Acesso restrito ao Administrador.')),
      );
    }
    final repo = app.repo;

    return AppScaffold(
      title: 'Equipas',
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _editarEquipaDialog(context, repo),
                icon: const Icon(Icons.add),
                label: const Text('Nova Equipa'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: repo.equipas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final eq = repo.equipas[i];
                  final ctb = repo.contabilistas
                      .where((c) => eq.contabilistaIds.contains(c.id))
                      .toList();
                  final emps = repo.empresas
                      .where((e) => eq.empresaIds.contains(e.id))
                      .toList();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  eq.nome,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarEquipaDialog(
                                  context,
                                  repo,
                                  original: eq,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _removerEquipa(context, repo, eq),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('Contabilistas:'),
                          Wrap(
                            spacing: 6,
                            children: ctb
                                .map(
                                  (c) => Chip(
                                    label: Text('${c.nome} (${c.nivel.label})'),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 6),
                          const Text('Empresas:'),
                          Wrap(
                            spacing: 6,
                            children: emps
                                .map(
                                  (e) =>
                                      Chip(label: Text('${e.nome} (${e.nif})')),
                                )
                                .toList(),
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

  void _removerEquipa(BuildContext context, Repository repo, Equipa eq) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover equipa'),
        content: Text('Tem a certeza que pretende remover "${eq.nome}"?'),
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
    if (ok == true) setState(() => repo.removeEquipa(eq.id));
  }

  void _editarEquipaDialog(
    BuildContext context,
    Repository repo, {
    Equipa? original,
  }) {
    final nome = TextEditingController(text: original?.nome ?? '');
    final selCont = <String>{...?(original?.contabilistaIds)};
    final selEmp = <String>{...?(original?.empresaIds)};

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(original == null ? 'Nova Equipa' : 'Editar Equipa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                decoration: const InputDecoration(labelText: 'Nome da Equipa'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Atribuir Contabilistas',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 6),
              _MultiSelectChips(
                options: repo.contabilistas
                    .map(
                      (c) =>
                          _Opt(id: c.id, label: '${c.nome} (${c.nivel.label})'),
                    )
                    .toList(),
                selected: selCont,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Atribuir Empresas',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 6),
              _MultiSelectChips(
                options: repo.empresas
                    .map((e) => _Opt(id: e.id, label: '${e.nome} (${e.nif})'))
                    .toList(),
                selected: selEmp,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (nome.text.trim().isEmpty) return;
              if (original == null) {
                final eq = repo.addEquipa(Equipa(nome: nome.text.trim()));
                for (final id in selCont) {
                  repo.assignContabilistaToEquipa(id, eq.id);
                }
                for (final id in selEmp) {
                  repo.assignEmpresaToEquipa(id, eq.id);
                }
              } else {
                repo.updateEquipa(original, nome: nome.text.trim());
                // reset assignments
                for (final c in repo.contabilistas) {
                  repo.unassignContabilistaFromEquipa(c.id, original.id);
                }
                for (final e in repo.empresas) {
                  repo.unassignEmpresaFromEquipa(e.id, original.id);
                }
                for (final id in selCont) {
                  repo.assignContabilistaToEquipa(id, original.id);
                }
                for (final id in selEmp) {
                  repo.assignEmpresaToEquipa(id, original.id);
                }
              }
              if (mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _Opt {
  final String id;
  final String label;
  _Opt({required this.id, required this.label});
}

class _MultiSelectChips extends StatefulWidget {
  final List<_Opt> options;
  final Set<String> selected;
  const _MultiSelectChips({required this.options, required this.selected});

  @override
  State<_MultiSelectChips> createState() => _MultiSelectChipsState();
}

class _MultiSelectChipsState extends State<_MultiSelectChips> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: widget.options
          .map(
            (o) => FilterChip(
              label: Text(o.label),
              selected: widget.selected.contains(o.id),
              onSelected: (v) => setState(() {
                if (v) {
                  widget.selected.add(o.id);
                } else {
                  widget.selected.remove(o.id);
                }
              }),
            ),
          )
          .toList(),
    );
  }
}
