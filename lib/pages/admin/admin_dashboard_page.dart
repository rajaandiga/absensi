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
  List<Pegawai> _semuaPegawai = [];
  bool _loading = true;
  bool _exporting = false;

  // Rentang tanggal export — default bulan ini
  late DateTime _exportMulai;
  late DateTime _exportSelesai;

  // Filter tampilan hari ini
  String _cariNama = '';
  StatusAbsen? _filterStatus;

  // Filter export: semua pegawai atau pegawai tertentu
  Pegawai? _pegawaiFilter; // null = semua

  // Jenis export
  _JenisExport _jenisExport = _JenisExport.rekapExcel;

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
      final results = await Future.wait([
        _api.getSemuaAbsensiHariIni(),
        _api.getSemuaPegawai(),
      ]);
      _absensiHariIni = (results[0])
          .map((e) => Absensi.fromJson(e as Map<String, dynamic>))
          .toList();
      _semuaPegawai = (results[1])
          .map((e) => Pegawai.fromJson(e as Map<String, dynamic>))
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
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                  semuaPegawai: _semuaPegawai,
                  pegawaiFilter: _pegawaiFilter,
                  jenisExport: _jenisExport,
                  onPilihRentang: _pilihRentangExport,
                  onPilihPegawai: (p) => setState(() => _pegawaiFilter = p),
                  onPilihJenis: (j) => setState(() => _jenisExport = j),
                  onExport: _jalankanExport,
                ),
                const SizedBox(height: 16),
                _DaftarAbsensiHariIni(
                  absensi: _filtered,
                  cariNama: _cariNama,
                  filterStatus: _filterStatus,
                  onCariNama: (v) => setState(() => _cariNama = v),
                  onFilterStatus: (v) => setState(() => _filterStatus = v),
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
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 40),
            ),
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
      initialDateRange: DateTimeRange(start: _exportMulai, end: _exportSelesai),
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

  Future<void> _jalankanExport() async {
    switch (_jenisExport) {
      case _JenisExport.rekapExcel:
        await _exportRekapExcel();
        break;
      case _JenisExport.rekapCsv:
        await _exportRekapCsv();
        break;
      case _JenisExport.detailExcel:
        await _exportDetailExcel();
        break;
    }
  }

  // ── Export 1: Rekap Ringkasan Excel ──────────────────────────────────────────
  Future<void> _exportRekapExcel() async {
    setState(() => _exporting = true);
    try {
      final data = await _api.getRekapRentang(
        tanggalMulai: _exportMulai,
        tanggalSelesai: _exportSelesai,
      );

      // Filter per pegawai jika dipilih
      final filtered = _pegawaiFilter == null
          ? data
          : data.where((row) => row['pegawai_id'] == _pegawaiFilter!.id).toList();

      final workbook = excel.Excel.createExcel();
      final sheet = workbook['Rekap Absensi'];
      workbook.delete('Sheet1');

      final fmtTgl = DateFormat('d MMM yyyy', 'id_ID');
      final labelRentang = '${fmtTgl.format(_exportMulai)} – ${fmtTgl.format(_exportSelesai)}';
      final labelPegawai = _pegawaiFilter != null ? ' — ${_pegawaiFilter!.nama}' : '';

      // Hitung hari kerja
      int hariKerja = 0;
      DateTime tgl = _exportMulai;
      while (!tgl.isAfter(_exportSelesai)) {
        if (tgl.weekday >= 1 && tgl.weekday <= 5) hariKerja++;
        tgl = tgl.add(const Duration(days: 1));
      }

      _setCell(sheet, 0, 0, 'Rekap Absensi: $labelRentang$labelPegawai',
          bold: true, color: '#7F77DD', fontSize: 13);
      _setCell(sheet, 0, 1, 'Hari Kerja dalam rentang: $hariKerja hari',
          italic: true, color: '#6B7280');

      final headers = ['No', 'Nama', 'NIP', 'Unit Kerja', 'Hadir', 'Terlambat',
        'Izin', 'Sakit', 'Tidak Hadir', 'Total Hari Kerja', '% Kehadiran'];
      for (var i = 0; i < headers.length; i++) {
        _setCell(sheet, i, 2, headers[i],
            bold: true, bgColor: '#7F77DD', color: '#FFFFFF');
      }

      for (var i = 0; i < filtered.length; i++) {
        final row = filtered[i] as Map<String, dynamic>;
        final nilai = [
          i + 1, row['nama'] ?? '', row['nip'] ?? '', row['unit_kerja'] ?? '',
          row['total_hadir'] ?? 0, row['total_terlambat'] ?? 0,
          row['total_izin'] ?? 0, row['total_sakit'] ?? 0,
          row['total_alpha'] ?? 0, row['total_hari_kerja'] ?? hariKerja,
          '${(row['persentase'] as num?)?.toStringAsFixed(1) ?? '0'}%',
        ];
        for (var j = 0; j < nilai.length; j++) {
          final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 3));
          final v = nilai[j];
          cell.value = v is int ? excel.IntCellValue(v) : excel.TextCellValue(v.toString());
        }
      }

      await _simpanDanBagikan(workbook, 'Rekap', labelRentang);
    } catch (e) {
      _tampilError('Gagal export rekap: $e');
    }
    setState(() => _exporting = false);
  }

  // ── Export 2: Rekap CSV ───────────────────────────────────────────────────────
  Future<void> _exportRekapCsv() async {
    setState(() => _exporting = true);
    try {
      final data = await _api.getRekapRentang(
        tanggalMulai: _exportMulai,
        tanggalSelesai: _exportSelesai,
      );

      final filtered = _pegawaiFilter == null
          ? data
          : data.where((row) => row['pegawai_id'] == _pegawaiFilter!.id).toList();

      final buffer = StringBuffer();
      buffer.writeln('No,Nama,NIP,Unit Kerja,Hadir,Terlambat,Izin,Sakit,Tidak Hadir,Total Hari Kerja,% Kehadiran');

      for (var i = 0; i < filtered.length; i++) {
        final row = filtered[i] as Map<String, dynamic>;
        final persen = (row['persentase'] as num?)?.toStringAsFixed(1) ?? '0';
        buffer.writeln([
          i + 1,
          '"${row['nama'] ?? ''}"',
          row['nip'] ?? '',
          '"${row['unit_kerja'] ?? ''}"',
          row['total_hadir'] ?? 0,
          row['total_terlambat'] ?? 0,
          row['total_izin'] ?? 0,
          row['total_sakit'] ?? 0,
          row['total_alpha'] ?? 0,
          row['total_hari_kerja'] ?? 0,
          '$persen%',
        ].join(','));
      }

      final dir = await getApplicationDocumentsDirectory();
      final fmtFile = DateFormat('yyyyMMdd');
      final namaFile = 'Rekap_${fmtFile.format(_exportMulai)}_${fmtFile.format(_exportSelesai)}.csv';
      final filePath = '${dir.path}/$namaFile';
      await File(filePath).writeAsString(buffer.toString());

      final fmtTgl = DateFormat('d MMM yyyy', 'id_ID');
      final labelRentang = '${fmtTgl.format(_exportMulai)} – ${fmtTgl.format(_exportSelesai)}';
      await Share.shareXFiles([XFile(filePath)],
          subject: 'Rekap Absensi BPS Jambi — $labelRentang');
    } catch (e) {
      _tampilError('Gagal export CSV: $e');
    }
    setState(() => _exporting = false);
  }

  // ── Export 3: Detail Harian Excel ─────────────────────────────────────────────
  Future<void> _exportDetailExcel() async {
    setState(() => _exporting = true);
    try {
      final data = await _api.getDetailAbsensiRentang(
        tanggalMulai: _exportMulai,
        tanggalSelesai: _exportSelesai,
        pegawaiId: _pegawaiFilter?.id,
      );

      final workbook = excel.Excel.createExcel();
      final sheet = workbook['Detail Absensi Harian'];
      workbook.delete('Sheet1');

      final fmtTgl = DateFormat('d MMM yyyy', 'id_ID');
      final labelRentang = '${fmtTgl.format(_exportMulai)} – ${fmtTgl.format(_exportSelesai)}';
      final labelPegawai = _pegawaiFilter != null ? ' — ${_pegawaiFilter!.nama}' : '';

      _setCell(sheet, 0, 0, 'Detail Absensi Harian: $labelRentang$labelPegawai',
          bold: true, color: '#7F77DD', fontSize: 13);

      final headers = ['No', 'Tanggal', 'Nama', 'NIP', 'Unit Kerja',
        'Jam Masuk', 'Jam Pulang', 'Metode', 'Status', 'Keterangan'];
      for (var i = 0; i < headers.length; i++) {
        _setCell(sheet, i, 1, headers[i],
            bold: true, bgColor: '#7F77DD', color: '#FFFFFF');
      }

      final fmtWaktu = DateFormat('HH:mm');
      final fmtTglRow = DateFormat('d MMM yyyy', 'id_ID');

      for (var i = 0; i < data.length; i++) {
        final row = data[i] as Map<String, dynamic>;
        final waktuMasukStr = row['waktu_masuk'] as String?;
        final waktuPulangStr = row['waktu_pulang'] as String?;
        final jamMasuk = waktuMasukStr != null
            ? fmtWaktu.format(DateTime.parse(waktuMasukStr))
            : '-';
        final jamPulang = waktuPulangStr != null
            ? fmtWaktu.format(DateTime.parse(waktuPulangStr))
            : '-';
        final tanggal = waktuMasukStr != null
            ? fmtTglRow.format(DateTime.parse(waktuMasukStr))
            : '';

        final nilai = [
          i + 1, tanggal, row['nama_pegawai'] ?? '', row['nip'] ?? '',
          row['unit_kerja'] ?? '', jamMasuk, jamPulang,
          row['metode'] ?? '', row['status'] ?? '', row['keterangan'] ?? '',
        ];
        for (var j = 0; j < nilai.length; j++) {
          final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 2));
          final v = nilai[j];
          cell.value = v is int ? excel.IntCellValue(v) : excel.TextCellValue(v.toString());
        }
      }

      await _simpanDanBagikan(workbook, 'Detail', labelRentang);
    } catch (e) {
      _tampilError('Gagal export detail: $e');
    }
    setState(() => _exporting = false);
  }

  void _setCell(
      excel.Sheet sheet,
      int col,
      int row,
      String value, {
        bool bold = false,
        bool italic = false,
        String? color,
        String? bgColor,
        int? fontSize,
      }) {
    final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = excel.TextCellValue(value);
    // Ikuti pola kode asli yang sudah berjalan: fromHexString langsung tanpa null check
    cell.cellStyle = excel.CellStyle(
      bold: bold,
      italic: italic,
      fontColorHex: color != null
          ? excel.ExcelColor.fromHexString(color)
          : excel.ExcelColor.black,
      backgroundColorHex: bgColor != null
          ? excel.ExcelColor.fromHexString(bgColor)
          : excel.ExcelColor.none,
      fontSize: fontSize,
    );
  }

  Future<void> _simpanDanBagikan(
      excel.Excel workbook,
      String prefix,
      String labelRentang,
      ) async {
    final dir = await getApplicationDocumentsDirectory();
    final fmtFile = DateFormat('yyyyMMdd');
    final namaFile =
        '${prefix}_Absensi_${fmtFile.format(_exportMulai)}_${fmtFile.format(_exportSelesai)}.xlsx';
    final filePath = '${dir.path}/$namaFile';
    final fileBytes = workbook.save();
    if (fileBytes != null) {
      await File(filePath).writeAsBytes(fileBytes);
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: '$prefix Absensi BPS Jambi — $labelRentang',
      );
    }
  }

  void _tampilError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
      ));
    }
  }
}

enum _JenisExport { rekapExcel, rekapCsv, detailExcel }

// ── Kartu statistik ────────────────────────────────────────────────────────────
class _KartuStatistik extends StatelessWidget {
  final List<Absensi> absensi;
  const _KartuStatistik({required this.absensi});

  @override
  Widget build(BuildContext context) {
    final hadir = absensi.where((a) => a.status == StatusAbsen.hadir).length;
    final terlambat = absensi.where((a) => a.status == StatusAbsen.terlambat).length;
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
                _StatBox(label: 'Hadir', nilai: hadir, warna: AppColors.success),
                const SizedBox(width: 6),
                _StatBox(label: 'Terlambat', nilai: terlambat, warna: AppColors.warning),
                const SizedBox(width: 6),
                _StatBox(label: 'Izin', nilai: izin, warna: AppColors.primary),
                const SizedBox(width: 6),
                _StatBox(label: 'Sakit', nilai: sakit, warna: AppColors.primaryLight),
                const SizedBox(width: 6),
                _StatBox(label: 'Total', nilai: total, warna: AppColors.textSecondary),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: warna.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: warna.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text('$nilai',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: warna)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Kartu Export Excel — versi lengkap ────────────────────────────────────────
class _KartuExport extends StatelessWidget {
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final bool exporting;
  final List<Pegawai> semuaPegawai;
  final Pegawai? pegawaiFilter;
  final _JenisExport jenisExport;
  final VoidCallback onPilihRentang;
  final ValueChanged<Pegawai?> onPilihPegawai;
  final ValueChanged<_JenisExport> onPilihJenis;
  final VoidCallback onExport;

  const _KartuExport({
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.exporting,
    required this.semuaPegawai,
    required this.pegawaiFilter,
    required this.jenisExport,
    required this.onPilihRentang,
    required this.onPilihPegawai,
    required this.onPilihJenis,
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

  String get _labelJenis {
    switch (jenisExport) {
      case _JenisExport.rekapExcel:  return 'Rekap ringkasan (.xlsx)';
      case _JenisExport.rekapCsv:    return 'Rekap ringkasan (.csv)';
      case _JenisExport.detailExcel: return 'Detail absensi harian (.xlsx)';
    }
  }

  IconData get _ikonJenis {
    switch (jenisExport) {
      case _JenisExport.rekapExcel:  return Icons.table_chart_outlined;
      case _JenisExport.rekapCsv:    return Icons.description_outlined;
      case _JenisExport.detailExcel: return Icons.list_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export Absensi',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 12),

            // ── Rentang tanggal ──────────────────────────────────────────────
            const Text('Rentang tanggal',
                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: onPilihRentang,
              icon: const Icon(Icons.date_range, size: 16),
              label: Text(_labelRentang),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            ),
            const SizedBox(height: 12),

            // ── Filter pegawai ───────────────────────────────────────────────
            const Text('Filter pegawai',
                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 4),
            DropdownButtonFormField<Pegawai?>(
              initialValue: pegawaiFilter,
              decoration: const InputDecoration(
                hintText: 'Semua pegawai',
                prefixIcon: Icon(Icons.person_search_outlined, size: 18),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: [
                const DropdownMenuItem<Pegawai?>(
                  value: null,
                  child: Text('Semua pegawai'),
                ),
                ...semuaPegawai.map((p) => DropdownMenuItem<Pegawai?>(
                  value: p,
                  child: Text(p.nama, overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: onPilihPegawai,
            ),
            const SizedBox(height: 12),

            // ── Jenis export ─────────────────────────────────────────────────
            const Text('Format export',
                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 4),
            _JenisExportPicker(
              selected: jenisExport,
              onChanged: onPilihJenis,
            ),
            const SizedBox(height: 12),

            // ── Tombol export ────────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: exporting ? null : onExport,
              icon: exporting
                  ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(_ikonJenis, size: 16),
              label: Text(exporting ? 'Mengexport...' : 'Export $_labelJenis'),
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

class _JenisExportPicker extends StatelessWidget {
  final _JenisExport selected;
  final ValueChanged<_JenisExport> onChanged;

  const _JenisExportPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final opsi = [
      (value: _JenisExport.rekapExcel,  label: 'Rekap .xlsx', icon: Icons.table_chart_outlined),
      (value: _JenisExport.rekapCsv,    label: 'Rekap .csv',  icon: Icons.description_outlined),
      (value: _JenisExport.detailExcel, label: 'Detail .xlsx', icon: Icons.list_alt_outlined),
    ];
    return Row(
      children: opsi.map((o) {
        final aktif = selected == o.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(o.value),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: aktif ? AppColors.primarySurface : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: aktif ? AppColors.primary.withOpacity(0.5) : AppColors.border,
                  width: aktif ? 1.5 : 0.8,
                ),
              ),
              child: Column(
                children: [
                  Icon(o.icon,
                      size: 18,
                      color: aktif ? AppColors.primary : AppColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(o.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: aktif ? FontWeight.w600 : FontWeight.normal,
                        color: aktif ? AppColors.primary : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
                  _FilterChip(label: 'Semua', aktif: filterStatus == null,
                      onTap: () => onFilterStatus(null)),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'Hadir', aktif: filterStatus == StatusAbsen.hadir,
                      warna: AppColors.success, onTap: () => onFilterStatus(StatusAbsen.hadir)),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'Terlambat', aktif: filterStatus == StatusAbsen.terlambat,
                      warna: AppColors.warning, onTap: () => onFilterStatus(StatusAbsen.terlambat)),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'Izin', aktif: filterStatus == StatusAbsen.izin,
                      warna: AppColors.primary, onTap: () => onFilterStatus(StatusAbsen.izin)),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'Sakit', aktif: filterStatus == StatusAbsen.sakit,
                      warna: AppColors.primaryLight, onTap: () => onFilterStatus(StatusAbsen.sakit)),
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
              color: aktif ? warna.withOpacity(0.4) : AppColors.border, width: 0.8),
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
      case StatusAbsen.hadir:     return AppColors.success;
      case StatusAbsen.terlambat: return AppColors.warning;
      case StatusAbsen.izin:      return AppColors.primary;
      case StatusAbsen.sakit:     return AppColors.primaryLight;
      case StatusAbsen.alpha:     return AppColors.error;
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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  'Masuk ${fmt.format(absensi.waktuMasuk)}'
                      '${absensi.waktuPulang != null ? " · Pulang ${fmt.format(absensi.waktuPulang!)}" : ""}'
                      ' · via ${absensi.labelMetode}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _warnaStatus.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _warnaStatus.withOpacity(0.3), width: 0.5),
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