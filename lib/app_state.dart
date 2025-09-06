// lib/app_state.dart
import 'package:flutter/material.dart';
import 'models.dart';
import 'service.dart';

/// Estado global em memória + escopo de acesso pelo widget tree.
class AppState extends ChangeNotifier {
  final auth = AuthService();

  // Dados principais
  final Map<String, Task> tasks = {};
  final Map<String, Company> companies = {};
  final Map<String, Accountant> accountants = {};
  final Map<String, Team> teams = {};

  // Tarefas concluídas por empresa/ano/mês (chave: compId|YYYY|MM)
  final Map<String, Set<String>> _doneByPeriod = {};

  // Mês/Ano selecionados (controlo interno)
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  // ===== Helpers =====
  String _key(String companyId, int year, int month) =>
      '$companyId|$year|$month';

  Set<String> doneFor(String companyId, {int? year, int? month}) {
    final k = _key(companyId, year ?? selectedYear, month ?? selectedMonth);
    return _doneByPeriod[k] ?? <String>{};
  }

  void toggleDone(String companyId, String taskId) {
    final k = _key(companyId, selectedYear, selectedMonth);
    final set = _doneByPeriod.putIfAbsent(k, () => <String>{});
    if (!set.add(taskId)) set.remove(taskId);
    notifyListeners();
  }

  void setMonthYear(int year, int month) {
    selectedYear = year;
    selectedMonth = month;
    notifyListeners();
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  // ===== CRUD: Tasks =====
  Task createTask(String nome, {String? descricao}) {
    final t = Task(id: _newId('task'), nome: nome, descricao: descricao);
    tasks[t.id] = t;
    notifyListeners();
    return t;
  }

  void updateTask(Task t, {String? nome, String? descricao}) {
    t.nome = nome ?? t.nome;
    t.descricao = descricao ?? t.descricao;
    notifyListeners();
  }

  void deleteTask(String id) {
    tasks.remove(id);
    for (final c in companies.values) {
      c.taskIds.remove(id);
    }
    _doneByPeriod.removeWhere((_, set) => set.remove(id));
    notifyListeners();
  }

  // ===== CRUD: Companies =====
  Company createCompany({
    required String nif,
    required String nome,
    required Periodicidade periodicidade,
    required int importancia,
    Set<String>? taskIds,
  }) {
    final c = Company(
      id: _newId('comp'),
      nif: nif,
      nome: nome,
      periodicidade: periodicidade,
      importancia: (importancia.clamp(0, 5)) as int,
      taskIds: taskIds,
    );
    companies[c.id] = c;
    notifyListeners();
    return c;
  }

  void updateCompany(
    Company c, {
    String? nif,
    String? nome,
    Periodicidade? periodicidade,
    int? importancia,
    Set<String>? taskIds,
  }) {
    c.nif = nif ?? c.nif;
    c.nome = nome ?? c.nome;
    c.periodicidade = periodicidade ?? c.periodicidade;
    if (importancia != null) c.importancia = (importancia.clamp(0, 5)) as int;
    if (taskIds != null) {
      c.taskIds
        ..clear()
        ..addAll(taskIds);
    }
    notifyListeners();
  }

  void deleteCompany(String id) {
    companies.remove(id);
    for (final t in teams.values) {
      t.companyIds.remove(id);
    }
    _doneByPeriod.removeWhere((k, _) => k.startsWith('$id|'));
    notifyListeners();
  }

  // ===== CRUD: Accountants =====
  Accountant createAccountant({
    String? id,
    required String nome,
    required DateTime dataNascimento,
    required NivelProf nivel,
    String? fotoUrl,
  }) {
    final a = Accountant(
      id: id ?? _newId('acc'),
      nome: nome,
      dataNascimento: dataNascimento,
      nivel: nivel,
      fotoUrl: fotoUrl,
    );
    accountants[a.id] = a;
    notifyListeners();
    return a;
  }

  void updateAccountant(
    Accountant a, {
    String? nome,
    DateTime? dataNascimento,
    NivelProf? nivel,
    String? fotoUrl,
  }) {
    a.nome = nome ?? a.nome;
    a.dataNascimento = dataNascimento ?? a.dataNascimento;
    a.nivel = nivel ?? a.nivel;
    a.fotoUrl = fotoUrl ?? a.fotoUrl;
    notifyListeners();
  }

  void deleteAccountant(String id) {
    accountants.remove(id);
    for (final t in teams.values) {
      t.accountantIds.remove(id);
    }
    notifyListeners();
  }

  // ===== CRUD: Teams =====
  Team createTeam(String nome) {
    final t = Team(id: _newId('team'), nome: nome);
    teams[t.id] = t;
    notifyListeners();
    return t;
  }

  void updateTeam(
    Team t, {
    String? nome,
    Set<String>? accountantIds,
    Set<String>? companyIds,
  }) {
    t.nome = nome ?? t.nome;
    if (accountantIds != null) {
      t.accountantIds
        ..clear()
        ..addAll(accountantIds);
    }
    if (companyIds != null) {
      t.companyIds
        ..clear()
        ..addAll(companyIds);
    }
    notifyListeners();
  }

  void deleteTeam(String id) {
    teams.remove(id);
    notifyListeners();
  }

  // ===== Filtragem por permissões =====
  Iterable<Company> visibleCompanies() {
    if (auth.isAdmin) return companies.values;
    final accId = auth.currentAccountantId;
    if (accId == null) return const <Company>[];
    final allowedCompanyIds = teams.values
        .where((t) => t.accountantIds.contains(accId))
        .expand((t) => t.companyIds)
        .toSet();
    return companies.values.where((c) => allowedCompanyIds.contains(c.id));
  }

  // ===== Seed inicial para demo =====
  void seedIfEmpty() {
    if (tasks.isNotEmpty || companies.isNotEmpty) return;

    // Tarefas base
    final t1 = createTask(
      'Declaração IVA',
      descricao: 'Preparar e submeter IVA',
    );
    final t2 = createTask(
      'Segurança Social',
      descricao: 'Relatório e pagamento',
    );
    final t3 = createTask('IRS/IRC', descricao: 'Apuramento e submissão');

    // Empresas
    final c1 = createCompany(
      nif: '500000001',
      nome: 'Alfa, Lda',
      periodicidade: Periodicidade.mensal,
      importancia: 5,
      taskIds: {t1.id, t2.id, t3.id},
    );
    final c2 = createCompany(
      nif: '500000002',
      nome: 'Beta, SA',
      periodicidade: Periodicidade.trimestral,
      importancia: 3,
      taskIds: {t1.id, t3.id},
    );

    // Contabilistas (um com id fixo para bater com utilizador c1)
    final a1 = createAccountant(
      id: 'acc-1',
      nome: 'Ana Silva',
      dataNascimento: DateTime(1990, 5, 12),
      nivel: NivelProf.lider,
    );
    final a2 = createAccountant(
      nome: 'Bruno Costa',
      dataNascimento: DateTime(1995, 3, 3),
      nivel: NivelProf.senior,
    );

    // Equipa
    final team = createTeam('Equipa A');
    team.accountantIds.addAll({a1.id, a2.id});
    team.companyIds.addAll({c1.id, c2.id});
    notifyListeners();
  }
}

/// InheritedNotifier para aceder ao AppState no widget tree.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope não encontrado no contexto');
    return scope!.notifier!;
  }
}
