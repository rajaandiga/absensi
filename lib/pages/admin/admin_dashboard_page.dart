import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/absensi_model.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _api = ApiService();
  List<Absensi> _absensiHariIni = [];
  bool _loading = true;
  bool _exporting = false;
  DateTime _bulanDipilih = DateTime.now();

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getSemuaAbsensiHariIni();
      _absensiHariIni = data
          .map((e) => Absensi.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Tampilkan data kosong jika gagal
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _muatData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
            color: AppColors.primary))
            : RefreshIndicator(
          onRefresh: _muatData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KartuStatistik(absensi: _absensiHariIni),
                const SizedBox(height: 16),
                _KartuExport(
                  bulan: _bulanDipilih,
                  exporting: _exporting,
                  onPilihBulan: _pilihBulan,
                  onExport: _exportExcel,
                ),
                const SizedBox(height: 16),
                _DaftarAbsensiHariIni(absensi: _absensiHariIni),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pilihBulan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _bulanDipilih,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _bulanDipilih = picked);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);

    try {
      // Ambil rekap dari server
      final data = await _api.getRekapBulanan(
        bulan: _bulanDipilih.month,
        tahun: _bulanDipilih.year,
      );

      // Buat file Excel
      final excel = Excel.createExcel();
      final sheet = excel['Rekap Absensi'];
      excel.delete('Sheet1');

      // Header
      final headers = [
        'No', 'Nama', 'NIP', 'Unit Kerja',
        'Hadir', 'Terlambat', 'Izin', 'Sakit', 'Tidak Hadir',
        'Total Hari Kerja', '% Kehadiran',
      ];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#7F77DD'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Data baris
      for (var i = 0; i < data.length; i++) {
        final row = data[i] as Map<String, dynamic>;
        final rowIndex = i + 1;
        final nilai = [
          i + 1,
          row['nama'] ?? '',
          row['nip'] ?? '',
          row['unit_kerja'] ?? '',
          row['total_hadir'] ?? 0,
          row['total_terlambat'] ?? 0,
          row['total_izin'] ?? 0,
          row['total_sakit'] ?? 0,
          row['total_alpha'] ?? 0,
          row['total_hari_kerja'] ?? 0,
          '${row['persentase']?.toStringAsFixed(1) ?? 0}%',
        ];

        for (var j = 0; j < nilai.length; j++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
          final v = nilai[j];
          cell.value = v is int
              ? IntCellValue(v)
              : TextCellValue(v.toString());
        }
      }

      // Simpan file
      final dir = await getApplicationDocumentsDirectory();
      final namaBulan = DateFormat('MMMM_yyyy', 'id_ID').format(_bulanDipilih);
      final filePath = '${dir.path}/Rekap_Absensi_BPS_$namaBulan.xlsx';
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        // Share file
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Rekap Absensi BPS Jambi — $namaBulan',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _exporting = false);
  }
}

// ── Widget: Statistik hari ini ────────────────────────────────────────────────
class _KartuStatistik extends StatelessWidget {
  final List<Absensi> absensi;
  const _KartuStatistik({required this.absensi});

  @override
  Widget build(BuildContext context) {
    final hadir = absensi.where((a) => a.status == StatusAbsen.hadir).length;
    final terlambat =
        absensi.where((a) => a.status == StatusAbsen.terlambat).length;
    final total = absensi.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hari ini — ${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now())}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatBox(label: 'Hadir', nilai: hadir, warna: AppColors.success),
                const SizedBox(width: 8),
                _StatBox(
                    label: 'Terlambat', nilai: terlambat,
                    warna: AppColors.warning),
                const SizedBox(width: 8),
                _StatBox(label: 'Total', nilai: total,
                    warna: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int nilai;
  final Color warna;
  const _StatBox({required this.label, required this.nilai, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: warna,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget: Kartu export Excel ────────────────────────────────────────────────
class _KartuExport extends StatelessWidget {
  final DateTime bulan;
  final bool exporting;
  final VoidCallback onPilihBulan;
  final VoidCallback onExport;

  const _KartuExport({
    required this.bulan,
    required this.exporting,
    required this.onPilihBulan,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export rekap Excel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPilihBulan,
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: Text(
                      DateFormat('MMMM yyyy', 'id_ID').format(bulan),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: exporting ? null : onExport,
                    icon: exporting
                        ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.download, size: 16),
                    label: Text(exporting ? 'Mengexport...' : 'Export Excel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget: Daftar absensi hari ini ───────────────────────────────────────────
class _DaftarAbsensiHariIni extends StatelessWidget {
  final List<Absensi> absensi;
  const _DaftarAbsensiHariIni({required this.absensi});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar absensi hari ini',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (absensi.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Belum ada data absensi hari ini',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ),
              )
            else
              ...absensi.map((a) => _AbsensiItem(absensi: a)),
          ],
        ),
      ),
    );
  }
}

class _AbsensiItem extends StatelessWidget {
  final Absensi absensi;
  const _AbsensiItem({required this.absensi});

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              absensi.namaPegawai.isNotEmpty
                  ? absensi.namaPegawai[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  absensi.namaPegawai,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Masuk ${fmt.format(absensi.waktuMasuk)} · via ${absensi.labelMetode}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }
}