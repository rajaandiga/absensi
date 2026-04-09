class AppConstants {
  // Koordinat GPS kantor BPS Provinsi Jambi
  static const double kantorLatitude = -1.6063162306134218;
  static const double kantorLongitude = 103.58308582619074;
  static const double radiusMeters = 50.0;

  // Nama WiFi resmi kantor BPS
  static const List<String> allowedSsids = [
    'BPS Provinsi Jambi',
    'KANTOR BPS PROVINSI JAMBI',
    'KANTOR BPS PROVINSI JAMBI-5G',
    'Aula BPS Prov Jambi',
    'Ruangan Kepala',
    'Produksi',
    'Sekretariat',
    'Keuangan',
    'PBJ&SDM',
  ];

  // URL backend BPS (isi saat server sudah siap)
  static const String baseUrl = 'https://absensidatabase-production-9b3c.up.railway.app';

  // Timeout
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);

  // Storage keys
  static const String keyToken = 'auth_token';
  static const String keyUser = 'user_data';

  // Jam kerja (untuk menentukan terlambat)
  static const int jamMasukHour = 8;
  static const int jamMasukMinute = 0;
}
