import 'package:equatable/equatable.dart';

enum RolePengguna { pegawai, admin }

enum TipePegawai { pns, mahasiswaMagang, karyawanSwasta, tamu }

class Pegawai extends Equatable {
  final String id;
  final String nip; // NIP untuk PNS, NIM untuk mahasiswa, dsb
  final String nama;
  final String email;
  final String jabatan;
  final String unitKerja;
  final RolePengguna role;
  final TipePegawai tipe;

  const Pegawai({
    required this.id,
    required this.nip,
    required this.nama,
    required this.email,
    required this.jabatan,
    required this.unitKerja,
    required this.role,
    required this.tipe,
  });

  factory Pegawai.fromJson(Map<String, dynamic> json) {
    return Pegawai(
      id: json['id'] as String,
      nip: json['nip'] as String,
      nama: json['nama'] as String,
      email: json['email'] as String,
      jabatan: json['jabatan'] as String? ?? '',
      unitKerja: json['unit_kerja'] as String? ?? '',
      role: json['role'] == 'admin' ? RolePengguna.admin : RolePengguna.pegawai,
      tipe: _parseTipe(json['tipe'] as String? ?? 'pns'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nip': nip,
    'nama': nama,
    'email': email,
    'jabatan': jabatan,
    'unit_kerja': unitKerja,
    'role': role.name,
    'tipe': tipe.name,
  };

  static TipePegawai _parseTipe(String tipe) {
    switch (tipe) {
      case 'mahasiswa_magang': return TipePegawai.mahasiswaMagang;
      case 'karyawan_swasta': return TipePegawai.karyawanSwasta;
      case 'tamu': return TipePegawai.tamu;
      default: return TipePegawai.pns;
    }
  }

  String get labelTipe {
    switch (tipe) {
      case TipePegawai.pns: return 'PNS / ASN';
      case TipePegawai.mahasiswaMagang: return 'Mahasiswa Magang';
      case TipePegawai.karyawanSwasta: return 'Karyawan Swasta';
      case TipePegawai.tamu: return 'Tamu';
    }
  }

  bool get isAdmin => role == RolePengguna.admin;

  @override
  List<Object?> get props => [id, nip, nama, email, role, tipe];
}