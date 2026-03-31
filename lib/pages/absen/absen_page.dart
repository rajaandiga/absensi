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
    RiwayatPage(),
    ProfilPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pegawai = context.read<AuthProvider>().pegawai;
      if (pegawai != null) {
        context.read<AbsenProvider>().muatStatusHariIni(pegawai.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
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
    );
  }
}

// ── Halaman beranda (tab pertama) ─────────────────────────────────────────────
class _BerandaAbsen extends StatelessWidget {
  const _BerandaAbsen();

  @override
  Widget build(BuildContext context) {
    final pegawai = context.watch<AuthProvider>().pegawai;
    if (pegawai == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _lihatNotifikasi(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KartuPegawai(pegawai: pegawai),
              const SizedBox(height: 16),
              _KartuStatusHariIni(),
              const SizedBox(height: 16),
              _TombolAbsen(pegawai: pegawai),
              const SizedBox(height: 16),
              _InfoValidasi(),
            ],
          ),
        ),
      ),
    );
  }

  void _lihatNotifikasi(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifikasi',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            const _NotifikasiItem(
              icon: Icons.info_outline,
              warna: AppColors.primary,
              judul: 'Pengingat absen',
              isi: 'Jangan lupa absen masuk sebelum jam 08:00 WIB.',
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
            borderRadius: BorderRadius.circular(8),
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
                      fontSize: 13, fontWeight: FontWeight.w500)),
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

// ── Kartu pegawai dengan jam real-time ────────────────────────────────────────
class _KartuPegawai extends StatefulWidget {
  final dynamic pegawai;
  const _KartuPegawai({required this.pegawai});

  @override
  State<_KartuPegawai> createState() => _KartuPegawaiState();
}

class _KartuPegawaiState extends State<_KartuPegawai> {
  late Timer _timer;
  late DateTime _sekarang;

  @override
  void initState() {
    super.initState();
    _sekarang = DateTime.now();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _sekarang = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jam = DateFormat('HH:mm:ss').format(_sekarang);
    final tanggal =
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_sekarang);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                widget.pegawai.nama.isNotEmpty
                    ? widget.pegawai.nama[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selamat datang,',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text(widget.pegawai.nama,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  Text(widget.pegawai.labelTipe,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(jam,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary)),
                Text(tanggal,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status hari ini ────────────────────────────────────────────────────────────
class _KartuStatusHariIni extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AbsenProvider>(
      builder: (_, absen, __) {
        final fmt = DateFormat('HH:mm');
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status hari ini',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatusItem(
                      label: 'Masuk',
                      nilai: absen.sudahAbsenMasuk &&
                          absen.waktuMasuk != null
                          ? fmt.format(absen.waktuMasuk!)
                          : '—',
                      warna: absen.sudahAbsenMasuk
                          ? AppColors.success
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 12),
                    _StatusItem(
                      label: 'Pulang',
                      nilai: absen.sudahAbsenPulang &&
                          absen.waktuPulang != null
                          ? fmt.format(absen.waktuPulang!)
                          : '—',
                      warna: absen.sudahAbsenPulang
                          ? AppColors.success
                          : AppColors.textHint,
                    ),
                  ],
                ),
              ],
            ),
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

  const _StatusItem({
    required this.label,
    required this.nilai,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(nilai,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: warna)),
            const Text('WIB',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

// ── Tombol Absen ───────────────────────────────────────────────────────────────
class _TombolAbsen extends StatelessWidget {
  final dynamic pegawai;
  const _TombolAbsen({required this.pegawai});

  @override
  Widget build(BuildContext context) {
    return Consumer<AbsenProvider>(
      builder: (_, absen, __) {
        final sudahSelesai =
            absen.sudahAbsenMasuk && absen.sudahAbsenPulang;

        if (absen.status == AbsenStatus.berhasil ||
            absen.status == AbsenStatus.gagal) {
          return Column(
            children: [
              _HasilValidasiCard(
                berhasil: absen.status == AbsenStatus.berhasil,
                pesan: absen.pesan,
                hasilValidasi: absen.hasilValidasi,
              ),
              const SizedBox(height: 12),
              if (!sudahSelesai)
                OutlinedButton(
                  onPressed: () => absen.reset(),
                  child: const Text('Absen Lagi'),
                ),
            ],
          );
        }

        if (absen.status == AbsenStatus.memvalidasi) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(absen.pesan,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Jangan tutup aplikasi',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ),
          );
        }

        if (sudahSelesai) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 48),
                  const SizedBox(height: 8),
                  const Text('Absensi hari ini selesai',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Sampai jumpa besok!',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }

        final labelTombol =
        absen.sudahAbsenMasuk ? 'Absen Pulang' : 'Absen Masuk';

        return ElevatedButton.icon(
          onPressed: () => absen.absen(pegawai),
          icon: Icon(absen.sudahAbsenMasuk
              ? Icons.logout_rounded
              : Icons.login_rounded),
          label: Text(labelTombol),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: absen.sudahAbsenMasuk
                ? AppColors.primaryDark
                : AppColors.primary,
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

  const _HasilValidasiCard({
    required this.berhasil,
    required this.pesan,
    this.hasilValidasi,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
    berhasil ? AppColors.successSurface : AppColors.errorSurface;
    final iconColor = berhasil ? AppColors.success : AppColors.error;
    final icon =
    berhasil ? Icons.check_circle_outline : Icons.error_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                berhasil ? 'Absen berhasil' : 'Absen gagal',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: iconColor,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(pesan,
              style: TextStyle(fontSize: 13, color: iconColor)),
          if (berhasil && hasilValidasi != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Metode: ${hasilValidasi!.metode == MetodeValidasiLokasi.wifi ? "WiFi Kantor" : "GPS"}',
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

// ── Info validasi ──────────────────────────────────────────────────────────────
class _InfoValidasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sistem validasi lokasi',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.gps_fixed,
              warna: AppColors.success,
              judul: 'Lapis 1 — GPS',
              deskripsi:
              'Cek koordinat dalam radius 150m kantor BPS',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.wifi,
              warna: AppColors.primary,
              judul: 'Lapis 2 — WiFi',
              deskripsi:
              'Fallback otomatis jika GPS lemah di dalam gedung',
            ),
          ],
        ),
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: warna.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: warna),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
