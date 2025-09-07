import 'supabase_service.dart';

Future<void> seedDefaults() async {
  final existing = await Supa.client.from('teams').select('id,name');
  if ((existing as List).isEmpty) {
    await Supa.client.from('teams').insert([
      {'name': 'Equipa A'},
      {'name': 'Equipa B'},
      {'name': 'Equipa C'},
      {'name': 'Equipa D'},
    ]);
  }
}
