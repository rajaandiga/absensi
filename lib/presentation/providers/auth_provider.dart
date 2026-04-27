import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/pegawai_model.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/app_constants.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();

  AuthStatus _status = AuthStatus.initial;
  Pegawai? _pegawai;
  String? _errorMessage;
  bool _sessionExpired = false;

  AuthStatus get status => _status;
  Pegawai? get pegawai => _pegawai;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _pegawai?.isAdmin ?? false;

  bool get sessionExpired => _sessionExpired;

  void resetSessionExpired() {
    _sessionExpired = false;
  }

  /// Cek apakah sudah login saat buka aplikasi, sekaligus daftarkan auto logout
  Future<void> cekStatusLogin() async {
    _status = AuthStatus.loading;
    notifyListeners();

    _api.onSessionExpired = () {
      if (_status == AuthStatus.authenticated) {
        _sessionExpired = true;
        _doLogout();
      }
    };

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
    _sessionExpired = false;
    notifyListeners();

    try {
      final response = await _api.login(nip: nip, password: password);

      final token = response['token'] as String;
      await _api.simpanToken(token);

      final pegawaiData = response['pegawai'] as Map<String, dynamic>;
      _pegawai = Pegawai.fromJson(pegawaiData);

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
    _sessionExpired = false;
    await _doLogout();
  }

  /// Internal logout — (sesi expired)
  Future<void> _doLogout() async {
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
    final msg = error.toString();
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    if (msg.contains('401')) {
      return 'password salah.';
    }
    if (msg.contains('DioException') || msg.contains('DioError')) {
      try {
        final dioError = error as dynamic;
        final responseData = dioError.response?.data;
        if (responseData != null && responseData['message'] != null) {
          return responseData['message'].toString();
        }
      } catch (_) {}
      return 'Error: $msg';
    }
    return 'Terjadi kesalahan: $msg';
  }
}