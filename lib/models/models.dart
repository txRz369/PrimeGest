// lib/models.dart

/// ===== Enums =====
enum Periodicidade { mensal, trimestral, isenta, cessada }

extension PeriodicidadeLabel on Periodicidade {
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
}

enum NivelProf { estagiario, junior, senior, lider }

extension NivelProfLabel on NivelProf {
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

enum UserRole { admin, contabilista }

/// ===== Models =====
class Task {
  final String id;
  String nome;
  String? descricao;

  Task({required this.id, required this.nome, this.descricao});
}

class Company {
  final String id;
  String nif;
  String nome;
  Periodicidade periodicidade;
  int importancia; // 0–5
  final Set<String> taskIds; // tarefas aplicáveis à empresa

  Company({
    required this.id,
    required this.nif,
    required this.nome,
    required this.periodicidade,
    required this.importancia,
    Set<String>? taskIds,
  }) : taskIds = taskIds ?? <String>{};
}

class Accountant {
  final String id;
  String nome;
  DateTime dataNascimento;
  NivelProf nivel;
  String? fotoUrl;

  Accountant({
    required this.id,
    required this.nome,
    required this.dataNascimento,
    required this.nivel,
    this.fotoUrl,
  });
}

class Team {
  final String id;
  String nome;
  final Set<String> accountantIds; // membros
  final Set<String> companyIds; // empresas atribuídas

  Team({
    required this.id,
    required this.nome,
    Set<String>? accountantIds,
    Set<String>? companyIds,
  }) : accountantIds = accountantIds ?? <String>{},
       companyIds = companyIds ?? <String>{};
}
