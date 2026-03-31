import 'package:flutter/foundation.dart';
import '../data/services/lokasi_service.dart';
import '../data/services/api_service.dart';
import '../data/models/absensi_model.dart';
import '../data/models/pegawai_model.dart';

enum AbsenStatus { idle, memvalidasi, berhasil, gagal }

class AbsenProvider extends ChangeNotifier {
  final _lokasiService = LokasiService();
  final _api = ApiService();

  AbsenStatus _status = AbsenStatus.idle;
  String _pesan = '';
  HasilValidasiLokasi? _hasilValidasi;
  bool _sudahAbsenMasuk = false;
  bool _sudahAbsenPulang = false;
  DateTime? _waktuMasuk;
  DateTime? _waktuPulang;

  AbsenStatus get status => _status;
  String get pesan => _pesan;
  HasilValidasiLokasi? get hasilValidasi => _hasilValidasi;
  bool get sudahAbsenMasuk => _sudahAbsenMasuk;
  bool get sudahAbsenPulang => _sudahAbsenPulang;
  DateTime? get waktuMasuk => _waktuMasuk;
  DateTime? get waktuPulang => _waktuPulang;

  /// Proses absen — validasi lokasi lalu kirim ke server
  Future<void> absen(Pegawai pegawai, {String? acaraId}) async {
    _status = AbsenStatus.memvalidasi;
    _pesan = 'Memvalidasi lokasi...';
    notifyListeners();

    // 1. Validasi lokasi (GPS → WiFi otomatis)
    _hasilValidasi = await _lokasiService.validasiLokasi();

    if (!_hasilValidasi!.valid) {
      _status = AbsenStatus.gagal;
      _pesan = _hasilValidasi!.pesan;
      notifyListeners();
      return;
    }

    // 2. Kirim ke server
    _pesan = 'Menyimpan absensi...';
    notifyListeners();

    try {
      final jenisAbsen = _sudahAbsenMasuk ? 'pulang' : 'masuk';
      final metode = _hasilValidasi!.metode == MetodeValidasiLokasi.wifi
          ? 'wifi'
          : 'gps';

      await _api.submitAbsen(
        pegawaiId: pegawai.id,
        jenis: jenisAbsen,
        metode: metode,
        latitude: _hasilValidasi!.jarak != null ? null : null,
        ssidWifi: _hasilValidasi!.ssid,
        acaraId: acaraId,
      );

      // Update state lokal
      if (!_sudahAbsenMasuk) {
        _sudahAbsenMasuk = true;
        _waktuMasuk = DateTime.now();
      } else {
        _sudahAbsenPulang = true;
        _waktuPulang = DateTime.now();
      }

      _status = AbsenStatus.berhasil;
      _pesan = _hasilValidasi!.pesan;
      notifyListeners();
    } catch (e) {
      _status = AbsenStatus.gagal;
      _pesan = 'Gagal menyimpan absensi ke server. Coba lagi.';
      notifyListeners();
    }
  }

  /// Load status absen hari ini dari server
  Future<void> muatStatusHariIni(String pegawaiId) async {
    try {
      final data = await _api.getStatusHariIni(pegawaiId);
      _sudahAbsenMasuk = data['sudah_masuk'] as bool? ?? false;
      _sudahAbsenPulang = data['sudah_pulang'] as bool? ?? false;
      if (data['waktu_masuk'] != null) {
        _waktuMasuk = DateTime.parse(data['waktu_masuk'] as String);
      }
      if (data['waktu_pulang'] != null) {
        _waktuPulang = DateTime.parse(data['waktu_pulang'] as String);
      }
      notifyListeners();
    } catch (_) {
      // Gagal load status — biarkan default (belum absen)
    }
  }

  void reset() {
    _status = AbsenStatus.idle;
    _pesan = '';
    _hasilValidasi = null;
    notifyListeners();
  }
}