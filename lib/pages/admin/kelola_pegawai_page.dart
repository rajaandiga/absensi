import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../data/models/pegawai_model.dart';

class KelolaPegawaiPage extends StatefulWidget {
  const KelolaPegawaiPage({super.key});

  @override
  State<KelolaPegawaiPage> createState() => _KelolaPegawaiPageState();
}

class _KelolaPegawaiPageState extends State<KelolaPegawaiPage> {
  final _api = ApiService();
  List<Pegawai> _pegawai = [];
  List<Pegawai> _filtered = [];
  bool _loading = true;
  String _cari = '';

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getSemuaPegawai();
      _pegawai = data
          .map((e) => Pegawai.fromJson(e as Map<String, dynamic>))
          .toList();
      _applyFilter();
    } catch (_) {
      _pegawai = [];
      _filtered = [];
    }
    setState(() => _loading = false);
  }

  void _applyFilter() {
    _filtered = _cari.isEmpty
        ? List.from(_pegawai)
        : _pegawai
        .where((p) =>
    p.nama.toLowerCase().contains(_cari.toLowerCase()) ||
        p.nip.contains(_cari))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pegawai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Tambah Pegawai',
            onPressed: () => _dialogTambahEdit(context, null),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() {
                _cari = v;
                _applyFilter();
              }),
              decoration: const InputDecoration(
                hintText: 'Cari nama atau NIP...',
                prefixIcon:
                Icon(Icons.search, color: AppColors.textHint),
                isDense: true,
              ),
            ),
          ),
          if (_loading)
            const Expanded(
              child: Center(
                  child:
                  CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_filtered.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Tidak ada data pegawai',
                    style: TextStyle(color: AppColors.textHint)),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _muat,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 6),
                  itemBuilder: (_, i) => _PegawaiItem(
                    pegawai: _filtered[i],
                    onEdit: () =>
                        _dialogTambahEdit(context, _filtered[i]),
                    onHapus: () =>
                        _konfirmasiHapus(context, _filtered[i]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _dialogTambahEdit(BuildContext context, Pegawai? existing) {
    final nipCtrl =
    TextEditingController(text: existing?.nip ?? '');
    final namaCtrl =
    TextEditingController(text: existing?.nama ?? '');
    final emailCtrl =
    TextEditingController(text: existing?.email ?? '');
    final jabatanCtrl =
    TextEditingController(text: existing?.jabatan ?? '');
    final unitCtrl =
    TextEditingController(text: existing?.unitKerja ?? '');
    TipePegawai tipe = existing?.tipe ?? TipePegawai.pns;
    RolePengguna role = existing?.role ?? RolePengguna.pegawai;
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null
                          ? 'Tambah Pegawai'
                          : 'Edit Pegawai',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nipCtrl,
                      decoration:
                      const InputDecoration(labelText: 'NIP / NIM'),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: namaCtrl,
                      decoration: const InputDecoration(labelText: 'Nama'),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: jabatanCtrl,
                      decoration:
                      const InputDecoration(labelText: 'Jabatan'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: unitCtrl,
                      decoration:
                      const InputDecoration(labelText: 'Unit Kerja'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<TipePegawai>(
                      value: tipe,
                      decoration:
                      const InputDecoration(labelText: 'Tipe'),
                      items: TipePegawai.values
                          .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_labelTipe(t))))
                          .toList(),
                      onChanged: (v) => setModal(
                              () => tipe = v ?? TipePegawai.pns),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<RolePengguna>(
                      value: role,
                      decoration:
                      const InputDecoration(labelText: 'Role'),
                      items: RolePengguna.values
                          .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r == RolePengguna.admin
                              ? 'Admin'
                              : 'Pegawai')))
                          .toList(),
                      onChanged: (v) => setModal(() =>
                      role = v ?? RolePengguna.pegawai),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                        if (!formKey.currentState!.validate()) return;
                        setModal(() => saving = true);
                        try {
                          final payload = {
                            'nip': nipCtrl.text.trim(),
                            'nama': namaCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'jabatan': jabatanCtrl.text.trim(),
                            'unit_kerja': unitCtrl.text.trim(),
                            'tipe': tipe.name,
                            'role': role.name,
                          };
                          if (existing == null) {
                            await _api.tambahPegawai(payload);
                          } else {
                            await _api.updatePegawai(
                                existing.id, payload);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _muat();
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                  content: Text('Gagal: $e'),
                                  backgroundColor: AppColors.error),
                            );
                          }
                        }
                        setModal(() => saving = false);
                      },
                      child: saving
                          ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : Text(existing == null ? 'Tambah' : 'Simpan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _labelTipe(TipePegawai t) {
    switch (t) {
      case TipePegawai.pns: return 'PNS / ASN';
      case TipePegawai.mahasiswaMagang: return 'Mahasiswa Magang';
      case TipePegawai.karyawanSwasta: return 'Karyawan Swasta';
      case TipePegawai.tamu: return 'Tamu';
    }
  }

  void _konfirmasiHapus(BuildContext context, Pegawai p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pegawai'),
        content: Text('Yakin ingin menghapus ${p.nama}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(80, 40)),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _api.hapusPegawai(p.id);
                _muat();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Gagal hapus: $e'),
                      backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _PegawaiItem extends StatelessWidget {
  final Pegawai pegawai;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const _PegawaiItem({
    required this.pegawai,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primarySurface,
          child: Text(
            pegawai.nama.isNotEmpty
                ? pegawai.nama[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w500),
          ),
        ),
        title: Text(pegawai.nama,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${pegawai.nip} · ${pegawai.labelTipe}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pegawai.isAdmin)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Admin',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w500)),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.error),
              onPressed: onHapus,
            ),
          ],
        ),
      ),
    );
  }
}
