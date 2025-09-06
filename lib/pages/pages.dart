// lib/pages.dart
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'models.dart';
import 'widgets.dart';

/// ============ LOGIN ============
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController(text: 'admin');
  bool _obscure = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('App Controlo de Tarefas',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(labelText: 'Utilizador'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  FilledButton(
                    onPressed: () {
                      final msg = state.auth.login(
                        _userCtrl.text.trim(),
                        _passCtrl.text.trim(),
                      );
                      if (msg != null) {
                        setState(() => _error = msg);
                      } else {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                    child: const Text('Entrar'),
                  ),
                  const SizedBox(height: 8),
                  const Text('Admin: admin / admin\nExemplo contabilista: c1 / 1234'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============ CONTROLO INTERNO ============
class InternalControlPage extends StatelessWidget {
  const InternalControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final companies = state.visibleCompanies().toList()
      ..sort((a, b) => b.importancia.compareTo(a.importancia));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              MonthYearPicker(
                year: state.selectedYear,
                month: state.selectedMonth,
                onChanged: (y, m) => state.setMonthYear(y, m),
              ),
              const Spacer(),
              FilterChip(
                label: Text('Empresas: ${companies.length}'),
                onSelected: (_) {},
              ),
            ],
          ),
        ),
        const Divider(height: 0),
        Expanded(
          child: ListView.builder(
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final c = companies[index];
              final List<Task> cTasks =
                  c.taskIds.map((id) => state.tasks[id]).whereType<Task>().toList();
              final done = state.doneFor(c.id);
              final total = cTasks.length;
              final falta = total - done.length;

              return ExpansionTile(
                key: ValueKey(c.id),
                title: Text(c.nome),
                subtitle:
                    Text('${c.nif}  •  ${c.periodicidade.label}  •  Importância ${c.importancia}'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('Feitas ${done.length}/$total')),
                    if (falta > 0) Chip(label: Text('Faltam $falta')),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    child: TaskChecklist(
                      tasks: cTasks,
                      doneIds: done,
                      onToggle: (taskId) => state.toggleDone(c.id, taskId),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ============ EMPRESAS ============
class CompaniesPage extends StatelessWidget {
  const CompaniesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final list = state.companies.values.toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        label: const Text('Nova Empresa'),
        icon: const Icon(Icons.add_business),
      ),
      body: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, i) {
          final c = list[i];
          final totalTasks = c.taskIds.length;
          return ListTile(
            title: Text(c.nome),
            subtitle: Text(
                '${c.nif} • ${c.periodicidade.label} • Imp. ${c.importancia} • Tarefas: $totalTasks'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _openEditor(context, company: c)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context, c)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Company c) async {
    final state = AppStateScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar empresa'),
        content: Text('Tem a certeza que quer apagar "${c.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok == true) state.deleteCompany(c.id);
  }

  Future<void> _openEditor(BuildContext context, {Company? company}) async {
    final state = AppStateScope.of(context);
    final nifCtrl = TextEditingController(text: company?.nif ?? '');
    final nomeCtrl = TextEditingController(text: company?.nome ?? '');
    int importancia = company?.importancia ?? 3;
    Periodicidade periodicidade = company?.periodicidade ?? Periodicidade.mensal;

    // seleção de tarefas
    final allTasks = state.tasks.values.toList();
    final selected = <String>{...company?.taskIds ?? <String>{}>};

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setSt) {
        return AlertDialog(
          title: Text(company == null ? 'Nova Empresa' : 'Editar Empresa'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: nifCtrl, decoration: const InputDecoration(labelText: 'NIF')),
                  const SizedBox(height: 8),
                  TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Periodicidade>(
                    value: periodicidade,
                    onChanged: (v) => setSt(() => periodicidade = v ?? periodicidade),
                    items: Periodicidade.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                        .toList(),
                    decoration: const InputDecoration(labelText: 'Periodicidade'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Importância'),
                      Expanded(
                        child: Slider(
                          min: 0,
                          max: 5,
                          divisions: 5,
                          value: importancia.toDouble(),
                          onChanged: (v) => setSt(() => importancia = v.round()),
                          label: importancia.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Tarefas desta empresa', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final t in allTasks)
                          CheckboxListTile(
                            dense: true,
                            value: selected.contains(t.id),
                            onChanged: (_) => setSt(() {
                              if (!selected.add(t.id)) selected.remove(t.id);
                            }),
                            title: Text(t.nome),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (company == null) {
                  state.createCompany(
                    nif: nifCtrl.text.trim(),
                    nome: nomeCtrl.text.trim(),
                    periodicidade: periodicidade,
                    importancia: importancia,
                    taskIds: selected,
                  );
                } else {
                  state.updateCompany(
                    company,
                    nif: nifCtrl.text.trim(),
                    nome: nomeCtrl.text.trim(),
                    periodicidade: periodicidade,
                    importancia: importancia,
                    taskIds: selected,
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      }),
    );
  }
}

/// ============ CONTABILISTAS ============
class AccountantsPage extends StatelessWidget {
  const AccountantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final list = state.accountants.values.toList()..sort((a, b) => a.nome.compareTo(b.nome));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        label: const Text('Novo Contabilista'),
        icon: const Icon(Icons.person_add),
      ),
      body: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, i) {
          final a = list[i];
          return ListTile(
            leading: CircleAvatar(child: Text(a.nome.isNotEmpty ? a.nome[0] : '?')),
            title: Text(a.nome),
            subtitle: Text('${a.dataNascimento.toIso8601String().substring(0, 10)} • ${a.nivel.label}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _openEditor(context, accountant: a)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context, a)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Accountant a) async {
    final state = AppStateScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar contabilista'),
        content: Text('Tem a certeza que quer apagar "${a.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok == true) state.deleteAccountant(a.id);
  }

  Future<void> _openEditor(BuildContext context, {Accountant? accountant}) async {
    final state = AppStateScope.of(context);
    final nomeCtrl = TextEditingController(text: accountant?.nome ?? '');
    DateTime data = accountant?.dataNascimento ?? DateTime(1990, 1, 1);
    NivelProf nivel = accountant?.nivel ?? NivelProf.junior;
    final fotoCtrl = TextEditingController(text: accountant?.fotoUrl ?? '');

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setSt) {
        return AlertDialog(
          title: Text(accountant == null ? 'Novo Contabilista' : 'Editar Contabilista'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text('Data de nascimento: ${data.toIso8601String().substring(0, 10)}')),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: data,
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setSt(() => data = picked);
                        },
                        child: const Text('Escolher'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<NivelProf>(
                    value: nivel,
                    onChanged: (v) => setSt(() => nivel = v ?? nivel),
                    items: NivelProf.values
                        .map((n) => DropdownMenuItem(value: n, child: Text(n.label)))
                        .toList(),
                    decoration: const InputDecoration(labelText: 'Nível de Profissionalismo'),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: fotoCtrl, decoration: const InputDecoration(labelText: 'URL da foto (opcional)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (accountant == null) {
                  state.createAccountant(
                    nome: nomeCtrl.text.trim(),
                    dataNascimento: data,
                    nivel: nivel,
                    fotoUrl: fotoCtrl.text.trim().isEmpty ? null : fotoCtrl.text.trim(),
                  );
                } else {
                  state.updateAccountant(
                    accountant,
                    nome: nomeCtrl.text.trim(),
                    dataNascimento: data,
                    nivel: nivel,
                    fotoUrl: fotoCtrl.text.trim().isEmpty ? null : fotoCtrl.text.trim(),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      }),
    );
  }
}

/// ============ EQUIPAS ============
class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final list = state.teams.values.toList()..sort((a, b) => a.nome.compareTo(b.nome));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        label: const Text('Nova Equipa'),
        icon: const Icon(Icons.group_add),
      ),
      body: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, i) {
          final t = list[i];
          return ListTile(
            title: Text(t.nome),
            subtitle: Text('Membros: ${t.accountantIds.length} • Empresas: ${t.companyIds.length}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _openEditor(context, team: t)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context, t)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Team t) async {
    final state = AppStateScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar equipa'),
        content: Text('Tem a certeza que quer apagar "${t.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok == true) state.deleteTeam(t.id);
  }

  Future<void> _openEditor(BuildContext context, {Team? team}) async {
    final state = AppStateScope.of(context);
    final nomeCtrl = TextEditingController(text: team?.nome ?? '');
    final selectedAcc = <String>{...team?.accountantIds ?? <String>{}>};
    final selectedComp = <String>{...team?.companyIds ?? <String>{}>};

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setSt) {
        return AlertDialog(
          title: Text(team == null ? 'Nova Equipa' : 'Editar Equipa'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome da equipa')),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SelectBox(
                          title: 'Contabilistas',
                          options: [
                            for (final a in state.accountants.values) _Opt(id: a.id, label: a.nome),
                          ],
                          selected: selectedAcc,
                          onToggle: (id) => setSt(() {
                            if (!selectedAcc.add(id)) selectedAcc.remove(id);
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SelectBox(
                          title: 'Empresas',
                          options: [
                            for (final c in state.companies.values) _Opt(id: c.id, label: c.nome),
                          ],
                          selected: selectedComp,
                          onToggle: (id) => setSt(() {
                            if (!selectedComp.add(id)) selectedComp.remove(id);
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (team == null) {
                  final t = state.createTeam(nomeCtrl.text.trim());
                  state.updateTeam(t, accountantIds: selectedAcc, companyIds: selectedComp);
                } else {
                  state.updateTeam(team,
                      nome: nomeCtrl.text.trim(), accountantIds: selectedAcc, companyIds: selectedComp);
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      }),
    );
  }
}

class _Opt {
  final String id;
  final String label;
  _Opt({required this.id, required this.label});
}

class _SelectBox extends StatelessWidget {
  final String title;
  final List<_Opt> options;
  final Set<String> selected;
  final void Function(String id) onToggle;

  const _SelectBox({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final o in options)
                CheckboxListTile(
                  dense: true,
                  value: selected.contains(o.id),
                  onChanged: (_) => onToggle(o.id),
                  title: Text(o.label),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ============ TAREFAS ============
class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final list = state.tasks.values.toList()..sort((a, b) => a.nome.compareTo(b.nome));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        label: const Text('Nova Tarefa'),
        icon: const Icon(Icons.playlist_add),
      ),
      body: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, i) {
          final t = list[i];
          return ListTile(
            title: Text(t.nome),
            subtitle: t.descricao == null ? null : Text(t.descricao!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _openEditor(context, task: t)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context, t)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Task t) async {
    final state = AppStateScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar tarefa'),
        content: Text('Tem a certeza que quer apagar "${t.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok == true) state.deleteTask(t.id);
  }

  Future<void> _openEditor(BuildContext context, {Task? task}) async {
    final state = AppStateScope.of(context);
    final nomeCtrl = TextEditingController(text: task?.nome ?? '');
    final descCtrl = TextEditingController(text: task?.descricao ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task == null ? 'Nova Tarefa' : 'Editar Tarefa'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição (opcional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final nome = nomeCtrl.text.trim();
              final desc = descCtrl.text.trim();
              if (task == null) {
                state.createTask(nome, descricao: desc.isEmpty ? null : desc);
              } else {
                state.updateTask(task, nome: nome, descricao: desc.isEmpty ? null : desc);
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
