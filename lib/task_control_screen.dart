import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'models.dart';
import 'widgets.dart';
import 'permissions.dart';

/// Ecrã de Controlo de Tarefas
class TaskControlScreen extends StatefulWidget {
  const TaskControlScreen({super.key});
  @override
  State<TaskControlScreen> createState() => _TaskControlScreenState();
}

class _TaskControlScreenState extends State<TaskControlScreen> {
  DateTime ym = DateTime(DateTime.now().year, DateTime.now().month);
  ProfileFilter filter = ProfileFilter.todas;
  String search = '';

  List<Company> companies = [];
  Map<String, List<TaskInstance>> instances = {};
  DashboardCounts counts =
      DashboardCounts(companies: 0, pending: 0, completed: 0);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final isAdmin = Permissions.isAdmin(Supa.email);
    final allowedCompanyIds =
        isAdmin ? <String>[] : await Supa.teamCompanyIdsForMe();

    companies = await Supa.fetchCompanies(
      search: search.isEmpty ? null : search,
      inIds: isAdmin ? null : allowedCompanyIds,
    );

    final ids = companies.map((c) => c.id).toList();
    instances = await Supa.fetchInstancesForCompaniesMonth(
      ids,
      ym.year,
      ym.month,
    );

    // Sincroniza responsável das instâncias com o definido na Empresa (mostra já)
    for (final c in companies) {
      final list = instances[c.id] ?? [];
      for (final ti in list) {
        final compResp = c.taskResponsibleByKey[ti.taskKey];
        if (compResp != null && compResp != ti.responsibleId) {
          ti.responsibleId = compResp;
          await Supa.upsertInstance(ti);
        }
      }
    }

    // Empresas cessadas: IVA automaticamente CESSADA & done
    for (final c
        in companies.where((c) => c.periodicidade == Periodicidade.cessada)) {
      final list = instances[c.id] ?? [];
      for (final ti in list) {
        if (ti.taskKey == 'decl_iva') {
          if (ti.ivaEstado != IVAEstado.cessada || !ti.done) {
            ti.ivaEstado = IVAEstado.cessada;
            ti.done = true;
            await Supa.upsertInstance(ti);
          }
        }
      }
    }

    _recalcCounts();
    if (mounted) setState(() {});
  }

  void _recalcCounts() {
    int pending = 0, done = 0;
    for (final list in instances.values) {
      for (final ti in list) {
        ti.done ? done++ : pending++;
      }
    }
    counts = DashboardCounts(
      companies: companies.length,
      pending: pending,
      completed: done,
    );
  }

  void _onMonthChanged(DateTime newYm) {
    ym = DateTime(newYm.year, newYm.month);
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final filteredCompanies = companies.where((c) {
      if (filter == ProfileFilter.todas) return true;
      final list = instances[c.id] ?? [];
      final hasPending = list.any((i) => !i.done);
      if (filter == ProfileFilter.pendentes) return hasPending;
      if (filter == ProfileFilter.concluidas)
        return !hasPending && list.isNotEmpty;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SearchBar(
                  hintText: 'Pesquisar empresas...',
                  onChanged: (s) => search = s,
                  trailing: [
                    IconButton(
                        icon: const Icon(Icons.search), onPressed: _loadAll),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              YearMonthPickerButton(
                initial: ym,
                onChanged: _onMonthChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilterChip(
                label: const Text('Todas'),
                selected: filter == ProfileFilter.todas,
                onSelected: (_) => setState(() => filter = ProfileFilter.todas),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Pendentes'),
                selected: filter == ProfileFilter.pendentes,
                onSelected: (_) =>
                    setState(() => filter = ProfileFilter.pendentes),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Concluídas'),
                selected: filter == ProfileFilter.concluidas,
                onSelected: (_) =>
                    setState(() => filter = ProfileFilter.concluidas),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InfoBox(
                  title: 'Empresas',
                  value: counts.companies.toString(),
                  icon: Icons.apartment,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InfoBox(
                  title: 'Tarefas Pendentes',
                  value: counts.pending.toString(),
                  icon: Icons.timelapse,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InfoBox(
                  title: 'Tarefas Concluídas',
                  value: counts.completed.toString(),
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredCompanies.isEmpty
                ? const Center(child: Text('Sem empresas.'))
                : ListView.builder(
                    itemCount: filteredCompanies.length,
                    itemBuilder: (_, i) {
                      final c = filteredCompanies[i];
                      final list = (instances[c.id] ?? []);
                      return CompanyCard(
                        company: c,
                        monthInstances: list,
                        year: ym.year,
                        month: ym.month,
                        onToggleTask: (ti) async {
                          setState(() {
                            ti.done = !ti.done;
                            _recalcCounts();
                          });
                          await Supa.upsertInstance(ti);
                        },
                        onIVAChange: (ti,
                            {IVAEstado? estado,
                            DateTime? data,
                            double? montante}) async {
                          if (estado != null) ti.ivaEstado = estado;
                          if (data != null) ti.data = data; // Periódica
                          if (montante != null)
                            ti.montante = montante; // Periódica
                          setState(() {}); // reflecte já
                          await Supa.upsertInstance(ti);
                        },
                        brightness: brightness,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
