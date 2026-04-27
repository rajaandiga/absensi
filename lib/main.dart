import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/absen_provider.dart';
import 'pages/auth/login_page.dart';
import 'pages/absen/absen_page.dart';
import 'pages/admin/admin_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const AbsensiBpsApp());
}

class AbsensiBpsApp extends StatelessWidget {
  const AbsensiBpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..cekStatusLogin()),
        ChangeNotifierProvider(create: (_) => AbsenProvider()),
      ],
      child: MaterialApp(
        title: 'Absensi BPS Jambi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _RootPage(),
      ),
    );
  }
}

/// Router utama — arahkan ke halaman yang sesuai berdasarkan status auth
class _RootPage extends StatefulWidget {
  const _RootPage();

  @override
  State<_RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<_RootPage> {
  // Pantau perubahan AuthProvider untuk tampilkan notif sesi habis
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();

    // Jika baru saja auto-logout karena sesi expired, tampilkan snackbar
    if (auth.sessionExpired &&
        auth.status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        auth.resetSessionExpired();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi habis, silakan login kembali.'),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 4),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        switch (auth.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const _SplashScreen();

          case AuthStatus.authenticated:
            if (auth.isAdmin) return const AdminDashboardPage();
            return const AbsenPage();

          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return const LoginPage();
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF7F77DD)),
            SizedBox(height: 16),
            Text(
              'Absensi BPS Jambi',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF5F5E5A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}