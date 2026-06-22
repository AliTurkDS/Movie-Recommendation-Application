import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../core/constants.dart';

/// Talks to the Vercel cloud-backup function.
///
/// There is no real authentication: the user's email + password are hashed
/// together into an opaque key, and that key is the name of their JSON backup
/// in Blob storage. Same email + password ⇒ same key ⇒ same data, on any
/// device. A wrong password simply yields a different key (and thus "no backup
/// found"), so the password acts as a shared secret rather than a verified
/// credential.
class SyncService {
  SyncService([Dio? dio]) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Derives the opaque storage key from credentials. Email is normalised
  /// (trimmed + lower-cased) so casing/whitespace can't fork a user's data.
  static String keyFor(String email, String password) {
    final material = '${email.trim().toLowerCase()}:$password';
    return sha256.convert(utf8.encode(material)).toString();
  }

  Uri get _endpoint => Uri.parse('${SyncConfig.baseUrl}/api/data');

  /// Uploads the bundle for [key], overwriting any existing backup.
  Future<void> upload(String key, Map<String, dynamic> bundle) async {
    await _dio.postUri(
      _endpoint.replace(queryParameters: {'id': key}),
      data: jsonEncode(bundle),
      options: Options(
        contentType: 'application/json',
        responseType: ResponseType.plain,
      ),
    );
  }

  /// Downloads the bundle for [key], or returns null when no backup exists.
  Future<Map<String, dynamic>?> download(String key) async {
    try {
      final res = await _dio.getUri(
        _endpoint.replace(queryParameters: {'id': key}),
        options: Options(responseType: ResponseType.plain),
      );
      final body = res.data;
      if (body == null || (body is String && body.isEmpty)) return null;
      final decoded = jsonDecode(body is String ? body : jsonEncode(body));
      return decoded as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
