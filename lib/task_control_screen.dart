import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'models.dart';
import 'widgets.dart';
import 'permissions.dart';

/// Ecrã de Controlo de Tarefas
/// - Carrega tudo de UMA vez (batch) para o mês/ano escolhido
/// - Sem barra de “loading” contínua
/// - Filtros (todas/pendentes/concluídas)
/// - Seletor de Ano/Mês via popup (YearMonthPickerButton)
class TaskControlScreen extends StatefulWidget {
  const TaskControlScreen({super.key});
  @override
  State<TaskControlScreen> createState() => _TaskControlScreenState();
}

class _TaskControlScreenState extends State<TaskControlScreen> {
  // Ano/Mês actual
  DateTime ym = DateTime(DateTime.now().year, DateTime.now().month);
  // Filtro (todas/pendentes/concluídas)
  ProfileFilter filter = ProfileFilter.todas;
  // Pesquisa por nome de empresa
  String search = '';

  // Dados em memória
  List<Company> companies = [];
  Map<String, List<TaskInstance>> instances = {}; // companyId -> tarefas do mês

  // Contadores para os cards informativos
  DashboardCounts counts =
      DashboardCounts(companies: 0, pending: 0, completed: 0);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // Carrega empresas + instâncias do mês de forma agregada (uma ida ao servidor)
  Future<void> _loadAll() async {
    final isAdmin = Permissions.isAdmin(Supa.email);
    final allowedCompanyIds =
        isAdmin ? <String>[] : await Supa.teamCompanyIdsForMe();

    // 1) Empresas
    companies = await Supa.fetchCompanies(
      search: search.isEmpty ? null : search,
      inIds: isAdmin ? null : allowedCompanyIds,
    );

    // 2) Instâncias do mês (batch)
    final ids = companies.map((c) => c.id).toList();
    instances = await Supa.fetchInstancesForCompaniesMonth(
      ids,
      ym.year,
      ym.month,
    );

    // 3) Regras especiais: empresa CESSADA -> Decl. IVA validada + estado CESSADA
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

    // Aplica filtro de perfil
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
          // Linha superior: pesquisa + seletor Ano/Mês
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

          // Filtros de estado
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

          // Caixas informativas (contadores locais)
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

          // Lista de empresas (sem barras de loading)
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
                        // marca/desmarca imediatamente no UI e sincroniza
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
                          if (data != null) ti.data = data;
                          if (montante != null) ti.montante = montante;
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
