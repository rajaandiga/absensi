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
            onTap: _pilihBulan,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, size: 14,
                      color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM yyyy', 'id_ID').format(_bulanDipilih),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 13),
                  ),
                ],
              ),
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(Icons.event_busy,
                        size: 48,
                        color: AppColors.textHint.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada data absensi',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'id_ID').format(_bulanDipilih),
                    style: const TextStyle(color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }

          final hadir = absen.riwayat
              .where((a) => a.status == StatusAbsen.hadir)
              .length;
          final terlambat = absen.riwayat
              .where((a) => a.status == StatusAbsen.terlambat)
              .length;
          final izin = absen.riwayat
              .where((a) => a.status == StatusAbsen.izin)
              .length;
          final sakit = absen.riwayat
              .where((a) => a.status == StatusAbsen.sakit)
              .length;

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
                      'Rekap ${DateFormat('MMMM yyyy', 'id_ID').format(_bulanDipilih)}',
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
                            label: 'Hadir',
                            nilai: hadir,
                            warna: AppColors.success),
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
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: warna,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textOnDarkSecondary,
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
          // Tanggal box
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
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _warnaStatus.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _warnaStatus.withOpacity(0.3), width: 1),
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
