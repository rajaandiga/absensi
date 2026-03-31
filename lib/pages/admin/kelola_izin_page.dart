import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../data/models/izin_model.dart';

class KelolaIzinPage extends StatefulWidget {
  const KelolaIzinPage({super.key});

  @override
  State<KelolaIzinPage> createState() => _KelolaIzinPageState();
}

class _KelolaIzinPageState extends State<KelolaIzinPage>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tab;
  List<IzinModel> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _muat();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getIzinPending();
      _pending = data
          .map((e) => IzinModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _pending = [];
    }
    setState(() => _loading = false);
  }

  Future<void> _setujui(IzinModel izin, String statusBaru) async {
    try {
      await _api.setujuiIzin(izin.id, statusBaru);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusBaru == 'disetujui'
                ? 'Izin ${izin.namaPegawai} disetujui'
                : 'Izin ${izin.namaPegawai} ditolak'),
            backgroundColor: statusBaru == 'disetujui'
                ? AppColors.success
                : AppColors.error,
          ),
        );
      }
      _muat();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Izin & Sakit'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Menunggu'),
                  if (_pending.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pending.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Semua'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
        controller: _tab,
        children: [
          _ListIzin(
            data: _pending,
            emptyMsg: 'Tidak ada pengajuan yang menunggu',
            showAksi: true,
            onSetujui: (izin) => _setujui(izin, 'disetujui'),
            onTolak: (izin) => _setujui(izin, 'ditolak'),
            onRefresh: _muat,
          ),
          _ListIzin(
            data: _pending, // TODO: ganti dengan semua izin
            emptyMsg: 'Tidak ada data izin',
            showAksi: false,
            onSetujui: (_) {},
            onTolak: (_) {},
            onRefresh: _muat,
          ),
        ],
      ),
    );
  }
}

class _ListIzin extends StatelessWidget {
  final List<IzinModel> data;
  final String emptyMsg;
  final bool showAksi;
  final ValueChanged<IzinModel> onSetujui;
  final ValueChanged<IzinModel> onTolak;
  final Future<void> Function() onRefresh;

  const _ListIzin({
    required this.data,
    required this.emptyMsg,
    required this.showAksi,
    required this.onSetujui,
    required this.onTolak,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 56, color: AppColors.textHint.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(emptyMsg,
                style: const TextStyle(color: AppColors.textHint)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _IzinAdminItem(
          izin: data[i],
          showAksi: showAksi,
          onSetujui: () => onSetujui(data[i]),
          onTolak: () => onTolak(data[i]),
        ),
      ),
    );
  }
}

class _IzinAdminItem extends StatelessWidget {
  final IzinModel izin;
  final bool showAksi;
  final VoidCallback onSetujui;
  final VoidCallback onTolak;

  const _IzinAdminItem({
    required this.izin,
    required this.showAksi,
    required this.onSetujui,
    required this.onTolak,
  });

  Color get _warnaStatus {
    switch (izin.status) {
      case StatusIzin.pending: return AppColors.warning;
      case StatusIzin.disetujui: return AppColors.success;
      case StatusIzin.ditolak: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy', 'id_ID');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    izin.namaPegawai.isNotEmpty
                        ? izin.namaPegawai[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(izin.namaPegawai,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      Text(
                        '${izin.labelJenis}  ·  ${fmt.format(izin.tanggalMulai)} — ${fmt.format(izin.tanggalSelesai)}  ·  ${izin.jumlahHari} hari',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _warnaStatus.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _warnaStatus.withOpacity(0.3),
                        width: 0.5),
                  ),
                  child: Text(izin.labelStatus,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _warnaStatus)),
                ),
              ],
            ),
            if (izin.keterangan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  izin.keterangan,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
            if (showAksi && izin.status == StatusIzin.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTolak,
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSetujui,
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
