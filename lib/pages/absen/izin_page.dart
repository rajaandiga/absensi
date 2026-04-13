import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../../data/models/izin_model.dart';
import '../../core/theme/app_colors.dart';

class IzinPage extends StatefulWidget {
  const IzinPage({super.key});

  @override
  State<IzinPage> createState() => _IzinPageState();
}

class _IzinPageState extends State<IzinPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        foregroundColor: Colors.white,
        title: const Text('Izin & Sakit'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primaryLight,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Ajukan'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _FormIzin(api: _api),
          _RiwayatIzin(api: _api),
        ],
      ),
    );
  }
}

// ── Tab Ajukan Izin ────────────────────────────────────────────────────────────
class _FormIzin extends StatefulWidget {
  final ApiService api;
  const _FormIzin({required this.api});

  @override
  State<_FormIzin> createState() => _FormIzinState();
}

class _FormIzinState extends State<_FormIzin> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganCtrl = TextEditingController();

  JenisIzin _jenis = JenisIzin.izin;
  DateTime _tanggalMulai = DateTime.now();
  DateTime _tanggalSelesai = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    super.dispose();
  }

  int get _jumlahHari =>
      _tanggalSelesai.difference(_tanggalMulai).inDays + 1;

  Future<void> _pilihTanggal({required bool isMulai}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isMulai ? _tanggalMulai : _tanggalSelesai,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked == null) return;
    setState(() {
      if (isMulai) {
        _tanggalMulai = picked;
        if (_tanggalSelesai.isBefore(picked)) _tanggalSelesai = picked;
      } else {
        _tanggalSelesai = picked;
        if (_tanggalMulai.isAfter(picked)) _tanggalMulai = picked;
      }
    });
  }

  Future<void> _ajukan() async {
    if (!_formKey.currentState!.validate()) return;
    final pegawai = context.read<AuthProvider>().pegawai;
    if (pegawai == null) return;

    setState(() => _loading = true);
    try {
      await widget.api.ajukanIzin(
        pegawaiId: pegawai.id,
        jenis: _jenis.name,
        tanggalMulai:
        _tanggalMulai.toIso8601String().split('T').first,
        tanggalSelesai:
        _tanggalSelesai.toIso8601String().split('T').first,
        keterangan: _keteranganCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan izin berhasil dikirim'),
            backgroundColor: AppColors.success,
          ),
        );
        _keteranganCtrl.clear();
        setState(() {
          _tanggalMulai = DateTime.now();
          _tanggalSelesai = DateTime.now();
          _jenis = JenisIzin.izin;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengajukan: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, d MMM yyyy', 'id_ID');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Jenis
            _SectionLabel(label: 'Jenis Pengajuan'),
            const SizedBox(height: 10),
            Row(
              children: [
                _PilihJenisTile(
                  label: 'Izin',
                  icon: Icons.event_note_rounded,
                  warna: const Color(0xFF3B82F6),
                  dipilih: _jenis == JenisIzin.izin,
                  onTap: () => setState(() => _jenis = JenisIzin.izin),
                ),
                const SizedBox(width: 12),
                _PilihJenisTile(
                  label: 'Sakit',
                  icon: Icons.medical_services_outlined,
                  warna: AppColors.warning,
                  dipilih: _jenis == JenisIzin.sakit,
                  onTap: () => setState(() => _jenis = JenisIzin.sakit),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Periode
            _SectionLabel(label: 'Periode'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TombolTanggal(
                          label: 'Mulai',
                          tanggal: fmt.format(_tanggalMulai),
                          onTap: () => _pilihTanggal(isMulai: true),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 18, color: AppColors.textHint),
                      ),
                      Expanded(
                        child: _TombolTanggal(
                          label: 'Selesai',
                          tanggal: fmt.format(_tanggalSelesai),
                          onTap: () => _pilihTanggal(isMulai: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '$_jumlahHari hari kerja',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Keterangan
            _SectionLabel(
              label: _jenis == JenisIzin.sakit
                  ? 'Diagnosis / Keterangan Sakit'
                  : 'Alasan Izin',
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _keteranganCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _jenis == JenisIzin.sakit
                          ? 'Contoh: Demam, flu, dsb.'
                          : 'Contoh: Urusan keluarga, dsb.',
                      fillColor: AppColors.background,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Keterangan tidak boleh kosong';
                      }
                      if (v.trim().length < 10) {
                        return 'Keterangan minimal 10 karakter';
                      }
                      return null;
                    },
                  ),
                  if (_jenis == JenisIzin.sakit) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: AppColors.warning),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sakit > 2 hari wajib menyerahkan surat keterangan dokter.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _loading ? null : _ajukan,
              icon: _loading
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(_loading ? 'Mengirim...' : 'Ajukan Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PilihJenisTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color warna;
  final bool dipilih;
  final VoidCallback onTap;

  const _PilihJenisTile({
    required this.label,
    required this.icon,
    required this.warna,
    required this.dipilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: dipilih ? warna.withOpacity(0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dipilih ? warna : AppColors.border,
              width: dipilih ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: dipilih ? warna : AppColors.textHint, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: dipilih ? warna : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TombolTanggal extends StatelessWidget {
  final String label;
  final String tanggal;
  final VoidCallback onTap;

  const _TombolTanggal({
    required this.label,
    required this.tanggal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 4),
            Text(tanggal,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── Tab Riwayat Izin ───────────────────────────────────────────────────────────
class _RiwayatIzin extends StatefulWidget {
  final ApiService api;
  const _RiwayatIzin({required this.api});

  @override
  State<_RiwayatIzin> createState() => _RiwayatIzinState();
}

class _RiwayatIzinState extends State<_RiwayatIzin> {
  List<IzinModel> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final pegawai = context.read<AuthProvider>().pegawai;
    if (pegawai == null) return;
    setState(() => _loading = true);
    try {
      final raw = await widget.api.getRiwayatIzin(pegawai.id);
      _data = raw
          .map((e) => IzinModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _data = [];
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_data.isEmpty) {
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
              child: Icon(Icons.event_available,
                  size: 48,
                  color: AppColors.textHint.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada riwayat izin',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _IzinItem(izin: _data[i]),
      ),
    );
  }
}

class _IzinItem extends StatelessWidget {
  final IzinModel izin;
  const _IzinItem({required this.izin});

  Color get _warnaStatus {
    switch (izin.status) {
      case StatusIzin.pending:
        return AppColors.warning;
      case StatusIzin.disetujui:
        return AppColors.success;
      case StatusIzin.ditolak:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM', 'id_ID');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (izin.jenis == JenisIzin.sakit
                  ? AppColors.warning
                  : const Color(0xFF3B82F6))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              izin.jenis == JenisIzin.sakit
                  ? Icons.medical_services_outlined
                  : Icons.event_note_rounded,
              size: 22,
              color: izin.jenis == JenisIzin.sakit
                  ? AppColors.warning
                  : const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(izin.labelJenis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(
                  '${fmt.format(izin.tanggalMulai)} — ${fmt.format(izin.tanggalSelesai)}  ·  ${izin.jumlahHari} hari',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (izin.keterangan.isNotEmpty)
                  Text(
                    izin.keterangan,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              izin.labelStatus,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _warnaStatus),
            ),
          ),
        ],
      ),
    );
  }
}
