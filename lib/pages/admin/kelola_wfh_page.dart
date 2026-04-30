import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../data/models/jadwal_wfh_model.dart';
import '../../data/models/pegawai_model.dart';

class KelolaWfhPage extends StatefulWidget {
  const KelolaWfhPage({super.key});

  @override
  State<KelolaWfhPage> createState() => _KelolaWfhPageState();
}

class _KelolaWfhPageState extends State<KelolaWfhPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal WFH'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Jadwal Harian'),
            Tab(text: 'Per Pegawai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TabJadwalHarian(),
          _TabWfhPegawai(),
        ],
      ),
    );
  }
}

// ── Tab 1: Jadwal hari WFH global ─────────────────────────────────────────────
class _TabJadwalHarian extends StatefulWidget {
  const _TabJadwalHarian();

  @override
  State<_TabJadwalHarian> createState() => _TabJadwalHarianState();
}

class _TabJadwalHarianState extends State<_TabJadwalHarian> {
  final _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  final List<bool> _aktif = List.filled(7, false);
  final List<String> _catatan = List.filled(7, '');
  final _namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getJadwalWfhAdmin();
      for (var i = 0; i < 7; i++) {
        _aktif[i] = false;
        _catatan[i] = '';
      }
      for (final e in data) {
        final j = JadwalWfh.fromJson(e as Map<String, dynamic>);
        if (j.weekday >= 1 && j.weekday <= 7) {
          _aktif[j.weekday - 1] = j.aktif;
          _catatan[j.weekday - 1] = j.catatan ?? '';
        }
      }
    } catch (_) {
      _aktif[4] = true;
      _catatan[4] = 'WFH default setiap Jumat';
    }
    setState(() => _loading = false);
  }

  Future<void> _simpan() async {
    setState(() => _saving = true);
    try {
      final jadwal = <Map<String, dynamic>>[];
      for (var i = 0; i < 7; i++) {
        jadwal.add({
          'weekday': i + 1,
          'aktif': _aktif[i],
          'catatan': _catatan[i].isNotEmpty ? _catatan[i] : null,
        });
      }
      await _api.simpanJadwalWfh(jadwal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal WFH berhasil disimpan ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.3), width: 0.8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hari yang diaktifkan akan menjadi hari WFH global — semua pegawai bisa absen dari mana saja tanpa validasi GPS/WiFi.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8)),
                      ),
                    ),
                  ],
                ),
              ),

              // Daftar hari
              ...List.generate(7, (i) {
                final isWeekend = i >= 5;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    _namaHari[i],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isWeekend
                                          ? AppColors.textHint
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (i == 4) ...[
                                    const SizedBox(width: 8),
                                    _Badge('default', color: const Color(0xFF3B82F6)),
                                  ],
                                  if (isWeekend) ...[
                                    const SizedBox(width: 8),
                                    _Badge('libur', color: AppColors.textHint),
                                  ],
                                ],
                              ),
                            ),
                            Switch(
                              value: _aktif[i],
                              onChanged: (v) => setState(() => _aktif[i] = v),
                              activeThumbColor: const Color(0xFF3B82F6),
                            ),
                          ],
                        ),
                        if (_aktif[i]) ...[
                          const SizedBox(height: 4),
                          TextField(
                            controller: TextEditingController(text: _catatan[i])
                              ..selection =
                              TextSelection.collapsed(offset: _catatan[i].length),
                            onChanged: (v) => _catatan[i] = v,
                            decoration: InputDecoration(
                              hintText: 'Catatan (opsional)',
                              hintStyle: const TextStyle(fontSize: 12),
                              isDense: true,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                const BorderSide(color: AppColors.border, width: 0.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                const BorderSide(color: AppColors.border, width: 0.5),
                              ),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              // Ringkasan
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hari WFH aktif',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (var i = 0; i < 7; i++)
                            if (_aktif[i])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                                      width: 0.5),
                                ),
                                child: Text(
                                  _namaHari[i],
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1D4ED8),
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                          if (!_aktif.any((a) => a))
                            const Text('Tidak ada hari WFH yang aktif',
                                style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tombol simpan di bawah
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _simpan,
              icon: _saving
                  ? const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_saving ? 'Menyimpan...' : 'Simpan Jadwal'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab 2: WFH khusus per pegawai ─────────────────────────────────────────────
class _TabWfhPegawai extends StatefulWidget {
  const _TabWfhPegawai();

  @override
  State<_TabWfhPegawai> createState() => _TabWfhPegawaiState();
}

class _TabWfhPegawaiState extends State<_TabWfhPegawai> {
  final _api = ApiService();
  List<WfhPegawai> _daftar = [];
  List<Pegawai> _semuaPegawai = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getWfhPegawai(),
        _api.getSemuaPegawai(),
      ]);
      _daftar = (results[0])
          .map((e) => WfhPegawai.fromJson(e as Map<String, dynamic>))
          .toList();
      _semuaPegawai = (results[1])
          .map((e) => Pegawai.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _tambahWfhPegawai() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _DialogTambahWfhPegawai(semuaPegawai: _semuaPegawai),
    );
    if (result != null) {
      try {
        await _api.tambahWfhPegawai(result);
        await _muat();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WFH pegawai berhasil ditambahkan ✓'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menambahkan: $e'),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _hapus(WfhPegawai item) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus WFH Pegawai'),
        content: Text('Hapus izin WFH untuk ${item.namaPegawai}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (konfirmasi == true) {
      try {
        await _api.hapusWfhPegawai(item.id);
        await _muat();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e'),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Column(
      children: [
        // Info card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3), width: 0.8),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tambahkan pegawai tertentu yang boleh WFH pada rentang tanggal tertentu, di luar jadwal hari WFH global.',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _daftar.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_work_outlined,
                    size: 48, color: AppColors.textHint.withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text('Belum ada WFH per pegawai',
                    style: TextStyle(color: AppColors.textHint)),
                const SizedBox(height: 4),
                const Text('Tekan + untuk menambahkan',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _muat,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _daftar.length,
              itemBuilder: (_, i) {
                final item = _daftar[i];
                final fmt = DateFormat('d MMM yyyy', 'id_ID');
                final aktif = item.tanggalSelesai.isAfter(DateTime.now()) ||
                    _isSameDay(item.tanggalSelesai, DateTime.now());
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: aktif
                          ? const Color(0xFF3B82F6).withOpacity(0.12)
                          : AppColors.background,
                      child: Icon(Icons.person_outlined,
                          color: aktif
                              ? const Color(0xFF3B82F6)
                              : AppColors.textHint,
                          size: 20),
                    ),
                    title: Text(item.namaPegawai,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${fmt.format(item.tanggalMulai)} – ${fmt.format(item.tanggalSelesai)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (item.keterangan != null &&
                            item.keterangan!.isNotEmpty)
                          Text(item.keterangan!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Badge(aktif ? 'Aktif' : 'Selesai',
                            color: aktif
                                ? const Color(0xFF3B82F6)
                                : AppColors.textHint),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          onPressed: () => _hapus(item),
                          tooltip: 'Hapus',
                        ),
                      ],
                    ),
                    isThreeLine: item.keterangan != null &&
                        item.keterangan!.isNotEmpty,
                  ),
                );
              },
            ),
          ),
        ),

        // Tombol tambah
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _tambahWfhPegawai,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah WFH Pegawai'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Dialog tambah WFH pegawai ──────────────────────────────────────────────────
// FIX: Dropdown di dalam AlertDialog sering tidak bisa diklik di Android.
// Solusi: ganti pilih pegawai dengan tombol yang membuka bottom sheet sendiri.
class _DialogTambahWfhPegawai extends StatefulWidget {
  final List<Pegawai> semuaPegawai;
  const _DialogTambahWfhPegawai({required this.semuaPegawai});

  @override
  State<_DialogTambahWfhPegawai> createState() =>
      _DialogTambahWfhPegawaiState();
}

class _DialogTambahWfhPegawaiState extends State<_DialogTambahWfhPegawai> {
  Pegawai? _pegawai;
  DateTime _mulai = DateTime.now();
  DateTime _selesai = DateTime.now().add(const Duration(days: 1));
  final _keteranganCtrl = TextEditingController();

  String _fmtTgl(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
  String _fmtApi(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // FIX: Pilih pegawai via bottom sheet — tidak ada masalah klik seperti dropdown
  Future<void> _pilihPegawai() async {
    final picked = await showModalBottomSheet<Pegawai>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PilihPegawaiSheet(semuaPegawai: widget.semuaPegawai),
    );
    if (picked != null) setState(() => _pegawai = picked);
  }

  Future<void> _pilihRentang() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _mulai, end: _selesai),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        _mulai = picked.start;
        _selesai = picked.end;
      });
    }
  }

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah WFH Pegawai', style: TextStyle(fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pegawai',
                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 4),
            // FIX: Tombol biasa yang membuka bottom sheet — tidak ada bug klik
            OutlinedButton.icon(
              onPressed: _pilihPegawai,
              icon: Icon(
                _pegawai != null ? Icons.person : Icons.person_search_outlined,
                size: 16,
                color: _pegawai != null ? AppColors.primary : AppColors.textHint,
              ),
              label: Text(
                _pegawai?.nama ?? 'Pilih pegawai...',
                style: TextStyle(
                  fontSize: 13,
                  color: _pegawai != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                alignment: Alignment.centerLeft,
                side: BorderSide(
                  color: _pegawai != null
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.border,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Rentang tanggal WFH',
                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _pilihRentang,
              icon: const Icon(Icons.date_range, size: 16),
              label: Text('${_fmtTgl(_mulai)} – ${_fmtTgl(_selesai)}',
                  style: const TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44)),
            ),
            const SizedBox(height: 12),
            const Text('Keterangan (opsional)',
                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 4),
            TextField(
              controller: _keteranganCtrl,
              decoration: const InputDecoration(
                hintText: 'cth: izin kerja lapangan',
                isDense: true,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _pegawai == null
              ? null
              : () {
            Navigator.pop(context, {
              'pegawai_id': _pegawai!.id,
              'tanggal_mulai': _fmtApi(_mulai),
              'tanggal_selesai': _fmtApi(_selesai),
              'keterangan': _keteranganCtrl.text.trim().isEmpty
                  ? null
                  : _keteranganCtrl.text.trim(),
            });
          },
          child: const Text('Tambahkan'),
        ),
      ],
    );
  }
}

// ── Bottom sheet pilih pegawai ─────────────────────────────────────────────────
// Dibuat sebagai StatefulWidget tersendiri agar setState pencarian bekerja benar
class _PilihPegawaiSheet extends StatefulWidget {
  final List<Pegawai> semuaPegawai;
  const _PilihPegawaiSheet({required this.semuaPegawai});

  @override
  State<_PilihPegawaiSheet> createState() => _PilihPegawaiSheetState();
}

class _PilihPegawaiSheetState extends State<_PilihPegawaiSheet> {
  final _cariCtrl = TextEditingController();
  String _cari = '';

  @override
  void dispose() {
    _cariCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.semuaPegawai
        .where((p) =>
    _cari.isEmpty ||
        p.nama.toLowerCase().contains(_cari.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Pilih Pegawai',
                  style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            // Search
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _cariCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _cari = v),
                decoration: const InputDecoration(
                  hintText: 'Cari nama pegawai...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // List pegawai
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                child: Text('Tidak ada pegawai',
                    style: TextStyle(color: AppColors.textHint)),
              )
                  : ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        p.nama.isNotEmpty
                            ? p.nama[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    title: Text(p.nama,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(p.nip,
                        style: const TextStyle(fontSize: 12)),
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget bantu ───────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }
}