import 'package:flutter/material.dart';

/// Filtros do painel
enum ProfileFilter { todas, pendentes, concluidas }

/// Periodicidade da empresa
enum Periodicidade { mensal, trimestral, isenta, cessada }

/// Cargos dos contabilistas
enum Cargo { lider, senior, junior, estagiario }

/// Estados possíveis para a Declaração de IVA
enum IVAEstado {
  aPagar,
  planoPagar,
  recuperar,
  reembolso,
  reportar,
  naoTemIVA,
  enviado,
  cessada,
}

/// Modelo de Contabilista
class Accountant {
  final String id;
  final String name;
  final Cargo cargo;
  final String email;

  Accountant({
    required this.id,
    required this.name,
    required this.cargo,
    required this.email,
  });

  factory Accountant.fromMap(Map<String, dynamic> m) => Accountant(
        id: m['id'] as String,
        name: m['name'] as String,
        cargo: Cargo.values.firstWhere((e) => e.name == (m['cargo'] as String)),
        email: m['email'] as String,
      );

  Map<String, dynamic> toMapInsert() =>
      {'name': name, 'cargo': cargo.name, 'email': email};
}

/// Modelo de Equipa
class Team {
  final String id;
  String name;
  String? imageUrl;

  Team({required this.id, required this.name, this.imageUrl});

  factory Team.fromMap(Map<String, dynamic> m) => Team(
      id: m['id'] as String,
      name: m['name'] as String,
      imageUrl: m['image_url'] as String?);

  Map<String, dynamic> toMapUpdate() => {'name': name, 'image_url': imageUrl};
}

/// Modelo de Empresa
class Company {
  final String id;
  final String name;
  final String nipc;
  final Periodicidade periodicidade;
  final int importance;
  final String? logoUrl;

  // tarefas atribuídas
  List<String> taskKeys;
  Map<String, String?> taskResponsibleByKey;

  Company({
    required this.id,
    required this.name,
    required this.nipc,
    required this.periodicidade,
    required this.importance,
    this.logoUrl,
    this.taskKeys = const [],
    this.taskResponsibleByKey = const {},
  });

  factory Company.fromMap(Map<String, dynamic> m) => Company(
        id: m['id'] as String,
        name: m['name'] as String,
        nipc: m['nipc'] as String,
        periodicidade: Periodicidade.values
            .firstWhere((e) => e.name == (m['periodicidade'] as String)),
        importance: (m['importance'] as num).toInt(),
        logoUrl: m['logo_url'] as String?,
      );

  Map<String, dynamic> toMapInsert() => {
        'name': name,
        'nipc': nipc,
        'periodicidade': periodicidade.name,
        'importance': importance,
        'logo_url': logoUrl,
      };

  Map<String, dynamic> toMapUpdate() => {
        'name': name,
        'nipc': nipc,
        'periodicidade': periodicidade.name,
        'importance': importance,
        'logo_url': logoUrl,
      };
}

/// Instância mensal de tarefa
class TaskInstance {
  final String companyId;
  final String taskKey;
  final int year;
  final int month;
  bool done;
  String? responsibleId;
  IVAEstado? ivaEstado;

  /// ⚠️ NOVO — valores independentes:
  DateTime? periodicDate;
  double? periodicMontante;

  DateTime? recapDate;
  double? recapMontante;

  /// Mantido para compat: indicador de que houve Recapitulativa
  bool? recapitulativa;

  /// (LEGADO) estes campos eram usados para 1 só par de data/montante
  /// Mantidos apenas por compatibilidade eventual.
  DateTime? data;
  double? montante;

  TaskInstance({
    required this.companyId,
    required this.taskKey,
    required this.year,
    required this.month,
    this.done = false,
    this.responsibleId,
    this.ivaEstado,
    this.periodicDate,
    this.periodicMontante,
    this.recapDate,
    this.recapMontante,
    this.recapitulativa,
    this.data,
    this.montante,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  factory TaskInstance.fromMap(Map<String, dynamic> m) => TaskInstance(
        companyId: m['company_id'] as String,
        taskKey: m['task_key'] as String,
        year: m['year'] as int,
        month: m['month'] as int,
        done: m['done'] as bool? ?? false,
        responsibleId: m['responsible_id'] as String?,
        ivaEstado: (m['iva_estado'] as String?) == null
            ? null
            : IVAEstado.values.firstWhere((e) => e.name == m['iva_estado']),
        // novos campos
        periodicDate: _parseDate(m['periodic_data']),
        periodicMontante: (m['periodic_montante'] as num?)?.toDouble(),
        recapDate: _parseDate(m['recap_data']),
        recapMontante: (m['recap_montante'] as num?)?.toDouble(),
        recapitulativa: m['recapitulativa'] as bool?,
        // legado — se existirem ainda na DB
        data: _parseDate(m['data']),
        montante: (m['montante'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'company_id': companyId,
        'task_key': taskKey,
        'year': year,
        'month': month,
        'done': done,
        'responsible_id': responsibleId,
        'iva_estado': ivaEstado?.name,
        // novos campos
        'periodic_data': periodicDate?.toIso8601String(),
        'periodic_montante': periodicMontante,
        'recap_data': recapDate?.toIso8601String(),
        'recap_montante': recapMontante,
        'recapitulativa': recapitulativa,
        // legado (opcional) — espelhar periodic nos antigos para compat
        'data': data ?? periodicDate?.toIso8601String(),
        'montante': montante ?? periodicMontante,
      };
}

/// Contadores para os cards do dashboard
class DashboardCounts {
  final int companies;
  final int pending;
  final int completed;
  DashboardCounts(
      {required this.companies,
      required this.pending,
      required this.completed});
}

/// Definição de tarefa “de fábrica”
class TaskDef {
  final String key;
  final String name;
  final int defaultImportance;
  final bool isIVA;
  const TaskDef(
      {required this.key,
      required this.name,
      this.defaultImportance = 0,
      this.isIVA = false});
}

const List<TaskDef> kDefaultTasks = [
  TaskDef(key: 'diversos', name: 'Diversos', defaultImportance: 1),
  TaskDef(key: 'compras', name: 'Compras', defaultImportance: 1),
  TaskDef(key: 'imobilizado', name: 'Imobilizado', defaultImportance: 1),
  TaskDef(
      key: 'extratos_banc', name: 'Extratos Bancários', defaultImportance: 2),
  TaskDef(key: 'extratos_cc', name: 'Extratos de Cartões de Crédito'),
  TaskDef(key: 'caixa', name: 'Caixa'),
  TaskDef(key: 'emprestimos', name: 'Empréstimos'),
  TaskDef(key: 'ine', name: 'INE'),
  TaskDef(
      key: 'vendas_saft',
      name: 'Vendas (Integração de SAFT-T)',
      defaultImportance: 3),
  TaskDef(key: 'valid_saft', name: 'Validação de SAFT-T'),
  TaskDef(key: 'just_clientes', name: 'Justificação de Clientes'),
  TaskDef(key: 'just_fornec', name: 'Justificação de Fornecedores'),
  TaskDef(key: 'mapas_expl', name: 'Mapas de Exploração e Centro de Custo'),
  TaskDef(
      key: 'decl_iva',
      name: 'Declaração IVA',
      isIVA: true,
      defaultImportance: 5),
];

TaskDef? defaultTaskByKey(String k) =>
    kDefaultTasks.firstWhere((t) => t.key == k,
        orElse: () => const TaskDef(key: 'x', name: 'Tarefa'));
List<String> defaultTaskKeys() => kDefaultTasks.map((e) => e.key).toList();

/// Cores por estado de IVA (para botões/etiquetas)
Color colorForIVA(IVAEstado s, Brightness _) {
  switch (s) {
    case IVAEstado.aPagar:
    case IVAEstado.planoPagar:
      return Colors.red;
    case IVAEstado.recuperar:
      return const Color(0xFF1B5E20);
    case IVAEstado.reembolso:
      return Colors.lightGreen;
    case IVAEstado.reportar:
      return Colors.amber;
    case IVAEstado.naoTemIVA:
      return Colors.blue;
    case IVAEstado.enviado:
      return Colors.green;
    case IVAEstado.cessada:
      return Colors.lightBlueAccent;
  }
}
