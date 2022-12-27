import 'dart:convert';
import 'dart:typed_data';

import '../io/bytes.dart';
import '../payload.dart';
import 'frame_types.dart' as frame_types;

const int MAJOR_VERSION = 1;
const int MINOR_VERSION = 0;

Iterable<RSocketFrame> parseFrames(List<int> chunk) sync* {
  var byteBuffer = RSocketByteBuffer.fromArray(chunk);
  while (byteBuffer.isReadable()) {
    var frame = parseFrame(byteBuffer);
    if (frame != null) {
      yield frame;
    }
  }
}

RSocketFrame? parseFrame(RSocketByteBuffer byteBuffer) {
  var header = RSocketHeader.fromBuffer(byteBuffer);
  RSocketFrame? frame;
  switch (header.type) {
    case frame_types.SETUP:
      frame = SetupFrame.fromBuffer(header, byteBuffer);
      break;
    case frame_types.LEASE:
      frame = LeaseFrame.fromBuffer(header, byteBuffer);
      break;
    case frame_types.KEEPALIVE:
      frame = KeepAliveFrame.fromBuffer(header, byteBuffer);
      break;
    case frame_types.REQUEST_RESPONSE:
      frame = RequestResponseFrame.fromBuffer(header, byteBuffer);
      break;
    case frame_types.REQUEST_FNF:
      frame = RequestFNFFrame.fromBuffer(header, byteBuffer);
      break;
    case frame_types.REQUEST_STREAM:
      frame = RequestStreamFrame.fromBuffer(header, byteBuffer);
      break;
    case frame_types.REQUEST_CHANNEL:
      frame = RequestChannelFrame.fromBuffer(header, byteBuffer);
      break;
    case frame_types.REQUEST_N:
      frame = RequestNFrame.fromBuffer(header, byteBuffer);
      break;
    case frame_types.CANCEL:
      frame = CancelFrame.fromBuffer(header, byteBuffer);
      break;
    case frame_types.ERROR:
      frame = ErrorFrame.fromBuffer(header, byteBuffer);
      break;
    case frame_types.PAYLOAD:
      frame = PayloadFrame.fromBuffer(header, byteBuffer);
      break;
    default:
      if (header.frameLength > 9) {
        byteBuffer.readBytes(header.frameLength - 9);
      }
      break;
  }
  return frame;
}

RSocketFrame? parseWebSocketFrame(List<int> data) {
  var frameLength = data.length;
  var byteBuffer = RSocketByteBuffer.fromArray(data)
    ..insertI24(frameLength)
    ..resetWriterIndex();
  return parseFrame(byteBuffer);
}

class RSocketHeader {
  int frameLength = 0;
  int streamId = 0;
  int type = 0;
  int flags = 0;
  bool metaPresent = false;

  RSocketHeader();

  RSocketHeader.fromBuffer(RSocketByteBuffer buffer) {
    var frameLength = buffer.readI24();
    if (frameLength != null) {
      this.frameLength = frameLength;
    }
    var streamId = buffer.readI32();
    if (streamId != null) {
      this.streamId = streamId;
    }
    var frameTypeByte = buffer.readI8();
    if (frameTypeByte != null) {
      type = frameTypeByte >> 2;
      metaPresent = (frameTypeByte & 0x01) == 1;
    }
    var flags = buffer.readI8();
    if (flags != null) {
      this.flags = flags;
    }
  }

  Map toJson() => {
        'frameLength': frameLength,
        'streamId': streamId,
        'type': type,
        'flags': flags,
        'metaPresent': metaPresent
      };
}

class RSocketFrame {
  late RSocketHeader header;
}

class SetupFrame extends RSocketFrame {
  Payload? payload;
  String metadataMimeType = 'message/x.rsocket.composite-metadata.v0';
  String dataMimeType = 'application/json';
  int keepAliveInterval = 20;
  int keepAliveMaxLifetime = 90;
  String? resumeToken;
  bool leaseEnable = false;

  SetupFrame();

  SetupFrame.fromBuffer(RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
    var resumeEnable = (header.flags & 0x80) > 0;
    leaseEnable = (header.flags & 0x40) > 0;
    // ignore: unused_local_variable
    var majorVersion = buffer.readI16();
    // ignore: unused_local_variable
    var minorVersion = buffer.readI16();
    var keepAliveInterval = buffer.readI32();
    if (keepAliveInterval != null) {
      this.keepAliveInterval = keepAliveInterval;
    }
    var keepAliveMaxLifetime = buffer.readI32();
    if (keepAliveMaxLifetime != null) {
      this.keepAliveMaxLifetime = keepAliveMaxLifetime;
    }
    //resume token extraction
    if (resumeEnable) {
      var resumeTokenLength = buffer.readI16();
      if (resumeTokenLength != null) {
        var tokenU8Array = buffer.readBytes(resumeTokenLength);
        if (tokenU8Array.isNotEmpty) {
          resumeToken = utf8.decode(tokenU8Array);
        }
      }
    }
    // metadata & data encoding
    var metadataMimeTypeLength = buffer.readI8();
    if (metadataMimeTypeLength != null) {
      var metadataMimeTypeU8Array = buffer.readBytes(metadataMimeTypeLength);
      if (metadataMimeTypeU8Array.isNotEmpty) {
        metadataMimeType = utf8.decode(metadataMimeTypeU8Array);
      }
    }
    var dataMimeTypeLength = buffer.readI8();
    if (dataMimeTypeLength != null) {
      var dataMimeTypeU8Array = buffer.readBytes(dataMimeTypeLength);
      if (dataMimeTypeU8Array.isNotEmpty) {
        dataMimeType = utf8.decode(dataMimeTypeU8Array);
      }
    }
    payload = decodePayload(buffer, header.metaPresent, header.frameLength);
  }
}

class LeaseFrame extends RSocketFrame {
  int timeToLive = 0;
  int numberOfRequests = 0;

  LeaseFrame();

  LeaseFrame.fromBuffer(RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
    var timeToLive = buffer.readI32();
    if (timeToLive != null) {
      this.timeToLive = timeToLive;
    }
    var numberOfRequests = buffer.readI32();
    if (numberOfRequests != null) {
      this.numberOfRequests = numberOfRequests;
    }
  }
}

class KeepAliveFrame extends RSocketFrame {
  int lastReceivedPosition = 0;
  Payload? payload;
  bool respond = false;

  KeepAliveFrame();

  KeepAliveFrame.fromBuffer(RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
    var lastReceivedPosition = buffer.readI32();
    if (lastReceivedPosition != null) {
      this.lastReceivedPosition = lastReceivedPosition;
    }
    if (header.frameLength > 0) {
      payload = decodePayload(buffer, header.metaPresent, header.frameLength);
    }
    respond = (header.flags & 0x80) > 0;
  }
}

class ErrorFrame extends RSocketFrame {
  int? code;
  String message = '';

  ErrorFrame();

  ErrorFrame.fromBuffer(RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
    code = buffer.readI32();
    var dataLength = header.frameLength - 10;
    if (dataLength > 0) {
      var u8Array = buffer.readUint8List(dataLength);
      if (u8Array.isNotEmpty) {
        message = utf8.decode(u8Array);
      }
    }
  }
}

class CancelFrame extends RSocketFrame {
  CancelFrame();

  CancelFrame.fromBuffer(RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
  }
}

class RequestResponseFrame extends RSocketFrame {
  Payload? payload;

  RequestResponseFrame();

  RequestResponseFrame.fromBuffer(
      RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
    if (header.frameLength > 0) {
      payload = decodePayload(buffer, header.metaPresent, header.frameLength);
    }
  }
}

class RequestFNFFrame extends RSocketFrame {
  Payload? payload;

  RequestFNFFrame();

  RequestFNFFrame.fromBuffer(RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
    if (header.frameLength > 0) {
      payload = decodePayload(buffer, header.metaPresent, header.frameLength);
    }
  }
}

class RequestStreamFrame extends RSocketFrame {
  int? initialRequestN;
  Payload? payload;

  RequestStreamFrame();

  RequestStreamFrame.fromBuffer(
      RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
    initialRequestN = buffer.readI32();
    if (header.frameLength > 0) {
      payload = decodePayload(buffer, header.metaPresent, header.frameLength);
    }
  }
}

class RequestChannelFrame extends RSocketFrame {
  int? initialRequestN;
  Payload? payload;

  RequestChannelFrame();

  RequestChannelFrame.fromBuffer(
      RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
    initialRequestN = buffer.readI32();
    if (header.frameLength > 0) {
      payload = decodePayload(buffer, header.metaPresent, header.frameLength);
    }
  }
}

class RequestNFrame extends RSocketFrame {
  int? initialRequestN;

  RequestNFrame();

  RequestNFrame.fromBuffer(RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
    initialRequestN = buffer.readI32();
  }
}

class MetadataPushFrame extends RSocketFrame {
  Payload? payload;

  MetadataPushFrame();

  MetadataPushFrame.fromBuffer(RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
    if (header.frameLength > 0) {
      var metadataBytes = buffer.readBytes(header.frameLength - 6);
      payload = Payload()..metadata = metadataBytes as Uint8List?;
    }
  }
}

class PayloadFrame extends RSocketFrame {
  Payload? payload;
  bool completed = false;

  PayloadFrame();

  PayloadFrame.fromBuffer(RSocketHeader header, RSocketByteBuffer buffer) {
    this.header = header;
    completed = (header.flags & 0x40) > 0;
    if (header.frameLength > 0) {
      payload = decodePayload(buffer, header.metaPresent, header.frameLength);
    }
  }
}

class FrameCodec {
  static Uint8List encodeSetupFrame(
      int keepAliveInterval,
      int keepAliveMaxLifetime,
      String metadataMimeType,
      String dataMimeType,
      Payload? setupPayload) {
    var frameBuffer = RSocketByteBuffer();
    frameBuffer.writeI24(0); // frame length
    frameBuffer.writeI32(0); //stream id
    //frame type with metadata indicator without resume token and lease
    writeTFrameTypeAndFlags(
        frameBuffer, frame_types.SETUP, setupPayload?.metadata, 0);
    frameBuffer.writeI16(MAJOR_VERSION);
    frameBuffer.writeI16(MINOR_VERSION);
    frameBuffer.writeI32(keepAliveInterval);
    frameBuffer.writeI32(keepAliveMaxLifetime);
    //Metadata Encoding MIME Type
    frameBuffer.writeI8(metadataMimeType.length);
    frameBuffer.writeBytes(utf8.encode(metadataMimeType));
    //Data Encoding MIME Type
    frameBuffer.writeI8(dataMimeType.length);
    frameBuffer.writeBytes(utf8.encode(dataMimeType));
    // Metadata & Setup Payload
    writePayload(frameBuffer, setupPayload);
    // refill frame length
    refillFrameLength(frameBuffer);
    return frameBuffer.toUint8Array();
  }

  static Uint8List encodeKeepAlive(bool respond, int lastPosition) {
    var frameBuffer = RSocketByteBuffer();
    frameBuffer.writeI24(0); // frame length
    frameBuffer.writeI32(0); //stream id
    frameBuffer.writeI8(frame_types.KEEPALIVE << 2);
    if (respond) {
      frameBuffer.writeI8(0x80);
    } else {
      frameBuffer.writeI8(0);
    }
    frameBuffer.writeI64(lastPosition);
    refillFrameLength(frameBuffer);
    return frameBuffer.toUint8Array();
  }

  static Uint8List encodeRequestResponseFrame(int streamId, Payload payload) {
    var frameBuffer = RSocketByteBuffer();
    frameBuffer.writeI24(0); // frame length
    frameBuffer.writeI32(streamId); //stream id
    writeTFrameTypeAndFlags(
        frameBuffer, frame_types.REQUEST_RESPONSE, payload.metadata, 0);
    writePayload(frameBuffer, payload);
    refillFrameLength(frameBuffer);
    return frameBuffer.toUint8Array();
  }

  static Uint8List encodeFireAndForgetFrame(int streamId, Payload payload) {
    var frameBuffer = RSocketByteBuffer();
    frameBuffer.writeI24(0); // frame length
    frameBuffer.writeI32(streamId); //stream id
    writeTFrameTypeAndFlags(
        frameBuffer, frame_types.REQUEST_FNF, payload.metadata, 0);
    writePayload(frameBuffer, payload);
    refillFrameLength(frameBuffer);
    return frameBuffer.toUint8Array();
  }

  static Uint8List encodeMetadataFrame(int streamId, Payload payload) {
    var frameBuffer = RSocketByteBuffer();
    frameBuffer.writeI24(0); // frame length
    frameBuffer.writeI32(streamId); //stream id
    frameBuffer.writeI8((frame_types.METADATA_PUSH << 2) | 0x01);
    frameBuffer.writeI8(0);
    frameBuffer.writeBytes(payload.metadata!);
    refillFrameLength(frameBuffer);
    return frameBuffer.toUint8Array();
  }

  static Uint8List encodeRequestStreamFrame(
      int streamId, int initialRequestN, Payload payload) {
    var frameBuffer = RSocketByteBuffer();
    frameBuffer.writeI24(0); // frame length
    frameBuffer.writeI32(streamId); //stream id
    writeTFrameTypeAndFlags(
        frameBuffer, frame_types.REQUEST_STREAM, payload.metadata, 0);
    frameBuffer.writeI32(initialRequestN);
    writePayload(frameBuffer, payload);
    refillFrameLength(frameBuffer);
    return frameBuffer.toUint8Array();
  }

  static Uint8List encodeChannelFrame(
      int streamId, int initialRequestN, Payload payload) {
    var frameBuffer = RSocketByteBuffer();
    frameBuffer.writeI24(0); // frame length
    frameBuffer.writeI32(streamId); //stream id
    writeTFrameTypeAndFlags(
        frameBuffer, frame_types.REQUEST_CHANNEL, payload.metadata, 0);
    frameBuffer.writeI32(initialRequestN);
    writePayload(frameBuffer, payload);
    refillFrameLength(frameBuffer);
    return frameBuffer.toUint8Array();
  }

  static Uint8List encodePayloadFrame(
      int streamId, bool completed, Payload? payload) {
    var frameBuffer = RSocketByteBuffer();
    frameBuffer.writeI24(0); // frame length
    frameBuffer.writeI32(streamId); //stream id
    var flags = 0;
    if (completed) {
      flags = flags | 0x40; //complete
    } else {
      flags = flags | 0x20; //next
    }
    if (payload != null) {
      writeTFrameTypeAndFlags(
          frameBuffer, frame_types.PAYLOAD, payload.metadata, flags);
      writePayload(frameBuffer, payload);
    } else {
      writeTFrameTypeAndFlags(frameBuffer, frame_types.PAYLOAD, null, flags);
    }
    refillFrameLength(frameBuffer);
    return frameBuffer.toUint8Array();
  }

  static Uint8List encodeErrorFrame(int streamId, int code, String message) {
    var frameBuffer = RSocketByteBuffer();
    frameBuffer.writeI24(0); // frame length
    frameBuffer.writeI32(streamId); //stream id
    frameBuffer.writeI8(frame_types.ERROR << 2);
    frameBuffer.writeI8(0);
    frameBuffer.writeI32(code);
    frameBuffer.writeBytes(utf8.encode(message));
    refillFrameLength(frameBuffer);
    return frameBuffer.toUint8Array();
  }

  static Uint8List encodeCancelFrame(int streamId) {
    var frameBuffer = RSocketByteBuffer();
    frameBuffer.writeI24(0); // frame length
    frameBuffer.writeI32(streamId); //stream id
    frameBuffer.writeI8(frame_types.CANCEL << 2);
    frameBuffer.writeI8(0);
    refillFrameLength(frameBuffer);
    return frameBuffer.toUint8Array();
  }
}

Payload decodePayload(
    RSocketByteBuffer buffer, bool metadataPresent, int frameLength) {
  var payload = Payload();
  var dataLength = frameLength - 6;
  if (metadataPresent) {
    var metadataLength = buffer.readI24();
    if (metadataLength != null) {
      dataLength = dataLength - 3 - metadataLength;
      if (metadataLength > 0) {
        payload.metadata = buffer.readUint8List(metadataLength);
      }
    }
  }
  if (dataLength > 0) {
    payload.data = buffer.readUint8List(dataLength);
  }
  return payload;
}

void writeTFrameTypeAndFlags(RSocketByteBuffer frameBuffer, int frameType,
    Uint8List? metadata, int flags) {
  if (metadata != null) {
    frameBuffer.writeI8(frameType << 2 | 1);
  } else {
    frameBuffer.writeI8(frameType << 2);
  }
  frameBuffer.writeI8(flags);
}

void writePayload(RSocketByteBuffer frameBuffer, Payload? payload) {
  if (payload != null) {
    if (payload.metadata != null) {
      frameBuffer.writeI24(payload.metadata!.length);
      frameBuffer.writeUint8List(payload.metadata!);
    }
    if (payload.data != null) {
      frameBuffer.writeUint8List(payload.data!);
    }
  }
}

void refillFrameLength(RSocketByteBuffer frameBuffer) {
  var frameLength = frameBuffer.capacity() - 3;
  frameBuffer.resetWriterIndex();
  frameBuffer.writeI24(frameLength);
}
