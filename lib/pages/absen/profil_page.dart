import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
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
                  _KartuStatistikBulanIni(pegawaiId: pegawai.id),
                  const SizedBox(height: 12),
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
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
            ),
            child: Center(
              child: Text(
                pegawai.nama.isNotEmpty ? pegawai.nama[0].toUpperCase() : '?',
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                color: pegawai.isAdmin ? AppColors.textOnDark : AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu Statistik Absensi Bulan Ini ────────────────────────────────────────
class _KartuStatistikBulanIni extends StatefulWidget {
  final String pegawaiId;
  const _KartuStatistikBulanIni({required this.pegawaiId});

  @override
  State<_KartuStatistikBulanIni> createState() => _KartuStatistikBulanIniState();
}

class _KartuStatistikBulanIniState extends State<_KartuStatistikBulanIni> {
  final _api = ApiService();
  bool _loading = true;
  Map<String, int> _stats = {};
  int _hariKerja = 0;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final mulai = DateTime(now.year, now.month, 1);
      final data = await _api.getRiwayatAbsenRentang(
        pegawaiId: widget.pegawaiId,
        tanggalMulai: mulai,
        tanggalSelesai: now,
      );

      final counts = <String, int>{
        'hadir': 0, 'terlambat': 0, 'izin': 0, 'sakit': 0, 'alpha': 0,
      };
      for (final item in data) {
        final status = (item as Map<String, dynamic>)['status'] as String? ?? '';
        if (counts.containsKey(status)) counts[status] = (counts[status] ?? 0) + 1;
      }

      // Hitung hari kerja bulan ini sampai hari ini
      int hk = 0;
      DateTime tgl = mulai;
      while (!tgl.isAfter(now)) {
        if (tgl.weekday >= 1 && tgl.weekday <= 5) hk++;
        tgl = tgl.add(const Duration(days: 1));
      }

      setState(() {
        _stats = counts;
        _hariKerja = hk;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bulan = DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());
    final hadir = (_stats['hadir'] ?? 0) + (_stats['terlambat'] ?? 0);
    final persen = _hariKerja == 0 ? 0.0 : hadir / _hariKerja * 100;

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
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Statistik Absensi — $bulan',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ),
                if (!_loading)
                  GestureDetector(
                    onTap: _muat,
                    child: const Icon(Icons.refresh, size: 16, color: AppColors.textHint),
                  ),
              ],
            ),
          ),
          const Divider(height: 0),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Persentase kehadiran
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${persen.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: persen >= 80 ? AppColors.success : AppColors.warning,
                              ),
                            ),
                            const Text('Kehadiran bulan ini',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text('$hadir / $_hariKerja',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                            const Text('Hari hadir',
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _hariKerja == 0 ? 0 : hadir / _hariKerja,
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(
                        persen >= 80 ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Baris statistik detail
                  Row(
                    children: [
                      _StatMini(label: 'Tepat Waktu', nilai: _stats['hadir'] ?? 0, warna: AppColors.success),
                      _StatMini(label: 'Terlambat', nilai: _stats['terlambat'] ?? 0, warna: AppColors.warning),
                      _StatMini(label: 'Izin', nilai: _stats['izin'] ?? 0, warna: AppColors.primary),
                      _StatMini(label: 'Sakit', nilai: _stats['sakit'] ?? 0, warna: AppColors.primaryLight),
                      _StatMini(label: 'Alpha', nilai: _stats['alpha'] ?? 0, warna: AppColors.error),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final int nilai;
  final Color warna;
  const _StatMini({required this.label, required this.nilai, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$nilai',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: warna)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Kartu Info ─────────────────────────────────────────────────────────────────
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
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Informasi Akun',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 0),
          _InfoBaris(icon: Icons.badge_outlined, label: 'NIM', nilai: pegawai.nip),
          const Divider(height: 0, indent: 52),
          _InfoBaris(
              icon: Icons.email_outlined,
              label: 'Email',
              nilai: pegawai.email.isNotEmpty ? pegawai.email : '-'),
          const Divider(height: 0, indent: 52),
          _InfoBaris(
              icon: Icons.work_outline,
              label: 'Program Studi',
              nilai: pegawai.jabatan.isNotEmpty ? pegawai.jabatan : '-'),
          const Divider(height: 0, indent: 52),
          _InfoBaris(
              icon: Icons.business_outlined,
              label: 'Unit Kerja',
              nilai: pegawai.unitKerja.isNotEmpty ? pegawai.unitKerja : '-'),
          const Divider(height: 0, indent: 52),
          _InfoBaris(
              icon: Icons.school_outlined,
              label: 'Status',
              nilai: pegawai.labelTipe),
        ],
      ),
    );
  }
}

class _InfoBaris extends StatelessWidget {
  final IconData icon;
  final String label;
  final String nilai;

  const _InfoBaris({required this.icon, required this.label, required this.nilai});

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
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
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

// ── Kartu Aksi ────────────────────────────────────────────────────────────────
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
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
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            ),
            title: const Text('Keluar',
                style: TextStyle(fontSize: 14, color: AppColors.error,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                decoration: const InputDecoration(labelText: 'Password baru'),
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
                decoration: const InputDecoration(labelText: 'Konfirmasi password baru'),
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
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                final api = ApiService();
                try {
                  await api.gantiPassword(passwordBaru: newCtrl.text);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Password berhasil diubah! 🎉')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Gagal: ${e.toString()}')),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, minimumSize: const Size(80, 40)),
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