import 'dart:convert';
import 'dart:typed_data';

import '../io/bytes.dart';
import '../metadata/wellknown_mimetype.dart';

class CompositeMetadata extends Iterable<MetadataEntry> {
  RSocketByteBuffer buffer;

  CompositeMetadata(this.buffer);

  static CompositeMetadata fromEntries(List<MetadataEntry> entries) {
    var compositeMetadata = CompositeMetadata(RSocketByteBuffer());
    for (var entry in entries) {
      compositeMetadata.addMetadata(entry);
    }
    return compositeMetadata;
  }

  static CompositeMetadata fromU8Array(Uint8List u8Array) {
    return CompositeMetadata(RSocketByteBuffer.fromUint8List(u8Array));
  }

  void addMetadata(MetadataEntry metadata) {
    if (WellKnownMimeType.isWellKnownType(metadata.mimeType)) {
      addWellKnownMimeType(WellKnownMimeType.getMimeTypeId(metadata.mimeType)!,
          metadata.content!);
    } else {
      addExplicitMimeType(metadata.mimeType, metadata.content);
    }
  }

  void addWellKnownMimeType(int typeId, Uint8List content) {
    buffer.writeI8(typeId | 0x80);
    buffer.writeI24(content.length);
    buffer.writeUint8List(content);
  }

  void addExplicitMimeType(String? mimeType, Uint8List? content) {
    if (WellKnownMimeType.isWellKnownType(mimeType)) {
      addWellKnownMimeType(
          WellKnownMimeType.getMimeTypeId(mimeType)!, content!);
    } else {
      var mimeTypeArray = utf8.encode(mimeType!);
      buffer.writeI8(mimeTypeArray.length);
      buffer.writeBytes(mimeTypeArray);
      buffer.writeI24(content!.length);
      buffer.writeUint8List(content);
    }
  }

  Uint8List toUint8Array() {
    return buffer.toUint8Array();
  }

  Iterable<MetadataEntry> parseEntries() sync* {
    while (buffer.isReadable()) {
      var metadataTypeOrLength = buffer.readI8();
      if (metadataTypeOrLength != null) {
        if ((metadataTypeOrLength >= 0x80)) {
          var typeId = metadataTypeOrLength - 0x80;
          var mimeType = WellKnownMimeType.getMimeType(typeId);
          var dataLength = buffer.readI24();
          if (dataLength != null) {
            var content = buffer.readUint8List(dataLength);
            if (content.isNotEmpty) {
              yield MetadataEntry.fromContent(content, mimeType, typeId);
            }
          }
        } else {
          var mimeTypeU8Array = buffer.readBytes(metadataTypeOrLength);
          if (mimeTypeU8Array.isNotEmpty) {
            var dataLength = buffer.readI24();
            if (dataLength != null) {
              var content = buffer.readUint8List(dataLength);
              if (content.isNotEmpty) {
                var mimeType = utf8.decode(mimeTypeU8Array);
                yield MetadataEntry.fromContent(content, mimeType);
              }
            }
          }
        }
      }
    }
  }

  @override
  Iterator<MetadataEntry> get iterator => parseEntries().iterator;
}

class MetadataEntry {
  Uint8List? content;
  String? mimeType;
  int? id;

  MetadataEntry();

  MetadataEntry.fromContent(this.content, this.mimeType, [this.id]);
}

class TaggingMetadata extends MetadataEntry {
  late List<String> tags;

  TaggingMetadata(String? mimeType, List<String> tags) {
    this.mimeType = mimeType;
    this.tags = tags;
    var byteBuffer = RSocketByteBuffer();
    tags.forEach((tag) {
      var tagU8Array = utf8.encode(tag);
      if (tagU8Array.length <= 0xFF) {
        byteBuffer.writeI8(tagU8Array.length);
        byteBuffer.writeBytes(tagU8Array);
      }
    });
    content = byteBuffer.toUint8Array();
  }

  static TaggingMetadata fromEntry(MetadataEntry entry) {
    var buffer = RSocketByteBuffer.fromUint8List(entry.content!);
    var tags = <String>[];
    while (buffer.isReadable()) {
      var tagLength = buffer.readI8();
      if (tagLength != null) {
        var u8Array = buffer.readBytes(tagLength);
        if (u8Array.isNotEmpty) {
          tags[tags.length] = utf8.decode(u8Array);
        }
      }
    }
    return TaggingMetadata(entry.mimeType, tags);
  }
}

class RoutingMetadata extends TaggingMetadata {
  String? routingKey;
  List<String>? extraTags;

  RoutingMetadata(String routingKey, List<String> extraTags)
      : super('message/x.rsocket.routing.v0', [routingKey, ...extraTags]) {
    this.routingKey = routingKey;
    this.extraTags = extraTags;
  }

  static RoutingMetadata fromEntry(MetadataEntry entry) {
    var taggingMetadata = TaggingMetadata.fromEntry(entry);
    var tags = taggingMetadata.tags;
    if (tags.isEmpty) {
      return RoutingMetadata('', []);
    } else if (tags.length == 1) {
      return RoutingMetadata(tags[0], []);
    } else {
      return RoutingMetadata(tags[0], tags.sublist(1, tags.length));
    }
  }
}

class AuthMetadata extends MetadataEntry {
  late Uint8List authData;
  late int authTypeId;

  AuthMetadata(int authTypeId, Uint8List authData) {
    mimeType = 'message/x.rsocket.authentication.v0';
    this.authTypeId = authTypeId;
    this.authData = authData;
    content = Uint8List(this.authData.length + 1);
    content![0] = 0x80 | this.authTypeId;
    content!.setRange(1, content!.length, authData);
  }

  static AuthMetadata jwt(String jwtToken) {
    return AuthMetadata(0x01, utf8.encode(jwtToken) as Uint8List);
  }

  static AuthMetadata simple(String username, String password) {
    var userNameU8Array = utf8.encode(username);
    var passwordU8Array = utf8.encode(password);
    var buffer = RSocketByteBuffer();
    buffer.writeI24(userNameU8Array.length);
    buffer.writeBytes(userNameU8Array);
    buffer.writeBytes(passwordU8Array);
    return AuthMetadata(0x00, buffer.toUint8Array());
  }
}

class MessageMimeTypeMetadata extends MetadataEntry {
  String? dataMimeType;

  MessageMimeTypeMetadata(String dataMimeType) {
    mimeType = 'message/x.rsocket.mime-type.v0';
    this.dataMimeType = dataMimeType;
    if (WellKnownMimeType.isWellKnownType(dataMimeType)) {
      content = Uint8List(1);
      content![0] = 0x80 | WellKnownMimeType.getMimeTypeId(this.dataMimeType)!;
    } else {
      var dataMimeTypeU8Array = utf8.encode(this.dataMimeType!);
      content = Uint8List(1 + dataMimeTypeU8Array.length);
      content![0] = dataMimeTypeU8Array.length;
      content!.setRange(1, content!.length, dataMimeTypeU8Array);
    }
  }
}

class MessageAcceptMimeTypesMetadata extends MetadataEntry {
  List<String>? acceptMimeTypes;

  MessageAcceptMimeTypesMetadata(List<String> acceptMimeTypes) {
    mimeType = 'message/x.rsocket.accept-mime-types.v0';
    this.acceptMimeTypes = acceptMimeTypes;
    var buffer = RSocketByteBuffer();
    acceptMimeTypes.forEach((acceptMimeType) {
      if (WellKnownMimeType.isWellKnownType(acceptMimeType)) {
        buffer.writeI8(0x80 | WellKnownMimeType.getMimeTypeId(acceptMimeType)!);
      } else {
        var acceptMimeTypeU8Array = utf8.encode(acceptMimeType);
        buffer.writeI8(acceptMimeTypeU8Array.length);
        buffer.writeBytes(acceptMimeTypeU8Array);
      }
    });
    content = buffer.toUint8Array();
  }
}
