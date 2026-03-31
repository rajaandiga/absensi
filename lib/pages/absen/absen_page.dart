import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/absen_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/lokasi_service.dart';

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
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
    final pegawai = context.watch<AuthProvider>().pegawai;
    if (pegawai == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _konfirmasiLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kartu selamat datang
              _KartuPegawai(pegawai: pegawai),
              const SizedBox(height: 16),

              // Status absen hari ini
              _KartuStatusHariIni(),
              const SizedBox(height: 16),

              // Tombol absen
              _TombolAbsen(pegawai: pegawai),
              const SizedBox(height: 16),

              // Info sistem validasi
              _InfoValidasi(),
            ],
          ),
        ),
      ),
    );
  }

  void _konfirmasiLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Kartu info pegawai ────────────────────────────────────────────────
class _KartuPegawai extends StatelessWidget {
  final dynamic pegawai;
  const _KartuPegawai({required this.pegawai});

  @override
  Widget build(BuildContext context) {
    final jam = DateFormat('HH:mm').format(DateTime.now());
    final tanggal = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                pegawai.nama.isNotEmpty
                    ? pegawai.nama[0].toUpperCase()
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
                  Text(
                    'Selamat datang,',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    pegawai.nama,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    pegawai.labelTipe,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  jam,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  tanggal,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget: Status absen hari ini ─────────────────────────────────────────────
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
                const Text(
                  'Status hari ini',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatusItem(
                      label: 'Masuk',
                      nilai: absen.sudahAbsenMasuk && absen.waktuMasuk != null
                          ? fmt.format(absen.waktuMasuk!)
                          : '—',
                      warna: absen.sudahAbsenMasuk
                          ? AppColors.success
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 12),
                    _StatusItem(
                      label: 'Pulang',
                      nilai: absen.sudahAbsenPulang && absen.waktuPulang != null
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
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              nilai,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: warna,
              ),
            ),
            const Text('WIB',
                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

// ── Widget: Tombol absen + hasil validasi ─────────────────────────────────────
class _TombolAbsen extends StatelessWidget {
  final dynamic pegawai;
  const _TombolAbsen({required this.pegawai});

  @override
  Widget build(BuildContext context) {
    return Consumer<AbsenProvider>(
      builder: (_, absen, __) {
        final sudahSelesai =
            absen.sudahAbsenMasuk && absen.sudahAbsenPulang;

        // Hasil validasi — tampilkan setelah proses
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

        // Loading
        if (absen.status == AbsenStatus.memvalidasi) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    absen.pesan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Jangan tutup aplikasi',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          );
        }

        // Sudah absen semua
        if (sudahSelesai) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 48),
                  const SizedBox(height: 8),
                  const Text(
                    'Absensi hari ini selesai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sampai jumpa besok!',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        // Tombol absen
        final labelTombol = absen.sudahAbsenMasuk
            ? 'Absen Pulang'
            : 'Absen Masuk';

        return ElevatedButton.icon(
          onPressed: () => absen.absen(pegawai),
          icon: Icon(
            absen.sudahAbsenMasuk
                ? Icons.logout_rounded
                : Icons.login_rounded,
          ),
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

// ── Widget: Hasil validasi ────────────────────────────────────────────────────
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
    final bgColor = berhasil ? AppColors.successSurface : AppColors.errorSurface;
    final iconColor = berhasil ? AppColors.success : AppColors.error;
    final icon = berhasil ? Icons.check_circle_outline : Icons.error_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 0.5,
        ),
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
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pesan,
            style: TextStyle(
              fontSize: 13,
              color: iconColor,
            ),
          ),
          // Info metode validasi yang dipakai
          if (berhasil && hasilValidasi != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Metode: ${hasilValidasi!.metode == MetodeValidasiLokasi.wifi ? "WiFi Kantor" : "GPS"}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Widget: Info sistem validasi ──────────────────────────────────────────────
class _InfoValidasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sistem validasi lokasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.gps_fixed,
              warna: AppColors.success,
              judul: 'Lapis 1 — GPS',
              deskripsi: 'Cek koordinat dalam radius 150m kantor BPS',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.wifi,
              warna: AppColors.primary,
              judul: 'Lapis 2 — WiFi',
              deskripsi: 'Fallback otomatis jika GPS lemah di dalam gedung',
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
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                deskripsi,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}