import 'package:flutter/material.dart';
import '../models.dart';
import '../repository.dart';
import '../main.dart';

/// Drawer lateral com permissões
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showMonthBar;
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showMonthBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isAdmin = app.isAdmin;
    final user = app.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [if (showMonthBar) _MonthSelector(), const SizedBox(width: 8)],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                accountName: Text(
                  user?.isAdmin == true
                      ? 'Administrador'
                      : (user?.username ?? ''),
                ),
                accountEmail: Text(
                  user?.isAdmin == true
                      ? 'Acesso total'
                      : 'Acesso: Controlo Interno',
                ),
                currentAccountPicture: CircleAvatar(
                  child: Text(
                    user?.isAdmin == true
                        ? 'AD'
                        : (user?.username.substring(0, 1).toUpperCase() ?? 'U'),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('Controlo Interno'),
                onTap: () => _go(context, '/controlo'),
              ),
              if (isAdmin) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.apartment),
                  title: const Text('Empresas'),
                  onTap: () => _go(context, '/empresas'),
                ),
                ListTile(
                  leading: const Icon(Icons.people_alt),
                  title: const Text('Contabilistas'),
                  onTap: () => _go(context, '/contabilistas'),
                ),
                ListTile(
                  leading: const Icon(Icons.groups),
                  title: const Text('Equipas'),
                  onTap: () => _go(context, '/equipas'),
                ),
                ListTile(
                  leading: const Icon(Icons.task),
                  title: const Text('Tarefas'),
                  onTap: () => _go(context, '/tarefas'),
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () {
                  Navigator.of(context).pop();
                  app.logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ],
          ),
        ),
      ),
      body: body,
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacementNamed(route);
  }
}

/// Seletor de Mês/Ano para a AppBar
class _MonthSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final month = app.selectedMonth;
    final months = List.generate(12, (i) => i + 1);
    final years = List.generate(7, (i) => DateTime.now().year - 3 + i);

    return Row(
      children: [
        DropdownButton<int>(
          value: month.month,
          onChanged: (m) {
            if (m == null) return;
            app.setMonth(DateTime(month.year, m, 1));
          },
          items: months
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(m.toString().padLeft(2, '0')),
                ),
              )
              .toList(),
        ),
        const SizedBox(width: 6),
        DropdownButton<int>(
          value: month.year,
          onChanged: (y) {
            if (y == null) return;
            app.setMonth(DateTime(y, month.month, 1));
          },
          items: years
              .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
              .toList(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Chip simples de importância 0..5
class ImportanciaPill extends StatelessWidget {
  final int value;
  const ImportanciaPill(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final c = switch (value) {
      >= 4 => colors.errorContainer,
      3 => colors.tertiaryContainer,
      2 => colors.secondaryContainer,
      _ => colors.surfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.priority_high, size: 14),
          const SizedBox(width: 4),
          Text('Imp. $value/5'),
        ],
      ),
    );
  }
}

/// Editor compacto de empresa (formulário)
class EmpresaEditor extends StatefulWidget {
  final Empresa? original;
  final void Function(Empresa e) onSave;
  const EmpresaEditor({super.key, this.original, required this.onSave});

  @override
  State<EmpresaEditor> createState() => _EmpresaEditorState();
}

class _EmpresaEditorState extends State<EmpresaEditor> {
  final _form = GlobalKey<FormState>();
  late TextEditingController nif;
  late TextEditingController nome;
  int importancia = 3;
  Periodicidade periodicidade = Periodicidade.mensal;

  @override
  void initState() {
    super.initState();
    final o = widget.original;
    nif = TextEditingController(text: o?.nif ?? '');
    nome = TextEditingController(text: o?.nome ?? '');
    importancia = o?.importancia ?? 3;
    periodicidade = o?.periodicidade ?? Periodicidade.mensal;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nif,
            decoration: const InputDecoration(labelText: 'NIF'),
            validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
          ),
          TextFormField(
            controller: nome,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Periodicidade>(
                  decoration: const InputDecoration(labelText: 'Periodicidade'),
                  value: periodicidade,
                  onChanged: (p) =>
                      setState(() => periodicidade = p ?? Periodicidade.mensal),
                  items: Periodicidade.values
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Importância (0-5)',
                  ),
                  value: importancia,
                  onChanged: (i) => setState(() => importancia = i ?? 0),
                  items: List.generate(
                    6,
                    (i) => DropdownMenuItem(value: i, child: Text('$i')),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                if (_form.currentState?.validate() != true) return;
                final e = widget.original ??
                    Empresa(
                      nif: nif.text.trim(),
                      nome: nome.text.trim(),
                      periodicidade: periodicidade,
                      importancia: importancia,
                    );
                if (widget.original != null) {
                  e.nif = nif.text.trim();
                  e.nome = nome.text.trim();
                  e.periodicidade = periodicidade;
                  e.importancia = importancia;
                }
                widget.onSave(e);
              },
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialogo para atribuir tarefas a uma empresa
class AtribuirTarefasDialog extends StatefulWidget {
  final Repository repo;
  final Empresa empresa;
  const AtribuirTarefasDialog({
    super.key,
    required this.repo,
    required this.empresa,
  });

  @override
  State<AtribuirTarefasDialog> createState() => _AtribuirTarefasDialogState();
}

class _AtribuirTarefasDialogState extends State<AtribuirTarefasDialog> {
  late Set<String> selecionadas;

  @override
  void initState() {
    super.initState();
    selecionadas = {...widget.empresa.tarefaIds};
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.repo.tarefas.toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    return AlertDialog(
      title: Text('Tarefas de ${widget.empresa.nome}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 420),
        child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (_, i) {
            final t = tasks[i];
            return CheckboxListTile(
              value: selecionadas.contains(t.id),
              onChanged: (v) => setState(() {
                if (v == true) {
                  selecionadas.add(t.id);
                } else {
                  selecionadas.remove(t.id);
                }
              }),
              title: Text(t.nome),
              subtitle: t.descricao == null ? null : Text(t.descricao!),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            widget.repo.setEmpresaTarefas(widget.empresa.id, selecionadas);
            Navigator.pop(context, true);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
