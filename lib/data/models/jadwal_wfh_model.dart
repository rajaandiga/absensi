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
