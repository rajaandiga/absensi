import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/absen_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/absensi_model.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  DateTime _bulanDipilih = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muat());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data setiap kali halaman ini aktif kembali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _muat();
    });
  }

  void _muat() {
    final pegawai = context.read<AuthProvider>().pegawai;
    if (pegawai == null) return;
    context.read<AbsenProvider>().muatRiwayat(
      pegawaiId: pegawai.id,
      bulan: _bulanDipilih.month,
      tahun: _bulanDipilih.year,
    );
  }

  Future<void> _pilihBulan() async {
    final sekarang = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _bulanDipilih,
      firstDate: DateTime(2024),
      lastDate: sekarang,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && mounted) {
      setState(() => _bulanDipilih = picked);
      _muat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        actions: [
          TextButton.icon(
            onPressed: _pilihBulan,
            icon: const Icon(Icons.calendar_month, size: 16),
            label: Text(
              DateFormat('MMM yyyy', 'id_ID').format(_bulanDipilih),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: Consumer<AbsenProvider>(
        builder: (_, absen, __) {
          if (absen.loadingRiwayat) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (absen.riwayat.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy,
                      size: 64, color: AppColors.textHint.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada data absensi\n${DateFormat('MMMM yyyy', 'id_ID').format(_bulanDipilih)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }

          // Rekap ringkas di atas
          final hadir = absen.riwayat
              .where((a) => a.status == StatusAbsen.hadir).length;
          final terlambat = absen.riwayat
              .where((a) => a.status == StatusAbsen.terlambat).length;
          final izin = absen.riwayat
              .where((a) => a.status == StatusAbsen.izin).length;
          final sakit = absen.riwayat
              .where((a) => a.status == StatusAbsen.sakit).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Rekap kartu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekap ${DateFormat('MMMM yyyy', 'id_ID').format(_bulanDipilih)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _RekapChip(label: 'Hadir', nilai: hadir, warna: AppColors.success),
                          const SizedBox(width: 6),
                          _RekapChip(label: 'Terlambat', nilai: terlambat, warna: AppColors.warning),
                          const SizedBox(width: 6),
                          _RekapChip(label: 'Izin', nilai: izin, warna: AppColors.primary),
                          const SizedBox(width: 6),
                          _RekapChip(label: 'Sakit', nilai: sakit, warna: AppColors.primaryLight),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // List riwayat
              ...absen.riwayat.map((a) => _ItemRiwayat(absensi: a)),
            ],
          );
        },
      ),
    );
  }
}

class _RekapChip extends StatelessWidget {
  final String label;
  final int nilai;
  final Color warna;

  const _RekapChip({
    required this.label,
    required this.nilai,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: warna.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: warna.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              '$nilai',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: warna,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRiwayat extends StatelessWidget {
  final Absensi absensi;
  const _ItemRiwayat({required this.absensi});

  Color get _warnaStatus {
    switch (absensi.status) {
      case StatusAbsen.hadir: return AppColors.success;
      case StatusAbsen.terlambat: return AppColors.warning;
      case StatusAbsen.izin: return AppColors.primary;
      case StatusAbsen.sakit: return AppColors.primaryLight;
      case StatusAbsen.alpha: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    final fmtTgl = DateFormat('EEE, d MMM', 'id_ID');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Tanggal
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d').format(absensi.waktuMasuk),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    DateFormat('MMM', 'id_ID').format(absensi.waktuMasuk),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fmtTgl.format(absensi.waktuMasuk),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.login_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        fmt.format(absensi.waktuMasuk),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (absensi.waktuPulang != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.logout_rounded,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          fmt.format(absensi.waktuPulang!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _warnaStatus.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _warnaStatus.withOpacity(0.3), width: 0.5),
              ),
              child: Text(
                absensi.labelStatus,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _warnaStatus,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
