import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../data/models/jadwal_wfh_model.dart';

class KelolaWfhPage extends StatefulWidget {
  const KelolaWfhPage({super.key});

  @override
  State<KelolaWfhPage> createState() => _KelolaWfhPageState();
}

class _KelolaWfhPageState extends State<KelolaWfhPage> {
  final _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  // 7 hari: index 0 = Senin (weekday=1) ... 6 = Minggu (weekday=7)
  // aktif[i] = apakah weekday (i+1) adalah hari WFH
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
      // Reset
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
      // Jika gagal fetch, set default Jumat aktif
      _aktif[4] = true; // index 4 = Jumat
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
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal WFH'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _simpan,
            icon: _saving
                ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_outlined, color: Colors.white, size: 18),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
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
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  width: 0.8),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline,
                    size: 16, color: Color(0xFF3B82F6)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hari yang diaktifkan akan menjadi hari WFH — mahasiswa magang bisa absen dari mana saja tanpa validasi GPS/WiFi.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
          ),

          // Daftar hari
          ...List.generate(7, (i) {
            final isWeekend = i >= 5; // Sabtu & Minggu
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Nama hari
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6)
                                        .withOpacity(0.1),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: const Text('default',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                              if (isWeekend) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.textHint
                                        .withOpacity(0.08),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: const Text('libur',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.textHint,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Toggle aktif/nonaktif
                        Switch(
                          value: _aktif[i],
                          onChanged: (v) =>
                              setState(() => _aktif[i] = v),
                          activeColor: const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                    // Catatan (hanya muncul kalau hari aktif)
                    if (_aktif[i]) ...[
                      const SizedBox(height: 4),
                      TextField(
                        controller:
                        TextEditingController(text: _catatan[i])
                          ..selection = TextSelection.collapsed(
                              offset: _catatan[i].length),
                        onChanged: (v) => _catatan[i] = v,
                        decoration: InputDecoration(
                          hintText: 'Catatan (opsional)',
                          hintStyle: const TextStyle(fontSize: 12),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.border, width: 0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.border, width: 0.5),
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
                  const Text('Ringkasan jadwal WFH aktif',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                              color: const Color(0xFF3B82F6)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF3B82F6)
                                      .withOpacity(0.3),
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
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
