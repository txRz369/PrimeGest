import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'supabase_service.dart';
import 'home_shell.dart';
import 'login_screen.dart';
import 'data_seed.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supa.init();
  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _notifications = false;

  @override
  void initState() {
    super.initState();
    Supa.onAuthStateChange((session) async {
      if (session != null) {
        await seedDefaults();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final logged = Supa.loggedIn;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controlo Tarefas',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: logged
          ? HomeShell(
              onToggleTheme: () => setState(() {
                _themeMode = _themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
              }),
              notifications: _notifications,
              onToggleNotifications: () =>
                  setState(() => _notifications = !_notifications),
            )
          : LoginScreen(
              onLoggedIn: () => setState(() {}),
            ),
    );
  }
}
