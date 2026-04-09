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
        title: const Text('Kelola Mahasiswa Magang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Tambah Mahasiswa Magang',
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
                hintText: 'Cari nama atau NIM...',
                prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                isDense: true,
              ),
            ),
          ),
          if (_loading)
            const Expanded(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_filtered.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Belum ada mahasiswa magang',
                    style: TextStyle(color: AppColors.textHint)),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _muat,
                child: ListView.separated(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _PegawaiItem(
                    pegawai: _filtered[i],
                    onEdit: () => _dialogTambahEdit(context, _filtered[i]),
                    onHapus: () => _konfirmasiHapus(context, _filtered[i]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _dialogTambahEdit(BuildContext ctx, Pegawai? existing) {
    final nipCtrl = TextEditingController(text: existing?.nip ?? '');
    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final jabatanCtrl = TextEditingController(text: existing?.jabatan ?? '');
    final unitCtrl = TextEditingController(text: existing?.unitKerja ?? '');
    final passwordCtrl = TextEditingController();
    // FIX: role disimpan sebagai ValueNotifier agar perubahan terdeteksi
    // di dalam StatefulBuilder tanpa masalah state sync
    final roleNotifier = ValueNotifier<RolePengguna>(
        existing?.role ?? RolePengguna.pegawai);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModal) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    Text(
                      existing == null
                          ? 'Tambah Mahasiswa Magang'
                          : 'Edit Mahasiswa Magang',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    // NIM
                    TextFormField(
                      controller: nipCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                      const InputDecoration(labelText: 'NIM'),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),

                    // Nama
                    TextFormField(
                      controller: namaCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                      const InputDecoration(labelText: 'Nama Lengkap'),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),

                    // Email (opsional)
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                      const InputDecoration(labelText: 'Email (opsional)'),
                    ),
                    const SizedBox(height: 10),

                    // Jurusan / Jabatan
                    TextFormField(
                      controller: jabatanCtrl,
                      decoration:
                      const InputDecoration(labelText: 'Jurusan / Program Studi'),
                    ),
                    const SizedBox(height: 10),

                    // Unit Kerja / Divisi magang
                    TextFormField(
                      controller: unitCtrl,
                      decoration:
                      const InputDecoration(labelText: 'Unit / Divisi Magang'),
                    ),
                    const SizedBox(height: 10),

                    // Password
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: existing == null
                            ? 'Password'
                            : 'Password baru (kosongkan jika tidak diubah)',
                      ),
                      validator: (v) {
                        if (existing == null && (v == null || v.isEmpty)) {
                          return 'Wajib diisi';
                        }
                        if (v != null && v.isNotEmpty && v.length < 6) {
                          return 'Minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // FIX: Dropdown Role saja (tipe dihapus, selalu mahasiswa_magang)
                    // Gunakan ValueNotifier supaya perubahan terpantau dengan benar
                    ValueListenableBuilder<RolePengguna>(
                      valueListenable: roleNotifier,
                      builder: (_, roleVal, __) =>
                          DropdownButtonFormField<RolePengguna>(
                            value: roleVal,
                            decoration:
                            const InputDecoration(labelText: 'Akses'),
                            items: const [
                              DropdownMenuItem(
                                value: RolePengguna.pegawai,
                                child: Text('Mahasiswa Magang'),
                              ),
                              DropdownMenuItem(
                                value: RolePengguna.admin,
                                child: Text('Admin'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) roleNotifier.value = v;
                            },
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol simpan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModal(() => saving = true);
                          try {
                            final payload = <String, dynamic>{
                              'nip': nipCtrl.text.trim(),
                              'nama': namaCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'jabatan': jabatanCtrl.text.trim(),
                              'unit_kerja': unitCtrl.text.trim(),
                              // FIX: tipe selalu mahasiswa_magang
                              'tipe': 'mahasiswa_magang',
                              'role': roleNotifier.value.name,
                              'is_admin':
                              roleNotifier.value == RolePengguna.admin,
                            };
                            if (passwordCtrl.text.isNotEmpty) {
                              payload['password'] = passwordCtrl.text;
                            }

                            if (existing == null) {
                              await _api.tambahPegawai(payload);
                            } else {
                              await _api.updatePegawai(
                                  existing.id, payload);
                            }

                            if (sheetCtx.mounted) {
                              Navigator.pop(sheetCtx);
                            }
                            _muat();
                          } catch (e) {
                            if (sheetCtx.mounted) {
                              ScaffoldMessenger.of(sheetCtx)
                                  .showSnackBar(SnackBar(
                                content: Text('Gagal: $e'),
                                backgroundColor: AppColors.error,
                              ));
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

  void _konfirmasiHapus(BuildContext context, Pegawai p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Mahasiswa'),
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

// ── Item list pegawai ─────────────────────────────────────────────────────────
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
            pegawai.nama.isNotEmpty ? pegawai.nama[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w500),
          ),
        ),
        title: Text(pegawai.nama,
            style:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${pegawai.nip} · ${pegawai.isAdmin ? "Admin" : "Mahasiswa Magang"}',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pegawai.isAdmin)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
