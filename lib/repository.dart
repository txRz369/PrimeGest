import 'models.dart';
import 'supabase_config.dart';

/// Repositório ligado ao Supabase com caches locais.
/// Mantém a API usada no UI (maioritariamente síncrona), fazendo
/// carregamentos assíncronos em background e atualizando caches.
class Repository {
  // Listas principais (cache)
  final List<Empresa> empresas = [];
  final List<Contabilista> contabilistas = [];
  final List<Equipa> equipas = [];
  final List<Tarefa> tarefas = [];

  // Caches auxiliares
  final Map<String, List<Tarefa>> _empTarefas = {}; // empId -> tarefas
  final Set<String> _conclusoes = {}; // "emp|tarefa|ym"

  // ----------------------------- INIT -----------------------------
  void seed() {
    // Carrega tudo em background (UI lê as caches).
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadEmpresas(),
      _loadTarefas(),
      _loadPerfis(),
      _loadEquipas(),
    ]);
  }

  // ----------------------------- LOADERS --------------------------
  Future<void> _loadEmpresas() async {
    final rows = await Supa.client
        .from('empresas')
        .select()
        .order('importancia', ascending: false);
    empresas
      ..clear()
      ..addAll(rows.map<Empresa>((r) => Empresa(
            id: r['id'],
            nif: r['nif'],
            nome: r['nome'],
            periodicidade: PeriodicidadeX.fromLabel(r['periodicidade']),
            importancia: (r['importancia'] ?? 3) as int,
          )));
  }

  Future<void> _loadTarefas() async {
    final rows = await Supa.client.from('tarefas').select().order('nome');
    tarefas
      ..clear()
      ..addAll(rows.map<Tarefa>((r) => Tarefa(
            id: r['id'],
            nome: r['nome'],
            descricao: r['descricao'],
            ativa: (r['ativa'] ?? true) as bool,
          )));
  }

  Future<void> _loadPerfis() async {
    final rows = await Supa.client.from('profiles').select().order('nome');
    contabilistas
      ..clear()
      ..addAll(rows.map<Contabilista>((r) => Contabilista(
            id: r['user_id'],
            nome: r['nome'] ?? '',
            nascimento: r['nascimento'] == null
                ? DateTime(1990)
                : DateTime.parse(r['nascimento']),
            nivel: _nivelFromStr(r['nivel']),
            fotoUrl: r['foto_url'],
            username: r['username'] ?? '',
          )));
  }

  Future<void> _loadEquipas() async {
    final rows =
        await Supa.client.from('equipas').select('id, nome').order('nome');
    equipas
      ..clear()
      ..addAll(rows.map<Equipa>((r) => Equipa(id: r['id'], nome: r['nome'])));
    // relações
    for (final e in equipas) {
      final mem = await Supa.client
          .from('equipa_membros')
          .select('user_id')
          .eq('equipa_id', e.id);
      e.contabilistaIds
        ..clear()
        ..addAll(mem.map<String>((m) => m['user_id'] as String));

      final emps = await Supa.client
          .from('equipa_empresas')
          .select('empresa_id')
          .eq('equipa_id', e.id);
      e.empresaIds
        ..clear()
        ..addAll(emps.map<String>((m) => m['empresa_id'] as String));
    }
  }

  NivelProf _nivelFromStr(String? s) {
    switch ((s ?? 'junior').toLowerCase()) {
      case 'estagiario':
        return NivelProf.estagiario;
      case 'senior':
        return NivelProf.senior;
      case 'lider':
        return NivelProf.lider;
      default:
        return NivelProf.junior;
    }
  }

  String _nivelToStr(NivelProf n) => n.label.toLowerCase();

  // ----------------------------- VISÃO POR UTILIZADOR --------------
  List<Empresa> empresasForUser(User user) {
    // O RLS do Supabase já filtra; aqui devolvemos a cache ordenada.
    final list = [...empresas]
      ..sort((a, b) => b.importancia.compareTo(a.importancia));
    return list;
  }

  // ----------------------------- TAREFAS DA EMPRESA ----------------
  /// Versão síncrona para o UI: devolve cache (ou lista vazia na 1ª vez)
  /// e dispara um carregamento em background.
  List<Tarefa> tarefasDaEmpresa(String empresaId, {bool apenasAtivas = true}) {
    final cached = _empTarefas[empresaId];
    if (cached == null) {
      _loadEmpresaTarefas(empresaId); // background
      return const [];
    }
    final list =
        apenasAtivas ? cached.where((t) => t.ativa).toList() : [...cached];
    list.sort((a, b) => a.nome.compareTo(b.nome));
    return list;
  }

  /// Leitura assíncrona direta do Supabase (útil se quiseres usar FutureBuilder)
  Future<List<Tarefa>> _tarefasDaEmpresaAsync(String empresaId,
      {bool apenasAtivas = true}) async {
    final rows = await Supa.client
        .from('empresa_tarefas')
        .select('tarefas(id, nome, descricao, ativa)')
        .eq('empresa_id', empresaId);

    final list = <Tarefa>[];
    for (final r in rows) {
      final t = r['tarefas'] as Map<String, dynamic>?;
      if (t != null) {
        final task = Tarefa(
          id: t['id'],
          nome: t['nome'],
          descricao: t['descricao'],
          ativa: (t['ativa'] ?? true) as bool,
        );
        if (!apenasAtivas || task.ativa) list.add(task);
      }
    }
    list.sort((a, b) => a.nome.compareTo(b.nome));
    return list;
  }

  Future<void> _loadEmpresaTarefas(String empresaId) async {
    final list = await _tarefasDaEmpresaAsync(empresaId);
    _empTarefas[empresaId] = list;
  }

  void setEmpresaTarefas(String empresaId, Set<String> tarefaIds) {
    () async {
      await Supa.client
          .from('empresa_tarefas')
          .delete()
          .eq('empresa_id', empresaId);
      if (tarefaIds.isNotEmpty) {
        await Supa.client.from('empresa_tarefas').insert(
              tarefaIds
                  .map((id) => {'empresa_id': empresaId, 'tarefa_id': id})
                  .toList(),
            );
      }
      await _loadEmpresaTarefas(empresaId);
    }();
  }

  // ----------------------------- CONCLUSÕES MENSAIS ----------------
  bool isConcluida(String empresaId, String tarefaId, String ym) {
    final key = '$empresaId|$tarefaId|$ym';
    if (!_conclusoes.contains(key)) {
      _loadConclusoes(empresaId, ym); // background
      return false;
    }
    return true;
  }

  Future<void> _loadConclusoes(String empresaId, String ym) async {
    final rows = await Supa.client
        .from('task_completions')
        .select('tarefa_id')
        .eq('empresa_id', empresaId)
        .eq('ym', ym);
    for (final r in rows) {
      _conclusoes.add('$empresaId|${r['tarefa_id']}|$ym');
    }
  }

  void marcarConclusao(
      String empresaId, String tarefaId, String ym, bool done) {
    final key = '$empresaId|$tarefaId|$ym';
    () async {
      if (done) {
        await Supa.client.from('task_completions').upsert({
          'empresa_id': empresaId,
          'tarefa_id': tarefaId,
          'ym': ym,
          'user_id': Supa.client.auth.currentUser?.id,
        });
        _conclusoes.add(key);
      } else {
        await Supa.client
            .from('task_completions')
            .delete()
            .match({'empresa_id': empresaId, 'tarefa_id': tarefaId, 'ym': ym});
        _conclusoes.remove(key);
      }
    }();
  }

  /// Contagem rápida baseada em caches (pode apresentar 0/0 na 1ª renderização).
  TaskProgress progressoEmpresaMes(String empresaId, String ym) {
    final tasks = tarefasDaEmpresa(empresaId);
    int feitas = 0;
    for (final t in tasks) {
      if (isConcluida(empresaId, t.id, ym)) feitas++;
    }
    return TaskProgress(tasks.length, feitas);
  }

  /// Versão assíncrona precisa (se quiseres usar com FutureBuilder)
  Future<TaskProgress> progressoEmpresaMesFuture(
      String empresaId, String ym) async {
    final total = (await _tarefasDaEmpresaAsync(empresaId)).length;
    final rows = await Supa.client
        .from('task_completions')
        .select('tarefa_id')
        .eq('empresa_id', empresaId)
        .eq('ym', ym);
    final feitas = (rows as List).length;
    return TaskProgress(total, feitas);
  }

  // ----------------------------- CRUD TAREFAS -----------------------
  Tarefa addTarefa(Tarefa t) {
    // Atualiza UI imediatamente (optimistic), sincroniza com servidor em background
    tarefas.add(t);
    () async {
      final row = await Supa.client
          .from('tarefas')
          .insert({'nome': t.nome, 'descricao': t.descricao, 'ativa': t.ativa})
          .select()
          .single();
      // Recarrega para garantir consistência (id real, etc.)
      await _loadTarefas();
    }();
    return t;
  }

  void updateTarefa(Tarefa t, {String? nome, String? descricao, bool? ativa}) {
    final n = nome ?? t.nome;
    final d = descricao ?? t.descricao;
    final a = ativa ?? t.ativa;
    // Optimistic update
    t
      ..nome = n
      ..descricao = d
      ..ativa = a;
    () async {
      await Supa.client
          .from('tarefas')
          .update({'nome': n, 'descricao': d, 'ativa': a}).eq('id', t.id);
      await _loadTarefas();
    }();
  }

  void removeTarefa(String tarefaId) {
    tarefas.removeWhere((e) => e.id == tarefaId);
    () async {
      await Supa.client.from('tarefas').delete().eq('id', tarefaId);
      await _loadTarefas();
    }();
  }

  // ----------------------------- CRUD EMPRESAS ----------------------
  Empresa addEmpresa(Empresa e) {
    // Optimistic
    empresas.add(e);
    () async {
      final row = await Supa.client
          .from('empresas')
          .insert({
            'nif': e.nif,
            'nome': e.nome,
            'periodicidade': e.periodicidade.label.toLowerCase(),
            'importancia': e.importancia,
          })
          .select()
          .single();
      await _loadEmpresas();
    }();
    return e;
  }

  void updateEmpresa(Empresa e,
      {String? nif,
      String? nome,
      Periodicidade? periodicidade,
      int? importancia}) {
    if (nif != null) e.nif = nif;
    if (nome != null) e.nome = nome;
    if (periodicidade != null) e.periodicidade = periodicidade;
    if (importancia != null) e.importancia = importancia;

    final data = <String, dynamic>{};
    if (nif != null) data['nif'] = nif;
    if (nome != null) data['nome'] = nome;
    if (periodicidade != null)
      data['periodicidade'] = periodicidade.label.toLowerCase();
    if (importancia != null) data['importancia'] = importancia;

    () async {
      await Supa.client.from('empresas').update(data).eq('id', e.id);
      await _loadEmpresas();
    }();
  }

  void removeEmpresa(String empresaId) {
    empresas.removeWhere((x) => x.id == empresaId);
    () async {
      await Supa.client.from('empresas').delete().eq('id', empresaId);
      await _loadEmpresas();
    }();
  }

  // ----------------------------- CRUD PROFILES ----------------------
  /// NOTA: criar utilizadores em Auth precisa de Service Role (não disponível no cliente).
  /// Aqui assume-se que o user já existe em Auth; esta função faz upsert no profile.
  Contabilista addContabilista(Contabilista c) {
    contabilistas.add(c);
    () async {
      await Supa.client.from('profiles').upsert({
        'user_id': c.id,
        'nome': c.nome,
        'nascimento': c.nascimento.toIso8601String(),
        'nivel': _nivelToStr(c.nivel),
        'foto_url': c.fotoUrl,
        'username': c.username,
      });
      await _loadPerfis();
    }();
    return c;
  }

  void updateContabilista(Contabilista c,
      {String? nome,
      DateTime? nascimento,
      NivelProf? nivel,
      String? fotoUrl,
      String? username}) {
    if (nome != null) c.nome = nome;
    if (nascimento != null) c.nascimento = nascimento;
    if (nivel != null) c.nivel = nivel;
    if (fotoUrl != null) c.fotoUrl = fotoUrl;
    if (username != null) c.username = username;

    final data = <String, dynamic>{};
    if (nome != null) data['nome'] = nome;
    if (nascimento != null) data['nascimento'] = nascimento.toIso8601String();
    if (nivel != null) data['nivel'] = _nivelToStr(nivel);
    if (fotoUrl != null) data['foto_url'] = fotoUrl;
    if (username != null) data['username'] = username;

    () async {
      await Supa.client.from('profiles').update(data).eq('user_id', c.id);
      await _loadPerfis();
    }();
  }

  void removeContabilista(String contabilistaId) {
    contabilistas.removeWhere((c) => c.id == contabilistaId);
    () async {
      await Supa.client
          .from('equipa_membros')
          .delete()
          .eq('user_id', contabilistaId);
      await Supa.client.from('profiles').delete().eq('user_id', contabilistaId);
      await _loadPerfis();
    }();
  }

  // ----------------------------- EQUIPAS & RELAÇÕES -----------------
  Equipa addEquipa(Equipa e) {
    equipas.add(e);
    () async {
      final row = await Supa.client
          .from('equipas')
          .insert({'nome': e.nome})
          .select()
          .single();
      await _loadEquipas();
    }();
    return e;
  }

  void updateEquipa(Equipa e, {String? nome}) {
    if (nome != null) e.nome = nome;
    () async {
      await Supa.client.from('equipas').update({'nome': e.nome}).eq('id', e.id);
      await _loadEquipas();
    }();
  }

  void removeEquipa(String equipaId) {
    equipas.removeWhere((x) => x.id == equipaId);
    () async {
      await Supa.client.from('equipas').delete().eq('id', equipaId);
      await _loadEquipas();
    }();
  }

  void assignContabilistaToEquipa(String contabilistaId, String equipaId) {
    final eq = equipas.firstWhere((e) => e.id == equipaId);
    eq.contabilistaIds.add(contabilistaId);
    () async {
      await Supa.client
          .from('equipa_membros')
          .upsert({'equipa_id': equipaId, 'user_id': contabilistaId});
      await _loadEquipas();
    }();
  }

  void unassignContabilistaFromEquipa(String contabilistaId, String equipaId) {
    final eq = equipas.firstWhere((e) => e.id == equipaId);
    eq.contabilistaIds.remove(contabilistaId);
    () async {
      await Supa.client
          .from('equipa_membros')
          .delete()
          .match({'equipa_id': equipaId, 'user_id': contabilistaId});
      await _loadEquipas();
    }();
  }

  void assignEmpresaToEquipa(String empresaId, String equipaId) {
    final eq = equipas.firstWhere((e) => e.id == equipaId);
    eq.empresaIds.add(empresaId);
    () async {
      await Supa.client
          .from('equipa_empresas')
          .upsert({'equipa_id': equipaId, 'empresa_id': empresaId});
      await _loadEquipas();
    }();
  }

  void unassignEmpresaFromEquipa(String empresaId, String equipaId) {
    final eq = equipas.firstWhere((e) => e.id == equipaId);
    eq.empresaIds.remove(empresaId);
    () async {
      await Supa.client
          .from('equipa_empresas')
          .delete()
          .match({'equipa_id': equipaId, 'empresa_id': empresaId});
      await _loadEquipas();
    }();
  }
}
