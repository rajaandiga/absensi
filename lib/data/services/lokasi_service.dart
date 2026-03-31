import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../core/constants/app_constants.dart';

enum HasilValidasi {
  berhasil,
  gagalIzinLokasi,
  gagalLokasiDinonaktifkan,
  gagalDiLuarArea,
  gagalWifi,
  gagalIzinWifi,
}

class HasilValidasiLokasi {
  final bool valid;
  final HasilValidasi hasil;
  final MetodeValidasiLokasi? metode;
  final double? jarak; // meter
  final String? ssid;
  final String pesan;

  const HasilValidasiLokasi({
    required this.valid,
    required this.hasil,
    this.metode,
    this.jarak,
    this.ssid,
    required this.pesan,
  });
}

enum MetodeValidasiLokasi { gps, wifi }

class LokasiService {
  final _networkInfo = NetworkInfo();

  /// Validasi utama — coba GPS dulu, fallback ke WiFi
  Future<HasilValidasiLokasi> validasiLokasi() async {
    // ── Lapis 1: GPS ──────────────────────────────────────────────────────
    final hasilGps = await _validasiGps();
    if (hasilGps.valid) return hasilGps;

    // GPS gagal karena di luar area → langsung tolak, jangan fallback WiFi
    // GPS gagal karena teknis (izin / sinyal) → coba WiFi
    if (hasilGps.hasil == HasilValidasi.gagalDiLuarArea) {
      return hasilGps;
    }

    // ── Lapis 2: WiFi ─────────────────────────────────────────────────────
    final hasilWifi = await _validasiWifi();
    return hasilWifi;
  }

  // ── Private: Validasi GPS ─────────────────────────────────────────────────
  Future<HasilValidasiLokasi> _validasiGps() async {
    // Cek apakah layanan lokasi aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const HasilValidasiLokasi(
        valid: false,
        hasil: HasilValidasi.gagalLokasiDinonaktifkan,
        pesan: 'Layanan GPS tidak aktif. Aktifkan GPS di pengaturan HP.',
      );
    }

    // Cek & minta izin lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const HasilValidasiLokasi(
          valid: false,
          hasil: HasilValidasi.gagalIzinLokasi,
          pesan: 'Izin lokasi ditolak. Aplikasi membutuhkan akses lokasi.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const HasilValidasiLokasi(
        valid: false,
        hasil: HasilValidasi.gagalIzinLokasi,
        pesan: 'Izin lokasi diblokir permanen. Buka pengaturan aplikasi untuk mengizinkan.',
      );
    }

    try {
      // Ambil posisi dengan akurasi tinggi, timeout 10 detik
      final posisi = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final jarak = _hitungJarak(
        posisi.latitude,
        posisi.longitude,
        AppConstants.kantorLatitude,
        AppConstants.kantorLongitude,
      );

      // Akurasi HP sendiri juga diperhitungkan
      // Jika akurasi GPS > 100m, sinyal terlalu lemah — tidak bisa dipercaya
      if (posisi.accuracy > 100) {
        return HasilValidasiLokasi(
          valid: false,
          hasil: HasilValidasi.gagalIzinLokasi,
          jarak: jarak,
          pesan: 'Sinyal GPS lemah (akurasi ${posisi.accuracy.toStringAsFixed(0)}m). Mencoba validasi WiFi...',
        );
      }

      if (jarak <= AppConstants.radiusMeters) {
        return HasilValidasiLokasi(
          valid: true,
          hasil: HasilValidasi.berhasil,
          metode: MetodeValidasiLokasi.gps,
          jarak: jarak,
          pesan: 'Lokasi terverifikasi via GPS (${jarak.toStringAsFixed(0)}m dari kantor)',
        );
      } else {
        return HasilValidasiLokasi(
          valid: false,
          hasil: HasilValidasi.gagalDiLuarArea,
          jarak: jarak,
          pesan: 'Kamu berada ${jarak.toStringAsFixed(0)}m dari kantor BPS. Absen hanya bisa dilakukan dalam radius ${AppConstants.radiusMeters.toInt()}m.',
        );
      }
    } catch (e) {
      // Timeout atau error GPS → coba WiFi
      return HasilValidasiLokasi(
        valid: false,
        hasil: HasilValidasi.gagalIzinLokasi,
        pesan: 'GPS timeout, mencoba validasi WiFi...',
      );
    }
  }

  // ── Private: Validasi WiFi ────────────────────────────────────────────────
  Future<HasilValidasiLokasi> _validasiWifi() async {
    try {
      final ssid = await _networkInfo.getWifiName();

      if (ssid == null || ssid.isEmpty) {
        return const HasilValidasiLokasi(
          valid: false,
          hasil: HasilValidasi.gagalWifi,
          pesan: 'Tidak terhubung ke WiFi. Pastikan GPS aktif atau sambungkan ke WiFi kantor BPS.',
        );
      }

      // Bersihkan tanda kutip yang kadang muncul di Android
      final ssidBersih = ssid.replaceAll('"', '').trim();

      final ssidValid = AppConstants.allowedSsids.any(
            (allowed) => allowed.toLowerCase() == ssidBersih.toLowerCase(),
      );

      if (ssidValid) {
        return HasilValidasiLokasi(
          valid: true,
          hasil: HasilValidasi.berhasil,
          metode: MetodeValidasiLokasi.wifi,
          ssid: ssidBersih,
          pesan: 'Lokasi terverifikasi via WiFi kantor ($ssidBersih)',
        );
      } else {
        return HasilValidasiLokasi(
          valid: false,
          hasil: HasilValidasi.gagalWifi,
          ssid: ssidBersih,
          pesan: 'WiFi "$ssidBersih" bukan jaringan resmi kantor BPS. Sambungkan ke WiFi BPS atau aktifkan GPS.',
        );
      }
    } catch (e) {
      return const HasilValidasiLokasi(
        valid: false,
        hasil: HasilValidasi.gagalIzinWifi,
        pesan: 'Tidak dapat membaca informasi WiFi. Pastikan GPS aktif.',
      );
    }
  }

  // ── Hitung jarak dua koordinat (Haversine formula) ───────────────────────
  double _hitungJarak(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Radius bumi dalam meter
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * pi / 180;
}