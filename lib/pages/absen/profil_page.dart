import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/pegawai_model.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pegawai = context.watch<AuthProvider>().pegawai;
    if (pegawai == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar besar
            const SizedBox(height: 8),
            _AvatarBesar(pegawai: pegawai),
            const SizedBox(height: 20),

            // Info detail
            _KartuInfo(pegawai: pegawai),
            const SizedBox(height: 12),

            // Aksi
            _KartuAksi(context: context),
          ],
        ),
      ),
    );
  }
}

class _AvatarBesar extends StatelessWidget {
  final Pegawai pegawai;
  const _AvatarBesar({required this.pegawai});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySurface,
            border: Border.all(color: AppColors.primaryLight, width: 2),
          ),
          child: Center(
            child: Text(
              pegawai.nama.isNotEmpty ? pegawai.nama[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          pegawai.nama,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: pegawai.isAdmin
                ? AppColors.primarySurface
                : AppColors.successSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            pegawai.isAdmin ? 'Administrator' : pegawai.labelTipe,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: pegawai.isAdmin ? AppColors.primaryDark : AppColors.success,
            ),
          ),
        ),
      ],
    );
  }
}

class _KartuInfo extends StatelessWidget {
  final Pegawai pegawai;
  const _KartuInfo({required this.pegawai});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Akun',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _InfoBaris(
              icon: Icons.badge_outlined,
              label: 'NIP / NIM',
              nilai: pegawai.nip,
            ),
            const Divider(height: 16),
            _InfoBaris(
              icon: Icons.email_outlined,
              label: 'Email',
              nilai: pegawai.email.isNotEmpty ? pegawai.email : '-',
            ),
            const Divider(height: 16),
            _InfoBaris(
              icon: Icons.work_outline,
              label: 'Jabatan',
              nilai: pegawai.jabatan.isNotEmpty ? pegawai.jabatan : '-',
            ),
            const Divider(height: 16),
            _InfoBaris(
              icon: Icons.business_outlined,
              label: 'Unit Kerja',
              nilai: pegawai.unitKerja.isNotEmpty ? pegawai.unitKerja : '-',
            ),
            const Divider(height: 16),
            _InfoBaris(
              icon: Icons.person_outline,
              label: 'Tipe',
              nilai: pegawai.labelTipe,
            ),
          ],
        ),
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
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textHint),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
              Text(nilai,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _KartuAksi extends StatelessWidget {
  final BuildContext context;
  const _KartuAksi({required this.context});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
            title: const Text('Ganti Password',
                style: TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 20),
            onTap: () => _dialogGantiPassword(context),
          ),
          const Divider(height: 0, indent: 52),
          ListTile(
            leading:
            const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Keluar',
                style: TextStyle(fontSize: 14, color: AppColors.error)),
            onTap: () => _konfirmasiLogout(context),
          ),
        ],
      ),
    );
  }

  void _dialogGantiPassword(BuildContext ctx) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldCtrl,
                obscureText: true,
                decoration:
                const InputDecoration(labelText: 'Password lama'),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 10),
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                // TODO: panggil API ganti password
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Fitur ganti password akan tersedia setelah backend terhubung')),
                );
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
        title: const Text('Keluar'),
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
