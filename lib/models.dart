import 'package:flutter/material.dart';

enum Periodicidade { mensal, trimestral, isenta, cessada }

enum NivelProf { estagiario, junior, senior, lider }

extension PeriodicidadeX on Periodicidade {
  String get label {
    switch (this) {
      case Periodicidade.mensal:
        return 'Mensal';
      case Periodicidade.trimestral:
        return 'Trimestral';
      case Periodicidade.isenta:
        return 'Isenta';
      case Periodicidade.cessada:
        return 'Cessada';
    }
  }

  static Periodicidade fromLabel(String s) {
    switch (s.toLowerCase()) {
      case 'mensal':
        return Periodicidade.mensal;
      case 'trimestral':
        return Periodicidade.trimestral;
      case 'isenta':
        return Periodicidade.isenta;
      case 'cessada':
        return Periodicidade.cessada;
      default:
        return Periodicidade.mensal;
    }
  }
}

extension NivelProfX on NivelProf {
  String get label {
    switch (this) {
      case NivelProf.estagiario:
        return 'Estagiário';
      case NivelProf.junior:
        return 'Júnior';
      case NivelProf.senior:
        return 'Sénior';
      case NivelProf.lider:
        return 'Líder';
    }
  }
}

class User {
  final bool isAdmin;
  final String? contabilistaId;
  final String username;
  User.admin() : isAdmin = true, contabilistaId = null, username = 'admin';
  User.contabilista({required this.contabilistaId, required this.username})
    : isAdmin = false;
}

String makeId([String? prefix]) {
  final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rnd = (ts.hashCode ^ (ts.length * 2654435761)).toRadixString(36);
  return '${prefix ?? 'id'}_${ts}_$rnd';
}

class Tarefa {
  final String id;
  String nome;
  String? descricao;
  bool ativa;
  Tarefa({String? id, required this.nome, this.descricao, this.ativa = true})
    : id = id ?? makeId('tsk');
}

class Empresa {
  final String id;
  String nif;
  String nome;
  Periodicidade periodicidade;
  int importancia; // 0..5
  final Set<String> tarefaIds; // tarefas atribuídas à empresa

  Empresa({
    String? id,
    required this.nif,
    required this.nome,
    required this.periodicidade,
    required this.importancia,
    Set<String>? tarefaIds,
  }) : id = id ?? makeId('emp'),
       tarefaIds = tarefaIds ?? <String>{};
}

class Contabilista {
  final String id;
  String nome;
  DateTime nascimento;
  NivelProf nivel;
  String? fotoUrl;
  String username;
  Contabilista({
    String? id,
    required this.nome,
    required this.nascimento,
    required this.nivel,
    this.fotoUrl,
    required this.username,
  }) : id = id ?? makeId('ctb');
}

class Equipa {
  final String id;
  String nome;
  final Set<String> contabilistaIds;
  final Set<String> empresaIds;

  Equipa({
    String? id,
    required this.nome,
    Set<String>? contabilistaIds,
    Set<String>? empresaIds,
  }) : id = id ?? makeId('eqp'),
       contabilistaIds = contabilistaIds ?? <String>{},
       empresaIds = empresaIds ?? <String>{};
}

/// Chave YYYY-MM para controlo mensal
String ymKey(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

/// Resultado de contagem de tarefas
class TaskProgress {
  final int total;
  final int feitas;
  int get porFazer => total - feitas;
  TaskProgress(this.total, this.feitas);
}

/// Guard de permissões simples
@immutable
class Guard {
  final bool isAdmin;
  const Guard({required this.isAdmin});

  bool canSeeAdminMenu() => isAdmin;
}
