import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/models/pegawai_model.dart';
import '../data/services/api_service.dart';
import '../core/constants/app_constants.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();

  AuthStatus _status = AuthStatus.initial;
  Pegawai? _pegawai;
  String? _errorMessage;

  AuthStatus get status => _status;
  Pegawai? get pegawai => _pegawai;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _pegawai?.isAdmin ?? false;

  /// Cek apakah sudah login saat buka aplikasi
  Future<void> cekStatusLogin() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final sudahLogin = await _api.sudahLogin();
    if (sudahLogin) {
      await _muatDataPegawai();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> login(String nip, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.login(nip: nip, password: password);

      final token = response['token'] as String;
      await _api.simpanToken(token);

      final pegawaiData = response['pegawai'] as Map<String, dynamic>;
      _pegawai = Pegawai.fromJson(pegawaiData);

      // Simpan data pegawai lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUser, jsonEncode(pegawaiData));

      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _parseError(e);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUser);
    _pegawai = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _muatDataPegawai() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(AppConstants.keyUser);
      if (userData != null) {
        _pegawai = Pegawai.fromJson(jsonDecode(userData));
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  String _parseError(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    if (error.toString().contains('401')) {
      return 'NIP atau password salah.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}