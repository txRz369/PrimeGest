import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

/// ======= CREDENCIAIS DO TEU PROJECTO =======
const String SUPABASE_URL = 'https://qxjxtadslgwkqibszqcr.supabase.co';
const String SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4anh0YWRzbGd3a3FpYnN6cWNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcyNjM5NTUsImV4cCI6MjA3MjgzOTk1NX0.HurCX5klQGuObyrUqnr6bapdUMnvfQHekg_rJE5NTwM';
const String LOGO_BUCKET = 'logos';

class Supa {
  static late SupabaseClient client;

  static Future<void> init() async {
    await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);
    client = Supabase.instance.client;
  }

  // ---------- Auth ----------
  static bool get loggedIn => client.auth.currentSession != null;
  static String? get email => client.auth.currentUser?.email;

  static Future<AuthResponse> signIn(String email, String pass) =>
      client.auth.signInWithPassword(email: email, password: pass);

  static Future<void> signOut() => client.auth.signOut();

  /// Re-adicionado para o teu main.dart
  static void onAuthStateChange(void Function(Session?) cb) {
    client.auth.onAuthStateChange.listen((data) => cb(data.session));
  }

  // ---------- Accountants ----------
  static Future<List<Accountant>> fetchAccountants() async {
    final res = await client.from('accountants').select().order('name');
    return (res as List).map((m) => Accountant.fromMap(m)).toList();
  }

  static Future<String> createAccountant(Accountant a) async {
    final inserted = await client
        .from('accountants')
        .insert(a.toMapInsert())
        .select()
        .single();
    return inserted['id'] as String;
  }

  static Future<Accountant?> fetchMyAccountant() async {
    final e = email;
    if (e == null) return null;
    final res =
        await client.from('accountants').select().eq('email', e).maybeSingle();
    if (res == null) return null;
    return Accountant.fromMap(res);
  }

  // ---------- Teams ----------
  static Future<List<Team>> fetchTeams() async {
    final res = await client.from('teams').select().order('name');
    return (res as List).map((m) => Team.fromMap(m)).toList();
  }

  static Future<void> ensureDefaultTeams() async {
    final res = await client.from('teams').select('id').limit(1);
    if ((res as List).isEmpty) {
      await client.from('teams').insert([
        {'name': 'Equipa A'},
        {'name': 'Equipa B'},
        {'name': 'Equipa C'},
        {'name': 'Equipa D'},
      ]);
    }
  }

  static Future<void> updateTeam(Team t) async {
    await client.from('teams').update(t.toMapUpdate()).eq('id', t.id);
  }

  static Future<void> upsertTeamMembers(
      String teamId, List<String> accountantIds) async {
    await client.from('team_members').delete().eq('team_id', teamId);
    if (accountantIds.isEmpty) return;
    await client.from('team_members').insert([
      for (final id in accountantIds) {'team_id': teamId, 'accountant_id': id}
    ]);
  }

  static Future<void> upsertTeamCompanies(
      String teamId, List<String> companyIds) async {
    await client.from('team_companies').delete().eq('team_id', teamId);
    if (companyIds.isEmpty) return;
    await client.from('team_companies').insert([
      for (final id in companyIds) {'team_id': teamId, 'company_id': id}
    ]);
  }

  static Future<List<String>> teamMembersIds(String teamId) async {
    final res = await client
        .from('team_members')
        .select('accountant_id')
        .eq('team_id', teamId);
    return (res as List).map((e) => e['accountant_id'] as String).toList();
  }

  static Future<List<String>> teamCompanyIds(String teamId) async {
    final res = await client
        .from('team_companies')
        .select('company_id')
        .eq('team_id', teamId);
    return (res as List).map((e) => e['company_id'] as String).toList();
  }

  static Future<List<String>> teamCompanyIdsForMe() async {
    final acc = await fetchMyAccountant();
    if (acc == null) return [];
    final rows = await client
        .from('team_members')
        .select('team_id')
        .eq('accountant_id', acc.id);
    final teamIds = (rows as List).map((m) => m['team_id'] as String).toList();

    if (teamIds.isEmpty) return [];
    final ids = <String>{};
    for (final t in teamIds) {
      final tc = await client
          .from('team_companies')
          .select('company_id')
          .eq('team_id', t);
      ids.addAll((tc as List).map((m) => m['company_id'] as String));
    }
    return ids.toList();
  }

  // ---------- Companies ----------
  static Future<List<Company>> fetchCompanies(
      {String? search, List<String>? inIds}) async {
    final res = await client
        .from('companies')
        .select()
        .order('importance', ascending: false);
    var list = (res as List).map((m) => Company.fromMap(m)).toList();

    if (inIds != null && inIds.isNotEmpty) {
      list = list.where((c) => inIds.contains(c.id)).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = search.toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(s)).toList();
    }

    for (final c in list) {
      final t = await client
          .from('company_tasks')
          .select('task_key,responsible_id')
          .eq('company_id', c.id);
      final arr = (t as List);
      c.taskKeys = arr.map((e) => e['task_key'] as String).toList();
      c.taskResponsibleByKey = {
        for (final e in arr)
          e['task_key'] as String: e['responsible_id'] as String?
      };
    }
    return list;
  }

  static Future<String> createCompany(Company c, {String? teamId}) async {
    final inserted = await client
        .from('companies')
        .insert(c.toMapInsert())
        .select()
        .single();
    final id = inserted['id'] as String;

    if (c.taskKeys.isNotEmpty) {
      await client.from('company_tasks').insert([
        for (final k in c.taskKeys)
          {
            'company_id': id,
            'task_key': k,
            'responsible_id': c.taskResponsibleByKey[k]
          }
      ]);
    }
    if (teamId != null) {
      await client
          .from('team_companies')
          .upsert({'team_id': teamId, 'company_id': id});
    }
    return id;
  }

  static Future<void> updateCompany(Company c, {String? teamId}) async {
    await client.from('companies').update(c.toMapUpdate()).eq('id', c.id);
    await client.from('company_tasks').delete().eq('company_id', c.id);
    if (c.taskKeys.isNotEmpty) {
      await client.from('company_tasks').insert([
        for (final k in c.taskKeys)
          {
            'company_id': c.id,
            'task_key': k,
            'responsible_id': c.taskResponsibleByKey[k]
          }
      ]);
    }
    if (teamId != null) {
      await client.from('team_companies').delete().eq('company_id', c.id);
      await client
          .from('team_companies')
          .upsert({'team_id': teamId, 'company_id': c.id});
    }
  }

  // ---------- Storage (logos / imagens de equipa) ----------
  static Future<String> uploadLogo(Uint8List bytes, String filename) async {
    final path = '${DateTime.now().millisecondsSinceEpoch}_$filename';
    await client.storage.from(LOGO_BUCKET).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/*'),
        );
    return client.storage.from(LOGO_BUCKET).getPublicUrl(path);
  }

  // ---------- Task instances (batch) ----------
  static Future<Map<String, List<TaskInstance>>>
      fetchInstancesForCompaniesMonth(
          List<String> companyIds, int year, int month) async {
    if (companyIds.isEmpty) return {};

    final assigned = await client
        .from('company_tasks')
        .select('company_id,task_key,responsible_id')
        .inFilter('company_id', companyIds);

    final existing = await client
        .from('task_instances')
        .select('company_id,task_key')
        .eq('year', year)
        .eq('month', month)
        .inFilter('company_id', companyIds);

    final existingSet = <String>{};
    for (final r in (existing as List)) {
      existingSet.add('${r['company_id']}|${r['task_key']}');
    }

    final toUpsert = <Map<String, dynamic>>[];
    for (final a in (assigned as List)) {
      final key = '${a['company_id']}|${a['task_key']}';
      if (!existingSet.contains(key)) {
        toUpsert.add({
          'company_id': a['company_id'],
          'task_key': a['task_key'],
          'year': year,
          'month': month,
          'done': false,
          'responsible_id': a['responsible_id'],
        });
      }
    }
    if (toUpsert.isNotEmpty) {
      await client
          .from('task_instances')
          .upsert(toUpsert, onConflict: 'company_id,task_key,year,month');
    }

    final rows = await client
        .from('task_instances')
        .select()
        .eq('year', year)
        .eq('month', month)
        .inFilter('company_id', companyIds);

    final map = <String, List<TaskInstance>>{};
    for (final m in (rows as List)) {
      final ti = TaskInstance.fromMap(m);
      map.putIfAbsent(ti.companyId, () => []).add(ti);
    }

    map.forEach((_, list) {
      list.sort((a, b) {
        final ta = defaultTaskByKey(a.taskKey)?.defaultImportance ?? 0;
        final tb = defaultTaskByKey(b.taskKey)?.defaultImportance ?? 0;
        return tb.compareTo(ta);
      });
    });

    return map;
  }

  static Future<void> upsertInstance(TaskInstance i) async {
    await client.from('task_instances').upsert(
          i.toMap(),
          onConflict: 'company_id,task_key,year,month',
        );
  }

  static Future<DashboardCounts> counts({
    required int year,
    required int month,
    List<String>? inCompanyIds,
  }) async {
    final res = await client
        .from('task_instances')
        .select('done, company_id')
        .eq('year', year)
        .eq('month', month);
    int pending = 0, done = 0;
    for (final r in (res as List)) {
      final cid = r['company_id'] as String;
      if (inCompanyIds != null &&
          inCompanyIds.isNotEmpty &&
          !inCompanyIds.contains(cid)) continue;
      (r['done'] as bool) ? done++ : pending++;
    }
    int companiesCount = 0;
    if (inCompanyIds != null && inCompanyIds.isNotEmpty) {
      companiesCount = inCompanyIds.length;
    } else {
      final cs = await client.from('companies').select('id');
      companiesCount = (cs as List).length;
    }
    return DashboardCounts(
        companies: companiesCount, pending: pending, completed: done);
  }
}
