import 'package:equatable/equatable.dart';

enum JenisIzin { izin, sakit }

enum StatusIzin { pending, disetujui, ditolak }

class IzinModel extends Equatable {
  final String id;
  final String pegawaiId;
  final String namaPegawai;
  final JenisIzin jenis;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String keterangan;
  final StatusIzin status;
  final String? lampiranUrl;
  final DateTime diajukanPada;

  const IzinModel({
    required this.id,
    required this.pegawaiId,
    required this.namaPegawai,
    required this.jenis,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.keterangan,
    required this.status,
    this.lampiranUrl,
    required this.diajukanPada,
  });

  factory IzinModel.fromJson(Map<String, dynamic> json) {
    return IzinModel(
      id: json['id'] as String,
      pegawaiId: json['pegawai_id'] as String,
      namaPegawai: json['nama_pegawai'] as String? ?? '',
      jenis: json['jenis'] == 'sakit' ? JenisIzin.sakit : JenisIzin.izin,
      tanggalMulai: DateTime.parse(json['tanggal_mulai'] as String),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai'] as String),
      keterangan: json['keterangan'] as String? ?? '',
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      lampiranUrl: json['lampiran_url'] as String?,
      diajukanPada: DateTime.parse(
          json['diajukan_pada'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  static StatusIzin _parseStatus(String s) {
    switch (s) {
      case 'disetujui': return StatusIzin.disetujui;
      case 'ditolak': return StatusIzin.ditolak;
      default: return StatusIzin.pending;
    }
  }

  int get jumlahHari =>
      tanggalSelesai.difference(tanggalMulai).inDays + 1;

  String get labelJenis => jenis == JenisIzin.sakit ? 'Sakit' : 'Izin';

  String get labelStatus {
    switch (status) {
      case StatusIzin.pending: return 'Menunggu';
      case StatusIzin.disetujui: return 'Disetujui';
      case StatusIzin.ditolak: return 'Ditolak';
    }
  }

  @override
  List<Object?> get props => [id, pegawaiId, tanggalMulai];
}
