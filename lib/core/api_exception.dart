class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message);
  final int statusCode;
  final String code;
  final String message;

  bool get isAuthError => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 422;
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}
