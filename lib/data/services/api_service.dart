import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

/// Service HTTP — semua panggilan ke backend BPS melewati sini.
/// Saat backend BPS siap, cukup ganti baseUrl di AppConstants.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    // Log request/response saat development — hapus saat production
    _dio.interceptors.add(PrettyDioLogger(
      requestBody: true,
      responseBody: true,
    ));

    // Interceptor: otomatis sisipkan token di setiap request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.keyToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Token expired → bisa tambahkan logout otomatis di sini
        handler.next(error);
      },
    ));
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String nip,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'nip': nip,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage.delete(key: AppConstants.keyToken);
  }

  // ── Absensi ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitAbsen({
    required String pegawaiId,
    required String jenis, // 'masuk' | 'pulang'
    required String metode, // 'gps' | 'wifi'
    double? latitude,
    double? longitude,
    String? ssidWifi,
    String? acaraId,
  }) async {
    final response = await _dio.post('/absensi', data: {
      'pegawai_id': pegawaiId,
      'jenis': jenis,
      'metode': metode,
      'latitude': latitude,
      'longitude': longitude,
      'ssid_wifi': ssidWifi,
      'acara_id': acaraId,
      'waktu': DateTime.now().toIso8601String(),
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStatusHariIni(String pegawaiId) async {
    final response = await _dio.get('/absensi/hari-ini/$pegawaiId');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getRiwayatAbsen({
    required String pegawaiId,
    required int bulan,
    required int tahun,
  }) async {
    final response = await _dio.get('/absensi/riwayat', queryParameters: {
      'pegawai_id': pegawaiId,
      'bulan': bulan,
      'tahun': tahun,
    });
    return response.data as List<dynamic>;
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getSemuaAbsensiHariIni() async {
    final response = await _dio.get('/admin/absensi/hari-ini');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getRekapBulanan({
    required int bulan,
    required int tahun,
  }) async {
    final response = await _dio.get('/admin/rekap', queryParameters: {
      'bulan': bulan,
      'tahun': tahun,
    });
    return response.data as List<dynamic>;
  }

  // ── Token Management ──────────────────────────────────────────────────────

  Future<void> simpanToken(String token) async {
    await _storage.write(key: AppConstants.keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.keyToken);
  }

  Future<bool> sudahLogin() async {
    final token = await _storage.read(key: AppConstants.keyToken);
    return token != null && token.isNotEmpty;
  }
}