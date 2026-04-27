import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../presentation/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../data/models/absensi_model.dart';
import '../../data/models/pegawai_model.dart';
import '../../data/models/izin_model.dart';
import 'kelola_pegawai_page.dart';
import 'kelola_izin_page.dart';
import 'kelola_wfh_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _BerandaAdmin(),
      const KelolaPegawaiPage(),
      const KelolaIzinPage(),
      const KelolaWfhPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _navIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySurface,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Peserta Magang',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Izin',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work),
            label: 'WFH',
          ),
        ],
      ),
    );
  }
}

// ── Beranda Admin ─────────────────────────────────────────────────────────────
class _BerandaAdmin extends StatefulWidget {
  const _BerandaAdmin();

  @override
  State<_BerandaAdmin> createState() => _BerandaAdminState();
}

class _BerandaAdminState extends State<_BerandaAdmin> {
  final _api = ApiService();
  List<Absensi> _absensiHariIni = [];
  bool _loading = true;
  bool _exporting = false;

  // Rentang tanggal export — default bulan ini
  late DateTime _exportMulai;
  late DateTime _exportSelesai;

  String _cariNama = '';
  StatusAbsen? _filterStatus;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _exportMulai = DateTime(now.year, now.month, 1);
    _exportSelesai = now;
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getSemuaAbsensiHariIni();
      _absensiHariIni = data
          .map((e) => Absensi.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<Absensi> get _filtered {
    return _absensiHariIni.where((a) {
      final cocokNama = _cariNama.isEmpty ||
          a.namaPegawai.toLowerCase().contains(_cariNama.toLowerCase());
      final cocokStatus = _filterStatus == null || a.status == _filterStatus;
      return cocokNama && cocokStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _muatData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _konfirmasiLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
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
                  tanggalMulai: _exportMulai,
                  tanggalSelesai: _exportSelesai,
                  exporting: _exporting,
                  onPilihRentang: _pilihRentangExport,
                  onExport: _exportExcel,
                ),
                const SizedBox(height: 16),
                _DaftarAbsensiHariIni(
                  absensi: _filtered,
                  cariNama: _cariNama,
                  filterStatus: _filterStatus,
                  onCariNama: (v) => setState(() => _cariNama = v),
                  onFilterStatus: (v) =>
                      setState(() => _filterStatus = v),
                ),
              ],
            ),
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
        content: const Text('Yakin ingin keluar dari dashboard admin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(80, 40)),
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

  Future<void> _pilihRentangExport() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange:
      DateTimeRange(start: _exportMulai, end: _exportSelesai),
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
    if (picked != null) {
      setState(() {
        _exportMulai = picked.start;
        _exportSelesai = picked.end;
      });
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final data = await _api.getRekapRentang(
        tanggalMulai: _exportMulai,
        tanggalSelesai: _exportSelesai,
      );

      final workbook = excel.Excel.createExcel();
      final sheet = workbook['Rekap Absensi'];
      workbook.delete('Sheet1');

      final fmtTgl = DateFormat('d MMM yyyy', 'id_ID');
      final labelRentang =
          '${fmtTgl.format(_exportMulai)} – ${fmtTgl.format(_exportSelesai)}';

      // Hitung jumlah hari kerja dalam rentang (Senin–Jumat)
      int hariKerja = 0;
      DateTime tgl = _exportMulai;
      while (!tgl.isAfter(_exportSelesai)) {
        if (tgl.weekday >= 1 && tgl.weekday <= 5) hariKerja++;
        tgl = tgl.add(const Duration(days: 1));
      }

      // ── Baris judul rentang ───────────────────────────────────────────────
      final judulCell = sheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      judulCell.value = excel.TextCellValue('Rekap Absensi: $labelRentang');
      judulCell.cellStyle = excel.CellStyle(
        bold: true,
        fontColorHex: excel.ExcelColor.fromHexString('#7F77DD'),
        fontSize: 13,
      );

      final hkCell = sheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
      hkCell.value =
          excel.TextCellValue('Hari Kerja dalam rentang: $hariKerja hari');
      hkCell.cellStyle = excel.CellStyle(
          italic: true,
          fontColorHex: excel.ExcelColor.fromHexString('#6B7280'));

      // ── Header tabel (baris ke-3, index 2) ───────────────────────────────
      final headers = [
        'No',
        'Nama',
        'NIP',
        'Unit Kerja',
        'Hadir',
        'Terlambat',
        'Izin',
        'Sakit',
        'Tidak Hadir',
        'Total Hari Kerja',
        '% Kehadiran',
      ];

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
            excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
        cell.value = excel.TextCellValue(headers[i]);
        cell.cellStyle = excel.CellStyle(
          bold: true,
          backgroundColorHex: excel.ExcelColor.fromHexString('#7F77DD'),
          fontColorHex: excel.ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // ── Data ──────────────────────────────────────────────────────────────
      for (var i = 0; i < data.length; i++) {
        final row = data[i] as Map<String, dynamic>;
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
          row['total_hari_kerja'] ?? hariKerja,
          '${(row['persentase'] as num?)?.toStringAsFixed(1) ?? '0'}%',
        ];
        for (var j = 0; j < nilai.length; j++) {
          final cell = sheet.cell(excel.CellIndex.indexByColumnRow(
              columnIndex: j, rowIndex: i + 3));
          final v = nilai[j];
          cell.value = v is int
              ? excel.IntCellValue(v)
              : excel.TextCellValue(v.toString());
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final fmtFile = DateFormat('yyyyMMdd');
      final namaFile =
          'Rekap_Absensi_${fmtFile.format(_exportMulai)}_${fmtFile.format(_exportSelesai)}.xlsx';
      final filePath = '${dir.path}/$namaFile';

      final fileBytes = workbook.save();
      if (fileBytes != null) {
        await File(filePath).writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(filePath)],
            subject: 'Rekap Absensi BPS Jambi — $labelRentang');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal export: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
    setState(() => _exporting = false);
  }
}

// ── Kartu statistik ────────────────────────────────────────────────────────────
class _KartuStatistik extends StatelessWidget {
  final List<Absensi> absensi;
  const _KartuStatistik({required this.absensi});

  @override
  Widget build(BuildContext context) {
    final hadir = absensi.where((a) => a.status == StatusAbsen.hadir).length;
    final terlambat =
        absensi.where((a) => a.status == StatusAbsen.terlambat).length;
    final izin = absensi.where((a) => a.status == StatusAbsen.izin).length;
    final sakit = absensi.where((a) => a.status == StatusAbsen.sakit).length;
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
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatBox(
                    label: 'Hadir', nilai: hadir, warna: AppColors.success),
                const SizedBox(width: 6),
                _StatBox(
                    label: 'Terlambat',
                    nilai: terlambat,
                    warna: AppColors.warning),
                const SizedBox(width: 6),
                _StatBox(label: 'Izin', nilai: izin, warna: AppColors.primary),
                const SizedBox(width: 6),
                _StatBox(
                    label: 'Sakit',
                    nilai: sakit,
                    warna: AppColors.primaryLight),
                const SizedBox(width: 6),
                _StatBox(
                    label: 'Total',
                    nilai: total,
                    warna: AppColors.textSecondary),
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
  const _StatBox(
      {required this.label, required this.nilai, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: warna.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: warna.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text('$nilai',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: warna)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Kartu Export Excel ─────────────────────────────────────────────────────────
class _KartuExport extends StatelessWidget {
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final bool exporting;
  final VoidCallback onPilihRentang;
  final VoidCallback onExport;

  const _KartuExport({
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.exporting,
    required this.onPilihRentang,
    required this.onExport,
  });

  String get _labelRentang {
    final fmt = DateFormat('d MMM', 'id_ID');
    final fmtThn = DateFormat('d MMM yyyy', 'id_ID');
    if (tanggalMulai.year == tanggalSelesai.year) {
      return '${fmt.format(tanggalMulai)} – ${fmtThn.format(tanggalSelesai)}';
    }
    return '${fmtThn.format(tanggalMulai)} – ${fmtThn.format(tanggalSelesai)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export rekap Excel',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPilihRentang,
              icon: const Icon(Icons.date_range, size: 16),
              label: Text(_labelRentang),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: exporting ? null : onExport,
              icon: exporting
                  ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.download, size: 16),
              label: Text(exporting ? 'Mengexport...' : 'Export Excel'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Daftar absensi hari ini ────────────────────────────────────────────────────
class _DaftarAbsensiHariIni extends StatelessWidget {
  final List<Absensi> absensi;
  final String cariNama;
  final StatusAbsen? filterStatus;
  final ValueChanged<String> onCariNama;
  final ValueChanged<StatusAbsen?> onFilterStatus;

  const _DaftarAbsensiHariIni({
    required this.absensi,
    required this.cariNama,
    required this.filterStatus,
    required this.onCariNama,
    required this.onFilterStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daftar absensi hari ini',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              onChanged: onCariNama,
              decoration: const InputDecoration(
                hintText: 'Cari nama pegawai...',
                prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                      label: 'Semua',
                      aktif: filterStatus == null,
                      onTap: () => onFilterStatus(null)),
                  const SizedBox(width: 6),
                  _FilterChip(
                      label: 'Hadir',
                      aktif: filterStatus == StatusAbsen.hadir,
                      warna: AppColors.success,
                      onTap: () => onFilterStatus(StatusAbsen.hadir)),
                  const SizedBox(width: 6),
                  _FilterChip(
                      label: 'Terlambat',
                      aktif: filterStatus == StatusAbsen.terlambat,
                      warna: AppColors.warning,
                      onTap: () => onFilterStatus(StatusAbsen.terlambat)),
                  const SizedBox(width: 6),
                  _FilterChip(
                      label: 'Izin',
                      aktif: filterStatus == StatusAbsen.izin,
                      warna: AppColors.primary,
                      onTap: () => onFilterStatus(StatusAbsen.izin)),
                  const SizedBox(width: 6),
                  _FilterChip(
                      label: 'Sakit',
                      aktif: filterStatus == StatusAbsen.sakit,
                      warna: AppColors.primaryLight,
                      onTap: () => onFilterStatus(StatusAbsen.sakit)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (absensi.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Tidak ada data yang sesuai',
                      style: TextStyle(color: AppColors.textHint)),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool aktif;
  final Color warna;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.aktif,
    this.warna = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: aktif ? warna.withOpacity(0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: aktif ? warna.withOpacity(0.4) : AppColors.border,
              width: 0.8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: aktif ? FontWeight.w600 : FontWeight.normal,
                color: aktif ? warna : AppColors.textSecondary)),
      ),
    );
  }
}

class _AbsensiItem extends StatelessWidget {
  final Absensi absensi;
  const _AbsensiItem({required this.absensi});

  Color get _warnaStatus {
    switch (absensi.status) {
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
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(absensi.namaPegawai,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  'Masuk ${fmt.format(absensi.waktuMasuk)}'
                      '${absensi.waktuPulang != null ? " · Pulang ${fmt.format(absensi.waktuPulang!)}" : ""}'
                      ' · via ${absensi.labelMetode}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _warnaStatus.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
              Border.all(color: _warnaStatus.withOpacity(0.3), width: 0.5),
            ),
            child: Text(absensi.labelStatus,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _warnaStatus)),
          ),
        ],
      ),
    );
  }
}