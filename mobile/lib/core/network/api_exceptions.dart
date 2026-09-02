class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({required this.message, this.statusCode, this.details});

  @override
  String toString() => 'ApiException: $message (Code:$statusCode)';
}

class NetworkException extends ApiException {
  NetworkException([
    String message =
        'Unable to connect to server. Please check your internet connection.',
  ]) : super(message: message);
}

class ServerWarmingException extends ApiException {
  ServerWarmingException([
    String message = 'AI Engine is waking up, please retry in a few seconds...',
  ]) : super(message: message, statusCode: 503);
}

class ProductNotFoundException extends ApiException {
  ProductNotFoundException([
    String message =
        'Product barcode not cataloged. Please try Label OCR photo mode.',
  ]) : super(message: message, statusCode: 404);
}
