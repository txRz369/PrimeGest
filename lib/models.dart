import 'package:flutter/material.dart';

enum Periodicidade { mensal, trimestral, isenta, cessada }

enum Cargo { lider, senior, junior, estagiario }

enum ProfileFilter { todas, pendentes, concluidas }

class DashboardCounts {
  final int companies;
  final int pending;
  final int completed;
  DashboardCounts(
      {required this.companies,
      required this.pending,
      required this.completed});
}

class Company {
  String id;
  String name;
  String nipc;
  Periodicidade periodicidade;
  int importance; // 0-5
  String? logoUrl;
  List<String> taskKeys;
  // Novo: responsável por tarefa (task_key -> accountant_id)
  Map<String, String?> taskResponsibleByKey;

  Company({
    this.id = '',
    required this.name,
    required this.nipc,
    required this.periodicidade,
    required this.importance,
    this.logoUrl,
    List<String>? taskKeys,
    Map<String, String?>? taskResponsibleByKey,
  })  : taskKeys = taskKeys ?? defaultTaskKeys(),
        taskResponsibleByKey = taskResponsibleByKey ?? {};

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

  factory Company.fromMap(Map<String, dynamic> m) => Company(
        id: m['id'],
        name: m['name'] ?? '',
        nipc: m['nipc'] ?? '',
        periodicidade:
            Periodicidade.values.byName(m['periodicidade'] ?? 'mensal'),
        importance: (m['importance'] ?? 0) as int,
        logoUrl: m['logo_url'],
      );
}

class Accountant {
  final String id;
  final String name;
  final Cargo cargo;
  final String email;

  Accountant(
      {required this.id,
      required this.name,
      required this.cargo,
      required this.email});

  Map<String, dynamic> toMapInsert({String? id}) => {
        if (id != null) 'id': id,
        'name': name,
        'cargo': cargo.name,
        'email': email,
      };

  factory Accountant.fromMap(Map<String, dynamic> m) => Accountant(
        id: m['id'],
        name: m['name'],
        cargo: Cargo.values.byName(m['cargo']),
        email: m['email'],
      );
}

class Team {
  final String id;
  final String name;
  Team({required this.id, required this.name});

  factory Team.fromMap(Map<String, dynamic> m) =>
      Team(id: m['id'], name: m['name']);
}

// ---- Task definitions ----
class TaskDef {
  final String key;
  final String name;
  final int defaultImportance; // 0-5
  final bool isIVA;
  const TaskDef(this.key, this.name,
      {this.defaultImportance = 3, this.isIVA = false});
}

// “Fábrica”
const List<TaskDef> kDefaultTasks = [
  TaskDef('diversos', 'Diversos', defaultImportance: 2),
  TaskDef('compras', 'Compras', defaultImportance: 3),
  TaskDef('imobilizado', 'Imobilizado', defaultImportance: 2),
  TaskDef('extratos_banc', 'Extratos Bancários', defaultImportance: 4),
  TaskDef('extratos_cartao', 'Extratos de Cartões de Crédito',
      defaultImportance: 3),
  TaskDef('caixa', 'Caixa', defaultImportance: 2),
  TaskDef('emprestimos', 'Empréstimos', defaultImportance: 3),
  TaskDef('ine', 'INE', defaultImportance: 2),
  TaskDef('vendas_saft', 'Vendas (Integração de SAFT-T)', defaultImportance: 5),
  TaskDef('validar_saft', 'Validação de SAFT-T', defaultImportance: 5),
  TaskDef('just_cli', 'Justificação de Clientes', defaultImportance: 4),
  TaskDef('just_forn', 'Justificação de Fornecedores', defaultImportance: 4),
  TaskDef('mapas_explor', 'Mapas de Exploração e Centro de Custo',
      defaultImportance: 3),
  TaskDef('decl_iva', 'Declaração IVA', defaultImportance: 5, isIVA: true),
];

List<String> defaultTaskKeys() => kDefaultTasks.map((e) => e.key).toList();
TaskDef? defaultTaskByKey(String k) =>
    kDefaultTasks.where((t) => t.key == k).cast<TaskDef?>().firstOrNull;

// IVA status cores
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

Color colorForIVA(IVAEstado s, Brightness b) {
  switch (s) {
    case IVAEstado.aPagar:
    case IVAEstado.planoPagar:
      return Colors.red.shade400;
    case IVAEstado.recuperar:
      return Colors.green.shade800;
    case IVAEstado.reembolso:
      return Colors.green.shade300;
    case IVAEstado.reportar:
      return Colors.amber.shade600;
    case IVAEstado.naoTemIVA:
      return Colors.blue.shade600;
    case IVAEstado.enviado:
      return Colors.green.shade600;
    case IVAEstado.cessada:
      return Colors.lightBlue.shade200;
  }
}

class TaskInstance {
  String companyId;
  String taskKey;
  int year;
  int month;
  bool done;
  String? responsibleId;
  bool? recapitulativa;
  DateTime? data;
  double? montante;
  IVAEstado? ivaEstado;
  String? note;

  TaskInstance({
    required this.companyId,
    required this.taskKey,
    required this.year,
    required this.month,
    this.done = false,
    this.responsibleId,
    this.recapitulativa,
    this.data,
    this.montante,
    this.ivaEstado,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'company_id': companyId,
        'task_key': taskKey,
        'year': year,
        'month': month,
        'done': done,
        'responsible_id': responsibleId,
        'recapitulativa': recapitulativa,
        'data': data?.toIso8601String(),
        'montante': montante,
        'iva_estado': ivaEstado?.name,
        'note': note,
      };

  factory TaskInstance.fromMap(Map<String, dynamic> m) => TaskInstance(
        companyId: m['company_id'],
        taskKey: m['task_key'],
        year: m['year'],
        month: m['month'],
        done: m['done'] ?? false,
        responsibleId: m['responsible_id'],
        recapitulativa: m['recapitulativa'],
        data: m['data'] != null ? DateTime.parse(m['data']) : null,
        montante: (m['montante'] as num?)?.toDouble(),
        ivaEstado: m['iva_estado'] != null
            ? IVAEstado.values.byName(m['iva_estado'])
            : null,
        note: m['note'],
      );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
