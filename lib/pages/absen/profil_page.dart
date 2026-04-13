import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/pegawai_model.dart';
import '../../data/services/api_service.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pegawai = context.watch<AuthProvider>().pegawai;
    if (pegawai == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfilHeader(pegawai: pegawai),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _KartuInfo(pegawai: pegawai),
                  const SizedBox(height: 12),
                  _KartuAksi(context: context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilHeader extends StatelessWidget {
  final Pegawai pegawai;
  const _ProfilHeader({required this.pegawai});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.cardDark,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.2), width: 3),
            ),
            child: Center(
              child: Text(
                pegawai.nama.isNotEmpty
                    ? pegawai.nama[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            pegawai.nama,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDark,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: pegawai.isAdmin
                  ? Colors.white.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pegawai.isAdmin ? 'Administrator' : 'Mahasiswa Magang',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: pegawai.isAdmin
                    ? AppColors.textOnDark
                    : AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuInfo extends StatelessWidget {
  final Pegawai pegawai;
  const _KartuInfo({required this.pegawai});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Informasi Akun',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          _InfoBaris(
              icon: Icons.badge_outlined,
              label: 'NIM',
              nilai: pegawai.nip),
          const Divider(height: 0, indent: 52),
          _InfoBaris(
              icon: Icons.email_outlined,
              label: 'Email',
              nilai:
              pegawai.email.isNotEmpty ? pegawai.email : '-'),
          const Divider(height: 0, indent: 52),
          _InfoBaris(
              icon: Icons.work_outline,
              label: 'Program Studi',
              nilai: pegawai.jabatan.isNotEmpty
                  ? pegawai.jabatan
                  : '-'),
          const Divider(height: 0, indent: 52),
          _InfoBaris(
              icon: Icons.business_outlined,
              label: 'Unit Kerja',
              nilai: pegawai.unitKerja.isNotEmpty
                  ? pegawai.unitKerja
                  : '-'),
          const Divider(height: 0, indent: 52),
          _InfoBaris(
              icon: Icons.school_outlined,
              label: 'Status',
              nilai: 'Mahasiswa Magang'),
        ],
      ),
    );
  }
}

class _InfoBaris extends StatelessWidget {
  final IconData icon;
  final String label;
  final String nilai;

  const _InfoBaris({
    required this.icon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
                Text(nilai,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuAksi extends StatelessWidget {
  final BuildContext context;
  const _KartuAksi({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline,
                  color: AppColors.textSecondary, size: 18),
            ),
            title: const Text('Ganti Password',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 20),
            onTap: () => _dialogGantiPassword(context),
          ),
          const Divider(height: 0, indent: 60),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.error, size: 18),
            ),
            title: const Text('Keluar',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500)),
            onTap: () => _konfirmasiLogout(context),
          ),
        ],
      ),
    );
  }

  void _dialogGantiPassword(BuildContext ctx) {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Ganti Password',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration:
                const InputDecoration(labelText: 'Password baru'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (v.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Konfirmasi password baru'),
                validator: (v) {
                  if (v != newCtrl.text) return 'Password tidak cocok';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 40)),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                final api = ApiService();
                try {
                  await api.gantiPassword(passwordBaru: newCtrl.text);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text('Password berhasil diubah! 🎉')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                          content: Text('Gagal: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _konfirmasiLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(80, 40)),
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<AuthProvider>().logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
