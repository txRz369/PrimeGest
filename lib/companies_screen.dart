import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'models.dart';
import 'widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});
  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  List<Company> companies = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    companies = await Supa.fetchCompanies();
    if (mounted) setState(() {});
  }

  Future<void> _newCompany() async {
    final res = await showDialog<_CompanyResult>(
      context: context,
      builder: (_) => const _CompanyDialog(),
    );
    if (res != null) {
      await Supa.createCompany(res.company, teamId: res.teamId);
      await _load();
    }
  }

  Future<void> _editCompany(Company c) async {
    final res = await showDialog<_CompanyResult>(
      context: context,
      builder: (_) => _CompanyDialog(existing: c),
    );
    if (res != null) {
      await Supa.updateCompany(res.company, teamId: res.teamId);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Empresas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: _newCompany,
                icon: const Icon(Icons.add),
                label: const Text('Nova Empresa'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: companies.isEmpty
                ? const Center(child: Text('Sem empresas.'))
                : ListView.separated(
                    itemCount: companies.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = companies[i];
                      return Card(
                        elevation: 0,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide.none,
                        ),
                        child: ListTile(
                          leading: AvatarOrLogo(url: c.logoUrl, label: c.name),
                          title: Text(c.name),
                          subtitle: Text(
                            '${c.nipc} • ${c.periodicidade.name.toUpperCase()} • Imp: ${c.importance}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editCompany(c),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompanyResult {
  final Company company;
  final String? teamId;
  _CompanyResult(this.company, this.teamId);
}

class _CompanyDialog extends StatefulWidget {
  final Company? existing;
  const _CompanyDialog({this.existing});

  @override
  State<_CompanyDialog> createState() => _CompanyDialogState();
}

class _CompanyDialogState extends State<_CompanyDialog> {
  final name = TextEditingController();
  final nipc = TextEditingController();
  String? logoUrl; // só via upload
  Periodicidade periodicidade = Periodicidade.mensal;
  double imp = 3;

  final picker = ImagePicker();

  List<String> taskKeys = defaultTaskKeys();
  Map<String, String?> respByKey = {};
  List<Accountant> accountants = [];
  List<Team> teams = [];
  String? selectedTeamId;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    accountants = await Supa.fetchAccountants();
    teams = await Supa.fetchTeams();

    if (widget.existing != null) {
      final c = widget.existing!;
      name.text = c.name;
      nipc.text = c.nipc;
      periodicidade = c.periodicidade;
      imp = c.importance.toDouble();
      logoUrl = c.logoUrl;
      taskKeys = [...c.taskKeys];
      respByKey = Map<String, String?>.from(c.taskResponsibleByKey);
      // tentar obter a equipa atual (se alguma) — opcional
      final teamLinks = await Supa.client
          .from('team_companies')
          .select('team_id')
          .eq('company_id', c.id);
      if (teamLinks is List && teamLinks.isNotEmpty) {
        selectedTeamId = teamLinks.first['team_id'] as String?;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _importarLogo() async {
    final XFile? x =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (x == null) return;
    final Uint8List bytes = await x.readAsBytes();
    final url = await Supa.uploadLogo(bytes, x.name);
    setState(() => logoUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nova Empresa' : 'Editar Empresa'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Logo (apenas Importar)
              Row(
                children: [
                  AvatarOrLogo(
                    url: logoUrl,
                    label: name.text.isEmpty ? 'L' : name.text,
                    size: 44,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _importarLogo,
                    icon: const Icon(Icons.upload),
                    label: const Text('Importar Logo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: nipc,
                decoration: const InputDecoration(labelText: 'NIPC'),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<Periodicidade>(
                value: periodicidade,
                items: Periodicidade.values
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => periodicidade = v ?? Periodicidade.mensal),
                decoration: const InputDecoration(labelText: 'Periodicidade'),
              ),
              const SizedBox(height: 8),

              // Equipa responsável
              DropdownButtonFormField<String?>(
                value: selectedTeamId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('— Sem equipa —')),
                  ...teams.map((t) =>
                      DropdownMenuItem(value: t.id, child: Text(t.name))),
                ],
                onChanged: (v) => setState(() => selectedTeamId = v),
                decoration:
                    const InputDecoration(labelText: 'Equipa responsável'),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Text('Importância'),
                  Expanded(
                    child: Slider(
                      value: imp,
                      divisions: 5,
                      min: 0,
                      max: 5,
                      label: imp.round().toString(),
                      onChanged: (v) => setState(() => imp = v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Tarefas & Responsável',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),

              Column(
                children: [
                  for (final t in kDefaultTasks)
                    _TaskAssignRow(
                      def: t,
                      selected: taskKeys.contains(t.key),
                      onToggle: (sel) => setState(() {
                        if (sel) {
                          if (!taskKeys.contains(t.key)) taskKeys.add(t.key);
                        } else {
                          taskKeys.remove(t.key);
                          respByKey.remove(t.key);
                        }
                      }),
                      accountants: accountants,
                      value: respByKey[t.key],
                      onChanged: (id) => setState(() => respByKey[t.key] = id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            respByKey.removeWhere((k, _) => !taskKeys.contains(k));

            final c = Company(
              id: widget.existing?.id ?? '',
              name: name.text.trim(),
              nipc: nipc.text.trim(),
              periodicidade: periodicidade,
              importance: imp.round(),
              logoUrl: logoUrl,
              taskKeys: taskKeys,
              taskResponsibleByKey: respByKey,
            );
            Navigator.pop(context, _CompanyResult(c, selectedTeamId));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _TaskAssignRow extends StatelessWidget {
  final TaskDef def;
  final bool selected;
  final ValueChanged<bool> onToggle;
  final List<Accountant> accountants;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _TaskAssignRow({
    required this.def,
    required this.selected,
    required this.onToggle,
    required this.accountants,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading:
          Checkbox(value: selected, onChanged: (v) => onToggle(v ?? false)),
      title: Text(def.name),
      trailing: SizedBox(
        width: 220,
        child: DropdownButtonFormField<String?>(
          value: value,
          hint: const Text('Responsável'),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('—')),
            ...accountants.map((a) =>
                DropdownMenuItem<String?>(value: a.id, child: Text(a.name))),
          ],
          onChanged: (id) => onChanged(id),
        ),
      ),
    );
  }
}
