import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/absen_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/absensi_model.dart';

class KalenderPage extends StatefulWidget {
  const KalenderPage({super.key});

  @override
  State<KalenderPage> createState() => _KalenderPageState();
}

class _KalenderPageState extends State<KalenderPage> {
  DateTime _bulanDipilih = DateTime.now();
  DateTime? _hariDipilih;

  @override
  void initState() {
    super.initState();
    _hariDipilih = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muat());
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

  void _gantibulan(int delta) {
    setState(() {
      _bulanDipilih = DateTime(
          _bulanDipilih.year, _bulanDipilih.month + delta, 1);
      _hariDipilih = null;
    });
    _muat();
  }

  /// Cari semua record absen pada tanggal tertentu
  List<Absensi> _absenUntukHari(List<Absensi> riwayat, DateTime hari) {
    return riwayat.where((a) {
      final tgl = a.waktuMasuk;
      return tgl.year == hari.year &&
          tgl.month == hari.month &&
          tgl.day == hari.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Absensi'),
      ),
      body: Consumer<AbsenProvider>(
        builder: (_, absen, __) {
          if (absen.loadingRiwayat) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final absenHariDipilih = _hariDipilih != null
              ? _absenUntukHari(absen.riwayat, _hariDipilih!)
              : <Absensi>[];

          return Column(
            children: [
              // ── Header bulan ──────────────────────────────────────────
              _HeaderBulan(
                bulan: _bulanDipilih,
                onPrev: () => _gantibulan(-1),
                onNext: () => _gantibulan(1),
              ),
              // ── Grid kalender ─────────────────────────────────────────
              _GridKalender(
                bulan: _bulanDipilih,
                riwayat: absen.riwayat,
                hariDipilih: _hariDipilih,
                onPilihHari: (tgl) => setState(() => _hariDipilih = tgl),
              ),
              const Divider(height: 1),
              // ── Detail hari yang dipilih ──────────────────────────────
              Expanded(
                child: _DetailHari(
                  hari: _hariDipilih,
                  absenList: absenHariDipilih,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Header navigasi bulan ─────────────────────────────────────────────────────
class _HeaderBulan extends StatelessWidget {
  final DateTime bulan;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _HeaderBulan({
    required this.bulan,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final sekarang = DateTime.now();
    final isFuture = DateTime(bulan.year, bulan.month + 1).isAfter(
        DateTime(sekarang.year, sekarang.month + 1));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
            color: AppColors.primary,
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy', 'id_ID').format(bulan),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isFuture ? null : onNext,
            color: isFuture ? AppColors.textHint : AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ── Grid kalender ─────────────────────────────────────────────────────────────
class _GridKalender extends StatelessWidget {
  final DateTime bulan;
  final List<Absensi> riwayat;
  final DateTime? hariDipilih;
  final ValueChanged<DateTime> onPilihHari;

  const _GridKalender({
    required this.bulan,
    required this.riwayat,
    required this.hariDipilih,
    required this.onPilihHari,
  });

  Color _warnaHari(List<Absensi> absenHari, bool isWeekend) {
    if (absenHari.isEmpty) {
      return isWeekend ? Colors.transparent : Colors.transparent;
    }
    final status = absenHari.first.status;
    switch (status) {
      case StatusAbsen.hadir:
        return AppColors.success.withOpacity(0.15);
      case StatusAbsen.terlambat:
        return AppColors.warning.withOpacity(0.15);
      case StatusAbsen.izin:
        return AppColors.primary.withOpacity(0.12);
      case StatusAbsen.sakit:
        return AppColors.primaryLight.withOpacity(0.15);
      case StatusAbsen.alpha:
        return AppColors.error.withOpacity(0.12);
    }
  }

  Color _dotWarna(StatusAbsen status) {
    switch (status) {
      case StatusAbsen.hadir:
        return AppColors.success;
      case StatusAbsen.terlambat:
        return AppColors.warning;
      case StatusAbsen.izin:
        return AppColors.primary;
      case StatusAbsen.sakit:
        return AppColors.primaryLight;
      case StatusAbsen.alpha:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sekarang = DateTime.now();
    final hariPertama = DateTime(bulan.year, bulan.month, 1);
    // Senin = 1, jadi offset = weekday - 1
    final offset = (hariPertama.weekday - 1) % 7;
    final jumlahHari = DateUtils.getDaysInMonth(bulan.year, bulan.month);

    const namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Header hari
          Row(
            children: namaHari.map((h) {
              final isWeekend = h == 'Sab' || h == 'Min';
              return Expanded(
                child: Center(
                  child: Text(
                    h,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isWeekend
                          ? AppColors.error.withOpacity(0.6)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          // Grid tanggal
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.85,
            ),
            itemCount: offset + jumlahHari,
            itemBuilder: (_, i) {
              if (i < offset) return const SizedBox.shrink();

              final hari = DateTime(bulan.year, bulan.month, i - offset + 1);
              final isWeekend = hari.weekday >= 6;
              final isHariIni = hari.year == sekarang.year &&
                  hari.month == sekarang.month &&
                  hari.day == sekarang.day;
              final isDipilih = hariDipilih != null &&
                  hari.year == hariDipilih!.year &&
                  hari.month == hariDipilih!.month &&
                  hari.day == hariDipilih!.day;
              final isFuture = hari.isAfter(sekarang);

              // Kumpulkan semua record absen di hari ini
              final absenHari = riwayat.where((a) {
                final tgl = a.waktuMasuk;
                return tgl.year == hari.year &&
                    tgl.month == hari.month &&
                    tgl.day == hari.day;
              }).toList();

              return GestureDetector(
                onTap: isFuture ? null : () => onPilihHari(hari),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isDipilih
                        ? AppColors.primary
                        : _warnaHari(absenHari, isWeekend),
                    borderRadius: BorderRadius.circular(8),
                    border: isHariIni && !isDipilih
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${hari.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isHariIni || isDipilih
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isDipilih
                              ? Colors.white
                              : isFuture
                              ? AppColors.textHint
                              : isWeekend
                              ? AppColors.error.withOpacity(0.7)
                              : AppColors.textPrimary,
                        ),
                      ),
                      // Dot indikator (satu dot per jenis absen di hari itu)
                      if (absenHari.isNotEmpty && !isDipilih) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: absenHari
                              .take(3)
                              .map((a) => Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 1),
                            decoration: BoxDecoration(
                              color: _dotWarna(a.status),
                              shape: BoxShape.circle,
                            ),
                          ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Legenda
          _Legenda(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('Hadir', AppColors.success),
      ('Terlambat', AppColors.warning),
      ('Izin', AppColors.primary),
      ('Sakit', AppColors.primaryLight),
      ('Alpha', AppColors.error),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.$2,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(item.$1,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        );
      }).toList(),
    );
  }
}

// ── Detail hari dipilih ───────────────────────────────────────────────────────
class _DetailHari extends StatelessWidget {
  final DateTime? hari;
  final List<Absensi> absenList;

  const _DetailHari({required this.hari, required this.absenList});

  @override
  Widget build(BuildContext context) {
    if (hari == null) {
      return const Center(
        child: Text('Pilih tanggal untuk melihat detail',
            style: TextStyle(color: AppColors.textHint)),
      );
    }

    final fmtTanggal = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    final fmtJam = DateFormat('HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            fmtTanggal.format(hari!),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
        ),
        if (absenList.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy,
                      size: 40, color: AppColors.textHint.withOpacity(0.4)),
                  const SizedBox(height: 8),
                  const Text('Tidak ada catatan absensi',
                      style: TextStyle(color: AppColors.textHint)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: absenList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final absen = absenList[i];
                const isLembur = false; // tidak ada fitur lembur
                final Color headerColor =
                    AppColors.primary;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label jenis absen
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: headerColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Absensi',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: headerColor,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _warnaStatus(absen.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                absen.labelStatus,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _warnaStatus(absen.status),
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Jam masuk dan pulang
                        Row(
                          children: [
                            _JamItem(
                              label: 'Masuk',
                              jam: fmtJam.format(absen.waktuMasuk),
                              icon: Icons.login_rounded,
                              warna: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            _JamItem(
                              label: 'Pulang',
                              jam: absen.waktuPulang != null
                                  ? fmtJam.format(absen.waktuPulang!)
                                  : '—',
                              icon: Icons.logout_rounded,
                              warna: absen.waktuPulang != null
                                  ? AppColors.primaryDark
                                  : AppColors.textHint,
                            ),
                            const Spacer(),
                            // Metode validasi
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('via',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textHint)),
                                Text(absen.labelMetode,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                        // Durasi kerja
                        if (absen.waktuPulang != null) ...[
                          const SizedBox(height: 8),
                          _DurasiBar(
                              masuk: absen.waktuMasuk,
                              pulang: absen.waktuPulang!),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Color _warnaStatus(StatusAbsen status) {
    switch (status) {
      case StatusAbsen.hadir:
        return AppColors.success;
      case StatusAbsen.terlambat:
        return AppColors.warning;
      case StatusAbsen.izin:
        return AppColors.primary;
      case StatusAbsen.sakit:
        return AppColors.primaryLight;
      case StatusAbsen.alpha:
        return AppColors.error;
    }
  }
}

class _JamItem extends StatelessWidget {
  final String label;
  final String jam;
  final IconData icon;
  final Color warna;

  const _JamItem({
    required this.label,
    required this.jam,
    required this.icon,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
        Row(
          children: [
            Icon(icon, size: 12, color: warna),
            const SizedBox(width: 4),
            Text(jam,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: warna)),
          ],
        ),
      ],
    );
  }
}

class _DurasiBar extends StatelessWidget {
  final DateTime masuk;
  final DateTime pulang;

  const _DurasiBar({required this.masuk, required this.pulang});

  @override
  Widget build(BuildContext context) {
    final durasi = pulang.difference(masuk);
    final jam = durasi.inHours;
    final menit = durasi.inMinutes.remainder(60);
    final teksD = jam > 0 ? '${jam}j ${menit}m' : '${menit} menit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('Durasi kerja: $teksD',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
