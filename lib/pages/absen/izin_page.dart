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
      appBar: AppBar(
        title: const Text('Izin & Sakit'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
        tanggalMulai: _tanggalMulai.toIso8601String().split('T').first,
        tanggalSelesai: _tanggalSelesai.toIso8601String().split('T').first,
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
            // Pilih jenis
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jenis pengajuan',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _PilihJenisTile(
                          label: 'Izin',
                          icon: Icons.event_note,
                          warna: AppColors.primary,
                          dipilih: _jenis == JenisIzin.izin,
                          onTap: () => setState(() => _jenis = JenisIzin.izin),
                        ),
                        const SizedBox(width: 10),
                        _PilihJenisTile(
                          label: 'Sakit',
                          icon: Icons.medical_services_outlined,
                          warna: AppColors.warning,
                          dipilih: _jenis == JenisIzin.sakit,
                          onTap: () => setState(() => _jenis = JenisIzin.sakit),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Pilih tanggal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Periode',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
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
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward,
                              size: 16, color: AppColors.textHint),
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
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '$_jumlahHari hari kerja',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Keterangan
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _jenis == JenisIzin.sakit
                          ? 'Diagnosis / keterangan sakit'
                          : 'Alasan izin',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _keteranganCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: _jenis == JenisIzin.sakit
                            ? 'Contoh: Demam, flu, dsb.'
                            : 'Contoh: Urusan keluarga, dsb.',
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
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warningSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 14, color: AppColors.warning),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Untuk sakit > 2 hari, wajib menyerahkan surat keterangan dokter.',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

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
            ),
          ],
        ),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: dipilih ? warna.withOpacity(0.1) : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: dipilih ? warna : AppColors.border,
              width: dipilih ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: dipilih ? warna : AppColors.textHint, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 2),
            Text(tanggal,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
            Icon(Icons.event_available,
                size: 64, color: AppColors.textHint.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Belum ada riwayat izin',
                style: TextStyle(color: AppColors.textHint)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
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
      case StatusIzin.pending: return AppColors.warning;
      case StatusIzin.disetujui: return AppColors.success;
      case StatusIzin.ditolak: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM', 'id_ID');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (izin.jenis == JenisIzin.sakit
                    ? AppColors.warning
                    : AppColors.primary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                izin.jenis == JenisIzin.sakit
                    ? Icons.medical_services_outlined
                    : Icons.event_note,
                size: 20,
                color: izin.jenis == JenisIzin.sakit
                    ? AppColors.warning
                    : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(izin.labelJenis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
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
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _warnaStatus.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _warnaStatus.withOpacity(0.3), width: 0.5),
              ),
              child: Text(
                izin.labelStatus,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _warnaStatus),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
