import 'dart:convert';
import 'dart:typed_data';
import 'package:rsocket/metadata/composite_metadata.dart';

class Payload {
  Uint8List? metadata;
  Uint8List? data;

  Payload();

  Payload.from(this.metadata, this.data);

  Payload.fromText(String metadata, String data)
      : metadata = Uint8List.fromList(utf8.encode(metadata)),
        data = Uint8List.fromList(utf8.encode(data));
   
  Payload.routeAndData(String route, String data){
    var compositeMetadata = CompositeMetadata.fromEntries([
      RoutingMetadata(route, List.empty())
    ]);
    this.metadata = compositeMetadata.toUint8Array();
    this.data = Uint8List.fromList(utf8.encode(data));
  }

  String? getMetadataUtf8() {
    if (metadata != null) {
      return utf8.decode(metadata!);
    }
    return null;
  }

  String? getDataUtf8() {
    if (data != null) {
      return utf8.decode(data!);
    }
    return null;
  }

  Map toJson() => {'metadata': metadata, 'data': data};

  factory Payload.fromJson(dynamic json) {
    var payload = Payload();
    if (json['metadata'] != null) {
      payload.metadata = Uint8List.fromList(json['metadata'].cast<int>());
    }
    if (json['data'] != null) {
      payload.metadata = Uint8List.fromList(json['data'].cast<int>());
    }
    return payload;
  }
}

class ConnectionSetupPayload extends Payload {
  String metadataMimeType = 'message/x.rsocket.composite-metadata.v0';
  String dataMimeType = 'application/json';
  int keepAliveInterval = 20;
  int keepAliveMaxLifetime = 90;
  int flags = 0;

  @override
  Map toJson() => {
        'metadataMimeType': metadataMimeType,
        'dataMimeType': dataMimeType,
        'keepAliveInterval': keepAliveInterval,
        'keepAliveMaxLifetime': keepAliveMaxLifetime,
        'flags': flags,
        'metadata': metadata,
        'data': data
      };
}
