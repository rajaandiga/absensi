import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/absen_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/absensi_model.dart';
import '../../data/services/api_service.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  // Default: 1 bulan ke belakang dari hari ini
  late DateTime _tanggalMulai;
  late DateTime _tanggalSelesai;
  List<Absensi> _riwayat = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tanggalSelesai = now;
    _tanggalMulai = DateTime(now.year, now.month, 1); // awal bulan ini
    WidgetsBinding.instance.addPostFrameCallback((_) => _muat());
  }

  Future<void> _muat() async {
    final pegawai = context.read<AuthProvider>().pegawai;
    if (pegawai == null) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService().getRiwayatAbsenRentang(
        pegawaiId: pegawai.id,
        tanggalMulai: _tanggalMulai,
        tanggalSelesai: _tanggalSelesai,
      );
      setState(() {
        _riwayat = data
            .map((e) => Absensi.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      setState(() => _riwayat = []);
    }
    setState(() => _loading = false);
  }

  Future<void> _pilihRentang() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _tanggalMulai,
        end: _tanggalSelesai,
      ),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _tanggalMulai = picked.start;
        _tanggalSelesai = picked.end;
      });
      _muat();
    }
  }

  // Pilihan shortcut rentang
  void _setShortcut(String tipe) {
    final now = DateTime.now();
    DateTime mulai, selesai = now;
    switch (tipe) {
      case 'minggu':
        mulai = now.subtract(const Duration(days: 6));
        break;
      case 'bulan':
        mulai = DateTime(now.year, now.month, 1);
        break;
      case 'bulan_lalu':
        final bl = DateTime(now.year, now.month - 1, 1);
        mulai = bl;
        selesai = DateTime(now.year, now.month, 0);
        break;
      default:
        mulai = now;
    }
    setState(() {
      _tanggalMulai = mulai;
      _tanggalSelesai = selesai;
    });
    _muat();
  }

  String get _labelRentang {
    final fmt = DateFormat('d MMM', 'id_ID');
    final fmtThn = DateFormat('d MMM yyyy', 'id_ID');
    if (_tanggalMulai.year == _tanggalSelesai.year) {
      return '${fmt.format(_tanggalMulai)} – ${fmtThn.format(_tanggalSelesai)}';
    }
    return '${fmtThn.format(_tanggalMulai)} – ${fmtThn.format(_tanggalSelesai)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: AppColors.cardDark,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          GestureDetector(
            onTap: _pilihRentang,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    _labelRentang,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Shortcut chips
          Container(
            color: AppColors.cardDark,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ShortcutChip(
                    label: '7 Hari',
                    onTap: () => _setShortcut('minggu'),
                  ),
                  const SizedBox(width: 8),
                  _ShortcutChip(
                    label: 'Bulan Ini',
                    onTap: () => _setShortcut('bulan'),
                  ),
                  const SizedBox(width: 8),
                  _ShortcutChip(
                    label: 'Bulan Lalu',
                    onTap: () => _setShortcut('bulan_lalu'),
                  ),
                  const SizedBox(width: 8),
                  _ShortcutChip(
                    label: 'Pilih Rentang...',
                    icon: Icons.tune,
                    onTap: _pilihRentang,
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
                : _riwayat.isEmpty
                ? _emptyState()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(Icons.event_busy,
                size: 48, color: AppColors.textHint.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada data absensi',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            _labelRentang,
            style: const TextStyle(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final hadir =
        _riwayat.where((a) => a.status == StatusAbsen.hadir).length;
    final terlambat =
        _riwayat.where((a) => a.status == StatusAbsen.terlambat).length;
    final izin =
        _riwayat.where((a) => a.status == StatusAbsen.izin).length;
    final sakit =
        _riwayat.where((a) => a.status == StatusAbsen.sakit).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rekap kartu
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rekap $_labelRentang',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _RekapChip(
                      label: 'Hadir', nilai: hadir, warna: AppColors.success),
                  const SizedBox(width: 8),
                  _RekapChip(
                      label: 'Terlambat',
                      nilai: terlambat,
                      warna: AppColors.warning),
                  const SizedBox(width: 8),
                  _RekapChip(
                      label: 'Izin',
                      nilai: izin,
                      warna: const Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  _RekapChip(
                      label: 'Sakit',
                      nilai: sakit,
                      warna: AppColors.primaryLight),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._riwayat.map((a) => _ItemRiwayat(absensi: a)),
      ],
    );
  }
}

// ── Shortcut Chip ─────────────────────────────────────────────────────────────
class _ShortcutChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _ShortcutChip({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.white70),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rekap chip ────────────────────────────────────────────────────────────────
class _RekapChip extends StatelessWidget {
  final String label;
  final int nilai;
  final Color warna;

  const _RekapChip(
      {required this.label, required this.nilai, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: warna.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$nilai',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: warna),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textOnDarkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item Riwayat ──────────────────────────────────────────────────────────────
class _ItemRiwayat extends StatelessWidget {
  final Absensi absensi;
  const _ItemRiwayat({required this.absensi});

  Color get _warnaStatus {
    switch (absensi.status) {
      case StatusAbsen.hadir:
        return AppColors.success;
      case StatusAbsen.terlambat:
        return AppColors.warning;
      case StatusAbsen.izin:
        return const Color(0xFF3B82F6);
      case StatusAbsen.sakit:
        return AppColors.primaryLight;
      case StatusAbsen.alpha:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    final fmtTgl = DateFormat('EEE, d MMM', 'id_ID');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('d').format(absensi.waktuMasuk),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                Text(
                  DateFormat('MMM', 'id_ID').format(absensi.waktuMasuk),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fmtTgl.format(absensi.waktuMasuk),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.login_rounded,
                        size: 12, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      fmt.format(absensi.waktuMasuk),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (absensi.waktuPulang != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.logout_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        fmt.format(absensi.waktuPulang!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'via ${absensi.labelMetode}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _warnaStatus.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
              Border.all(color: _warnaStatus.withOpacity(0.3), width: 1),
            ),
            child: Text(
              absensi.labelStatus,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _warnaStatus,
              ),
            ),
          ),
        ],
      ),
    );
  }
}