import 'package:flutter/material.dart';
import '../models.dart';
import '../repository.dart';
import '../main.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

/// Scaffold com Drawer; se [title] for vazio, mostra o logotipo no AppBar.
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
        title: title.isEmpty
            ? Image.asset(
                'assets/cascata.png',
                height: 28,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
            : Text(title),
        actions: [
          if (showMonthBar) _MonthSelector(),
          const SizedBox(width: 8),
        ],
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
                  backgroundColor: Colors.transparent,
                  backgroundImage: const AssetImage('assets/cascata.png'),
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

/// Seletor de mês/ano num botão com DatePicker
class _MonthSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final month = app.selectedMonth;
    String label() => '${month.year}/${month.month.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month),
        label: Text(label()),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
        ),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: month,
            firstDate: DateTime(DateTime.now().year - 3, 1),
            lastDate: DateTime(DateTime.now().year + 3, 12, 31),
            helpText: 'Selecionar mês/ano',
          );
          if (picked != null) {
            app.setMonth(DateTime(picked.year, picked.month, 1));
          }
        },
      ),
    );
  }
}

/// Chip de importância (apenas número)
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
      _ => colors.surfaceContainerHighest,
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
          Text('Imp. $value'),
        ],
      ),
    );
  }
}

/// ================= Editor de Empresa (Dialog) =================
class EmpresaEditor extends StatefulWidget {
  final Empresa? original;
  final Repository? repo;
  final void Function(
    Empresa e,
    Set<String> tarefaIds,
    Uint8List? logoBytes,
    String? logoFilename,
  ) onSave;

  const EmpresaEditor({
    super.key,
    this.original,
    required this.onSave,
    this.repo,
  });

  @override
  State<EmpresaEditor> createState() => _EmpresaEditorState();
}

class _EmpresaEditorState extends State<EmpresaEditor> {
  final _form = GlobalKey<FormState>();
  late TextEditingController nif;
  late TextEditingController nome;
  int importancia = 3;
  Periodicidade periodicidade = Periodicidade.mensal;

  Uint8List? logoBytes;
  String? logoFilename;

  late Set<String> selecionadas;

  @override
  void initState() {
    super.initState();
    final o = widget.original;
    nif = TextEditingController(text: o?.nif ?? '');
    nome = TextEditingController(text: o?.nome ?? '');
    importancia = o?.importancia ?? 3;
    periodicidade = o?.periodicidade ?? Periodicidade.mensal;
    selecionadas = {...(o?.tarefaIds ?? const <String>{})};
  }

  @override
  Widget build(BuildContext context) {
    final tarefas = (widget.repo?.tarefas ?? const <Tarefa>[]).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

    ImageProvider? logoImg;
    if (logoBytes != null) {
      logoImg = MemoryImage(logoBytes!);
    } else if (widget.original?.logoUrl != null) {
      logoImg = NetworkImage(widget.original!.logoUrl!);
    }

    final tarefasWidget = tarefas.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Atribuir tarefas',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 280, minHeight: 80),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tarefas.length,
                  itemBuilder: (_, i) {
                    final t = tarefas[i];
                    return CheckboxListTile(
                      value: selecionadas.contains(t.id),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            selecionadas.add(t.id);
                          } else {
                            selecionadas.remove(t.id);
                          }
                        });
                      },
                      title: Text(t.nome),
                      subtitle: t.descricao == null ? null : Text(t.descricao!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: logoImg,
                    child: logoImg == null ? const Icon(Icons.image) : null,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Escolher logotipo'),
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (res != null && res.files.single.bytes != null) {
                        setState(() {
                          logoBytes = res.files.single.bytes!;
                          logoFilename = res.files.single.name;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nif,
                decoration: const InputDecoration(labelText: 'NIF'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: nome,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Periodicidade>(
                      decoration:
                          const InputDecoration(labelText: 'Periodicidade'),
                      initialValue: periodicidade,
                      onChanged: (p) => setState(
                          () => periodicidade = p ?? Periodicidade.mensal),
                      items: Periodicidade.values
                          .map((p) =>
                              DropdownMenuItem(value: p, child: Text(p.label)))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration:
                          const InputDecoration(labelText: 'Importância (0-5)'),
                      initialValue: importancia,
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
              tarefasWidget,
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
                      e
                        ..nif = nif.text.trim()
                        ..nome = nome.text.trim()
                        ..periodicidade = periodicidade
                        ..importancia = importancia;
                    }
                    widget.onSave(e, selecionadas, logoBytes, logoFilename);
                  },
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
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
      content: tasks.isEmpty
          ? const SizedBox(
              width: 420,
              child: Text(
                  'Não existem tarefas criadas. Vá a "Tarefas" e crie pelo menos uma.'),
            )
          : SizedBox(
              width: 420,
              height: 420,
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (_, i) {
                    final t = tasks[i];
                    return CheckboxListTile(
                      value: selecionadas.contains(t.id),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            selecionadas.add(t.id);
                          } else {
                            selecionadas.remove(t.id);
                          }
                        });
                      },
                      title: Text(t.nome),
                      subtitle: t.descricao == null ? null : Text(t.descricao!),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
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
