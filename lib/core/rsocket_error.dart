class RSocketException implements Exception {
  final int? code;
  final String message;

  RSocketException(this.code, this.message);

  @override
  String toString() {
    return 'RS-$code: $message';
  }

  Map toJson() => {'code': code, 'message': message};
}

class RSocketErrorCode {
  static const int RESERVED = 0x00000000;
  static const int INVALID_SETUP = 0x00000001;
  static const int UNSUPPORTED_SETUP = 0x00000002;
  static const int REJECTED_SETUP = 0x00000003;
  static const int REJECTED_RESUME = 0x00000004;
  static const int CONNECTION_ERROR = 0x00000101;
  static const int CONNECTION_CLOSE = 0x00000102;
  static const int APPLICATION_ERROR = 0x00000201;
  static const int REJECTED = 0x00000202;
  static const int CANCELED = 0x00000203;
  static const int INVALID = 0x00000204;
}

typedef ErrorConsumer = void Function(RSocketException error);
