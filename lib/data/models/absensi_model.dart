import 'package:equatable/equatable.dart';

enum StatusAbsen { hadir, terlambat, izin, sakit, alpha }

enum MetodeValidasi { gps, wifi, manual }

enum JenisAbsen { harian, acara }

class Absensi extends Equatable {
  final String id;
  final String pegawaiId;
  final String namaPegawai;
  final DateTime waktuMasuk;
  final DateTime? waktuPulang;
  final StatusAbsen status;
  final MetodeValidasi metode;
  final JenisAbsen jenis;
  final String? acaraId;
  final String? namaAcara;
  final double? latitude;
  final double? longitude;
  final String? ssidWifi;
  final String? keterangan;

  const Absensi({
    required this.id,
    required this.pegawaiId,
    required this.namaPegawai,
    required this.waktuMasuk,
    this.waktuPulang,
    required this.status,
    required this.metode,
    this.jenis = JenisAbsen.harian,
    this.acaraId,
    this.namaAcara,
    this.latitude,
    this.longitude,
    this.ssidWifi,
    this.keterangan,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['id'] as String,
      pegawaiId: json['pegawai_id'] as String,
      namaPegawai: json['nama_pegawai'] as String,
      waktuMasuk: DateTime.parse(json['waktu_masuk'] as String),
      waktuPulang: json['waktu_pulang'] != null
          ? DateTime.parse(json['waktu_pulang'] as String)
          : null,
      status: StatusAbsen.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => StatusAbsen.hadir,
      ),
      metode: MetodeValidasi.values.firstWhere(
            (e) => e.name == json['metode'],
        orElse: () => MetodeValidasi.gps,
      ),
      jenis: json['jenis'] == 'acara' ? JenisAbsen.acara : JenisAbsen.harian,
      acaraId: json['acara_id'] as String?,
      namaAcara: json['nama_acara'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      ssidWifi: json['ssid_wifi'] as String?,
      keterangan: json['keterangan'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pegawai_id': pegawaiId,
    'nama_pegawai': namaPegawai,
    'waktu_masuk': waktuMasuk.toIso8601String(),
    'waktu_pulang': waktuPulang?.toIso8601String(),
    'status': status.name,
    'metode': metode.name,
    'jenis': jenis.name,
    'acara_id': acaraId,
    'nama_acara': namaAcara,
    'latitude': latitude,
    'longitude': longitude,
    'ssid_wifi': ssidWifi,
    'keterangan': keterangan,
  };

  String get labelStatus {
    switch (status) {
      case StatusAbsen.hadir: return 'Hadir';
      case StatusAbsen.terlambat: return 'Terlambat';
      case StatusAbsen.izin: return 'Izin';
      case StatusAbsen.sakit: return 'Sakit';
      case StatusAbsen.alpha: return 'Tidak Hadir';
    }
  }

  String get labelMetode {
    switch (metode) {
      case MetodeValidasi.gps: return 'GPS';
      case MetodeValidasi.wifi: return 'WiFi Kantor';
      case MetodeValidasi.manual: return 'Manual';
    }
  }

  @override
  List<Object?> get props => [id, pegawaiId, waktuMasuk];
}

// Model untuk rekap bulanan
class RekapBulanan {
  final String pegawaiId;
  final String namaPegawai;
  final int bulan;
  final int tahun;
  final int totalHadir;
  final int totalTerlambat;
  final int totalIzin;
  final int totalSakit;
  final int totalAlpha;
  final int totalHariKerja;

  const RekapBulanan({
    required this.pegawaiId,
    required this.namaPegawai,
    required this.bulan,
    required this.tahun,
    required this.totalHadir,
    required this.totalTerlambat,
    required this.totalIzin,
    required this.totalSakit,
    required this.totalAlpha,
    required this.totalHariKerja,
  });

  double get persentaseKehadiran =>
      totalHariKerja == 0 ? 0 : (totalHadir + totalTerlambat) / totalHariKerja * 100;
}