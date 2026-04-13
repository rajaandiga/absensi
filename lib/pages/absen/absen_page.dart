import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/absen_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/lokasi_service.dart';
import '../../data/models/absensi_model.dart';
import 'riwayat_page.dart';
import 'izin_page.dart';
import 'profil_page.dart';
import 'kalender_page.dart';

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  int _navIndex = 0;

  final List<Widget> _pages = const [
    _BerandaAbsen(),
    IzinPage(),
    KalenderPage(),
    RiwayatPage(),
    ProfilPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pegawai = context.read<AuthProvider>().pegawai;
      if (pegawai != null) {
        final provider = context.read<AbsenProvider>();
        provider.muatStatusHariIni(pegawai.id);
        provider.muatJadwalWfh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _navIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primarySurface,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'Izin',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Kalender',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Beranda ───────────────────────────────────────────────────────────────────
class _BerandaAbsen extends StatelessWidget {
  const _BerandaAbsen();

  @override
  Widget build(BuildContext context) {
    final pegawai = context.watch<AuthProvider>().pegawai;
    if (pegawai == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header ──────────────────────────────────────────
              _HeroHeader(pegawai: pegawai),
              // ── Body Content ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  children: [
                    _BannerWfh(),
                    _KartuStatusHariIni(),
                    const SizedBox(height: 16),
                    _TombolAbsen(pegawai: pegawai),
                    const SizedBox(height: 16),
                    _InfoValidasi(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Header dengan dark card ──────────────────────────────────────────────
class _HeroHeader extends StatefulWidget {
  final dynamic pegawai;
  const _HeroHeader({required this.pegawai});

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader> {
  late Timer _timer;
  late DateTime _sekarang;

  @override
  void initState() {
    super.initState();
    _sekarang = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _sekarang = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _sapaanWaktu() {
    final jam = _sekarang.hour;
    if (jam < 11) return 'Selamat Pagi';
    if (jam < 15) return 'Selamat Siang';
    if (jam < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final jam = DateFormat('HH:mm').format(_sekarang);
    final detik = DateFormat('ss').format(_sekarang);
    final tanggal =
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_sekarang);

    return Container(
      width: double.infinity,
      color: AppColors.cardDark,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: greeting + notif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sapaanWaktu(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                  Text(
                    widget.pegawai.nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.textOnDarkSecondary),
                    onPressed: () => _lihatNotifikasi(context),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.pegawai.nama.isNotEmpty
                            ? widget.pegawai.nama[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Clock
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                jam,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textOnDark,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  ':$detik',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textOnDarkSecondary,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mahasiswa Magang',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tanggal,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _lihatNotifikasi(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Notifikasi',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            const _NotifikasiItem(
              icon: Icons.info_outline,
              warna: AppColors.primary,
              judul: 'Pengingat absen',
              isi: 'Jangan lupa absen masuk sebelum jam 07:30 WIB.',
            ),
            const SizedBox(height: 8),
            const _NotifikasiItem(
              icon: Icons.check_circle_outline,
              warna: AppColors.success,
              judul: 'Sistem aktif',
              isi: 'Validasi GPS & WiFi berjalan normal.',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner WFH ────────────────────────────────────────────────────────────────
class _BannerWfh extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final absen = context.watch<AbsenProvider>();
    if (!absen.hariIniWfh) return const SizedBox.shrink();

    final namaHari = absen.jadwalWfh
        .where((j) => j.aktif && j.weekday == DateTime.now().weekday)
        .map((j) => j.namaHari)
        .firstOrNull ??
        'Hari ini';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_work_outlined,
                size: 18, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$namaHari — Mode WFH',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4ED8)),
                ),
                const Text(
                  'Kamu bisa absen dari mana saja. Validasi lokasi tidak diperlukan.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifikasiItem extends StatelessWidget {
  final IconData icon;
  final Color warna;
  final String judul;
  final String isi;

  const _NotifikasiItem({
    required this.icon,
    required this.warna,
    required this.judul,
    required this.isi,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: warna.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: warna),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(isi,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Kartu Status Hari Ini ─────────────────────────────────────────────────────
class _KartuStatusHariIni extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AbsenProvider>(
      builder: (_, absen, __) {
        final fmt = DateFormat('HH:mm');
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Kehadiran Hari Ini',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  if (absen.hariIniWfh) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('WFH',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatusItem(
                    label: 'Jam Masuk',
                    nilai: absen.sudahAbsenMasuk && absen.waktuMasuk != null
                        ? fmt.format(absen.waktuMasuk!)
                        : '—',
                    warna: absen.sudahAbsenMasuk
                        ? AppColors.success
                        : AppColors.textHint,
                    icon: Icons.login_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatusItem(
                    label: 'Jam Pulang',
                    nilai:
                    absen.sudahAbsenPulang && absen.waktuPulang != null
                        ? fmt.format(absen.waktuPulang!)
                        : '—',
                    warna: absen.sudahAbsenPulang
                        ? AppColors.success
                        : AppColors.textHint,
                    icon: Icons.logout_rounded,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String nilai;
  final Color warna;
  final IconData icon;

  const _StatusItem({
    required this.label,
    required this.nilai,
    required this.warna,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: warna == AppColors.textHint
              ? AppColors.background
              : warna.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: warna == AppColors.textHint
                ? AppColors.border
                : warna.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: warna),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              nilai,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: warna,
                  letterSpacing: -0.5),
            ),
            if (nilai != '—')
              const Text('WIB',
                  style:
                  TextStyle(fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

// ── Tombol Absen ──────────────────────────────────────────────────────────────
class _TombolAbsen extends StatelessWidget {
  final dynamic pegawai;
  const _TombolAbsen({required this.pegawai});

  @override
  Widget build(BuildContext context) {
    return Consumer<AbsenProvider>(
      builder: (_, absen, __) {
        if (absen.status == AbsenStatus.memvalidasi) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(absen.pesan,
                    textAlign: TextAlign.center,
                    style:
                    const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('Jangan tutup aplikasi',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          );
        }

        if (absen.status == AbsenStatus.berhasil ||
            absen.status == AbsenStatus.gagal) {
          return Column(
            children: [
              _HasilValidasiCard(
                berhasil: absen.status == AbsenStatus.berhasil,
                pesan: absen.pesan,
                hasilValidasi: absen.hasilValidasi,
                isWfh: absen.hariIniWfh,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => absen.reset(),
                child: const Text('OK'),
              ),
            ],
          );
        }

        if (absen.sudahAbsenMasuk && absen.sudahAbsenPulang) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(16),
              border:
              Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success, size: 40),
                ),
                const SizedBox(height: 12),
                const Text('Absensi Hari Ini Selesai',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
                const SizedBox(height: 4),
                const Text('Sampai jumpa besok!',
                    style:
                    TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        final isWfh = absen.hariIniWfh;
        final labelTombol =
        absen.sudahAbsenMasuk ? 'Absen Pulang' : 'Absen Masuk';
        final ikonTombol = absen.sudahAbsenMasuk
            ? Icons.logout_rounded
            : (isWfh
            ? Icons.home_work_outlined
            : Icons.login_rounded);

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => absen.absen(pegawai),
            icon: Icon(ikonTombol),
            label:
            Text(isWfh ? '$labelTombol (WFH)' : labelTombol),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: absen.sudahAbsenMasuk
                  ? AppColors.cardDark
                  : AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HasilValidasiCard extends StatelessWidget {
  final bool berhasil;
  final String pesan;
  final HasilValidasiLokasi? hasilValidasi;
  final bool isWfh;

  const _HasilValidasiCard({
    required this.berhasil,
    required this.pesan,
    this.hasilValidasi,
    this.isWfh = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
    berhasil ? AppColors.successSurface : AppColors.errorSurface;
    final iconColor = berhasil ? AppColors.success : AppColors.error;
    final icon = berhasil
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Text(
                berhasil ? 'Absen Berhasil!' : 'Absen Gagal',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(pesan,
              style: TextStyle(fontSize: 13, color: iconColor)),
          if (berhasil) ...[
            const SizedBox(height: 10),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isWfh
                    ? 'Metode: WFH (bypass lokasi)'
                    : 'Metode: ${hasilValidasi?.metode == MetodeValidasiLokasi.wifi ? "WiFi Kantor" : "GPS"}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Info Validasi ─────────────────────────────────────────────────────────────
class _InfoValidasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWfh = context.watch<AbsenProvider>().hariIniWfh;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Text('Sistem Validasi',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          if (isWfh)
            const _InfoRow(
              icon: Icons.home_work_outlined,
              warna: Color(0xFF3B82F6),
              judul: 'Mode WFH Aktif',
              deskripsi:
              'Validasi GPS & WiFi tidak diperlukan hari ini.',
            )
          else ...[
            const _InfoRow(
              icon: Icons.gps_fixed_rounded,
              warna: AppColors.success,
              judul: 'Lapis 1 — GPS',
              deskripsi: 'Cek koordinat dalam radius 50m kantor BPS',
            ),
            const SizedBox(height: 10),
            const _InfoRow(
              icon: Icons.wifi_rounded,
              warna: Color(0xFF3B82F6),
              judul: 'Lapis 2 — WiFi',
              deskripsi: 'Fallback otomatis jika GPS lemah di dalam gedung',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color warna;
  final String judul;
  final String deskripsi;

  const _InfoRow({
    required this.icon,
    required this.warna,
    required this.judul,
    required this.deskripsi,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: warna.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: warna),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(deskripsi,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
