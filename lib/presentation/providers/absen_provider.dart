import 'package:flutter/foundation.dart';
import '../../data/services/lokasi_service.dart';
import '../../data/services/api_service.dart';
import '../../data/models/absensi_model.dart';
import '../../data/models/pegawai_model.dart';
import '../../data/models/jadwal_wfh_model.dart';

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

  // [FIX #3] Simpan tanggal terakhir status dimuat, untuk deteksi ganti hari
  DateTime? _tanggalStatusDimuat;

  List<Absensi> _riwayat = [];
  bool _loadingRiwayat = false;

  // Jadwal WFH — diambil dari server, default Jumat
  List<JadwalWfh> _jadwalWfh = JadwalWfh.defaultJadwal();

  AbsenStatus get status => _status;
  String get pesan => _pesan;
  HasilValidasiLokasi? get hasilValidasi => _hasilValidasi;
  bool get sudahAbsenMasuk => _sudahAbsenMasuk;
  bool get sudahAbsenPulang => _sudahAbsenPulang;
  DateTime? get waktuMasuk => _waktuMasuk;
  DateTime? get waktuPulang => _waktuPulang;
  List<Absensi> get riwayat => _riwayat;
  bool get loadingRiwayat => _loadingRiwayat;
  List<JadwalWfh> get jadwalWfh => _jadwalWfh;

  /// Apakah hari ini adalah hari WFH berdasarkan jadwal
  bool get hariIniWfh {
    final hariIni = DateTime.now().weekday; // 1=Sen ... 5=Jum
    return _jadwalWfh.any((j) => j.aktif && j.weekday == hariIni);
  }

  /// Muat jadwal WFH dari server (fallback ke default kalau gagal)
  Future<void> muatJadwalWfh() async {
    try {
      final data = await _api.getJadwalWfh();
      if (data.isNotEmpty) {
        _jadwalWfh = data
            .map((e) => JadwalWfh.fromJson(e as Map<String, dynamic>))
            .where((j) => j.aktif)
            .toList();
      }
      notifyListeners();
    } catch (_) {
      // Tetap pakai default (Jumat)
    }
  }

  /// Proses absen — WFH bypass lokasi, WFO validasi GPS/WiFi
  Future<void> absen(Pegawai pegawai) async {
    _status = AbsenStatus.memvalidasi;

    if (hariIniWfh) {
      _pesan = 'Mencatat absen WFH...';
    } else {
      _pesan = 'Memvalidasi lokasi...';
    }
    notifyListeners();

    String metode;
    double? lat, lon;
    String? ssid;

    if (hariIniWfh) {
      // WFH: bypass lokasi sepenuhnya
      metode = 'wfh';
      _pesan = 'Menyimpan absensi WFH...';
      notifyListeners();
    } else {
      // WFO: validasi GPS lalu WiFi
      _hasilValidasi = await _lokasiService.validasiLokasi();
      if (!_hasilValidasi!.valid) {
        _status = AbsenStatus.gagal;
        _pesan = _hasilValidasi!.pesan;
        notifyListeners();
        return;
      }
      metode = _hasilValidasi!.metode == MetodeValidasiLokasi.wifi ? 'wifi' : 'gps';
      lat = _hasilValidasi!.latitude;
      lon = _hasilValidasi!.longitude;
      ssid = _hasilValidasi!.ssid;
      _pesan = 'Menyimpan absensi...';
      notifyListeners();
    }

    try {
      final jenisAbsen = _sudahAbsenMasuk ? 'pulang' : 'masuk';

      await _api.submitAbsen(
        pegawaiId: pegawai.id,
        jenis: jenisAbsen,
        metode: metode,
        latitude: lat,
        longitude: lon,
        ssidWifi: ssid,
      );

      final now = DateTime.now();
      if (!_sudahAbsenMasuk) {
        _sudahAbsenMasuk = true;
        _waktuMasuk = now;
      } else {
        _sudahAbsenPulang = true;
        _waktuPulang = now;
      }

      _status = AbsenStatus.berhasil;
      if (hariIniWfh) {
        _pesan = jenisAbsen == 'masuk'
            ? 'Absen masuk WFH berhasil dicatat ✓'
            : 'Absen pulang WFH berhasil dicatat ✓';
      } else {
        _pesan = _hasilValidasi?.pesan ?? 'Absensi berhasil dicatat';
      }
      notifyListeners();

      await muatStatusHariIni(pegawai.id);

      await muatRiwayat(
        pegawaiId: pegawai.id,
        bulan: now.month,
        tahun: now.year,
      );
    } catch (e) {
      _status = AbsenStatus.gagal;
      _pesan = 'Gagal menyimpan absensi ke server. Coba lagi.';
      notifyListeners();
    }
  }

  bool _hariSama(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> muatStatusHariIni(String pegawaiId) async {
    final hariIni = DateTime.now();

    if (_tanggalStatusDimuat != null &&
        !_hariSama(_tanggalStatusDimuat!, hariIni)) {
      _sudahAbsenMasuk = false;
      _sudahAbsenPulang = false;
      _waktuMasuk = null;
      _waktuPulang = null;
      notifyListeners();
    }

    for (int attempt = 0; attempt < 3; attempt++) {
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
        _tanggalStatusDimuat = hariIni;
        notifyListeners();
        return;
      } catch (_) {
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    _tanggalStatusDimuat = hariIni;
  }

  Future<void> muatRiwayat({
    required String pegawaiId,
    required int bulan,
    required int tahun,
  }) async {
    _loadingRiwayat = true;
    notifyListeners();
    try {
      final data = await _api.getRiwayatAbsen(
        pegawaiId: pegawaiId,
        bulan: bulan,
        tahun: tahun,
      );
      _riwayat = data
          .map((e) => Absensi.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _riwayat = [];
    }
    _loadingRiwayat = false;
    notifyListeners();
  }

  void reset() {
    _status = AbsenStatus.idle;
    _pesan = '';
    _hasilValidasi = null;
    notifyListeners();
  }
}
