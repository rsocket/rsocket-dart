class WellKnownMimeType {
  static bool isWellKnownTypeId(int id) {
    return MIME_TYPES.containsKey(id);
  }

  static bool isWellKnownType(String? mimeType) {
    return MIME_TYPES.containsKey(mimeType);
  }

  static String? getMimeType(int id) {
    return MIME_TYPES[id];
  }

  static int? getMimeTypeId(String? mimeType) {
    return MIME_TYPES[mimeType];
  }

  static void addMimeType(int id, String mimeType) {
    MIME_TYPES[id] = mimeType;
    MIME_TYPES[mimeType] = id;
  }
}

final Map MIME_TYPES = {
  0x00: 'application/avro',
  'application/avro': 0x00,
  0x01: 'application/cbor',
  'application/cbor': 0x01,
  0x02: 'application/graphql',
  'application/graphql': 0x02,
  0x03: 'application/gzip',
  'application/gzip': 0x03,
  0x04: 'application/javascript',
  'application/javascript': 0x04,
  0x05: 'application/json',
  'application/json': 0x05,
  0x06: 'application/octet-stream',
  'application/octet-stream': 0x06,
  0x07: 'application/pdf',
  'application/pdf': 0x07,
  0x08: 'application/vnd.apache.thrift.binary',
  'application/vnd.apache.thrift.binary': 0x08,
  0x09: 'application/vnd.google.protobuf',
  'application/vnd.google.protobuf': 0x09,
  0x0a: 'application/xml',
  'application/xml': 0x0a,
  0x0b: 'application/zip',
  'application/zip': 0x0b,
  0x0c: 'audio/aac',
  'audio/aac': 0x0c,
  0x0d: 'audio/mp3',
  'audio/mp3': 0x0d,
  0x0e: 'audio/mp4',
  'audio/mp4': 0x0e,
  0x0f: 'audio/mpeg3',
  'audio/mpeg3': 0x0f,
  0x10: 'audio/mpeg',
  'audio/mpeg': 0x10,
  0x11: 'audio/ogg',
  'audio/ogg': 0x11,
  0x12: 'audio/opus',
  'audio/opus': 0x12,
  0x13: 'audio/vorbis',
  'audio/vorbis': 0x13,
  0x14: 'image/bmp',
  'image/bmp': 0x14,
  0x15: 'image/gif',
  'image/gif': 0x15,
  0x16: 'image/heic-sequence',
  'image/heic-sequence': 0x16,
  0x17: 'image/heic',
  'image/heic': 0x17,
  0x18: 'image/heif-sequence',
  'image/heif-sequence': 0x18,
  0x19: 'image/heif',
  'image/heif': 0x19,
  0x1a: 'image/jpeg',
  'image/jpeg': 0x1a,
  0x1b: 'image/png',
  'image/png': 0x1b,
  0x1c: 'image/tiff',
  'image/tiff': 0x1c,
  0x1d: 'multipart/mixed',
  'multipart/mixed': 0x1d,
  0x1e: 'text/css',
  'text/css': 0x1e,
  0x1f: 'text/csv',
  'text/csv': 0x1f,
  0x20: 'text/html',
  'text/html': 0x20,
  0x21: 'text/plain',
  'text/plain': 0x21,
  0x22: 'text/xml',
  'text/xml': 0x22,
  0x23: 'video/H264',
  'video/H264': 0x23,
  0x24: 'video/H265',
  'video/H265': 0x24,
  0x25: 'video/VP8',
  'video/VP8': 0x25,
  0x26: 'application/x-hessian',
  'application/x-hessian': 0x26,
  0x27: 'application/x-java-object',
  'application/x-java-object': 0x27,
  0x28: 'application/cloudevents+json',
  'application/cloudevents+json': 0x28,
  // ... reserved for future use ...
  0x7a: 'message/x.rsocket.mime-type.v0',
  'message/x.rsocket.mime-type.v0': 0x7a,
  0x7b: 'message/x.rsocket.accept-mime-types.v0',
  'message/x.rsocket.accept-mime-types.v0': 0x7b,
  0x7c: 'message/x.rsocket.authentication.v0',
  'message/x.rsocket.authentication.v0': 0x7c,
  0x7d: 'message/x.rsocket.tracing-zipkin.v0',
  'message/x.rsocket.tracing-zipkin.v0': 0x7d,
  0x7e: 'message/x.rsocket.routing.v0',
  'message/x.rsocket.routing.v0': 0x7e,
  0x7f: 'message/x.rsocket.composite-metadata.v0',
  'message/x.rsocket.composite-metadata.v0': 0x7f
};
