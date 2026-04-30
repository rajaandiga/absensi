/// Model untuk jadwal WFH yang diatur admin.
/// Default: Jumat (weekday = 5).
/// Admin bisa tambah hari lain atau nonaktifkan.
class JadwalWfh {
  /// weekday: 1=Sen, 2=Sel, 3=Rab, 4=Kam, 5=Jum, 6=Sab, 7=Min
  final int weekday;
  final bool aktif;
  final String? catatan;

  const JadwalWfh({
    required this.weekday,
    required this.aktif,
    this.catatan,
  });

  factory JadwalWfh.fromJson(Map<String, dynamic> json) {
    return JadwalWfh(
      weekday: json['weekday'] as int,
      aktif: json['aktif'] as bool? ?? true,
      catatan: json['catatan'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'aktif': aktif,
    'catatan': catatan,
  };

  String get namaHari {
    const nama = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return weekday >= 1 && weekday <= 7 ? nama[weekday] : '?';
  }

  /// Default: hanya Jumat aktif
  static List<JadwalWfh> defaultJadwal() => [
    const JadwalWfh(weekday: 5, aktif: true, catatan: 'WFH default setiap Jumat'),
  ];
}

/// Model untuk pegawai yang mendapat izin WFH khusus (di luar jadwal hari WFH global)
class WfhPegawai {
  final String id;
  final String pegawaiId;
  final String namaPegawai;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String? keterangan;

  const WfhPegawai({
    required this.id,
    required this.pegawaiId,
    required this.namaPegawai,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.keterangan,
  });

  factory WfhPegawai.fromJson(Map<String, dynamic> json) {
    return WfhPegawai(
      id: json['id'] as String,
      pegawaiId: json['pegawai_id'] as String,
      namaPegawai: json['nama_pegawai'] as String? ?? '',
      tanggalMulai: DateTime.parse(json['tanggal_mulai'] as String),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai'] as String),
      keterangan: json['keterangan'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pegawai_id': pegawaiId,
    'nama_pegawai': namaPegawai,
    'tanggal_mulai': '${tanggalMulai.year}-${tanggalMulai.month.toString().padLeft(2, '0')}-${tanggalMulai.day.toString().padLeft(2, '0')}',
    'tanggal_selesai': '${tanggalSelesai.year}-${tanggalSelesai.month.toString().padLeft(2, '0')}-${tanggalSelesai.day.toString().padLeft(2, '0')}',
    'keterangan': keterangan,
  };
}
