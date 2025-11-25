import 'dart:convert';
import 'dart:typed_data';

import 'constants.dart';
import 'utils/type_sizes.dart';
import 'utils/crc.dart';

class ProtocolVersion {
  ProtocolVersion(this.major, this.minor);

  final int major;
  final int minor;

  Uint8List toBytes() {
    final bd = ByteData(1);
    bd.setUint8(0, (major << 4) | minor);
    return bd.buffer.asUint8List();
  }

  @override
  String toString() {
    return '$major.$minor';
  }

  static ProtocolVersion fromBytes(Uint8List bytes) {
    final value = bytes[0];
    final major = value >> 4;
    final minor = value & 0x0f;

    return ProtocolVersion(major, minor);
  }
}

class ProfileVersion {
  ProfileVersion(this.major, this.minor);

  final int major;
  final int minor;

  static const majorScale = 100;

  Uint8List toBytes() {
    final bd = ByteData(2);
    bd.setUint16(0, versionCode, Endian.little);
    return bd.buffer.asUint8List();
  }

  int get versionCode {
    return major * majorScale + minor;
  }

  @override
  String toString() {
    return '$major.$minor';
  }

  static ProfileVersion fromBytes(Uint8List bytes) {
    final byteData = ByteData.sublistView(bytes);

    final value = byteData.getUint16(0, Endian.little);

    final major = value ~/ majorScale;
    final minor = value % majorScale;

    return ProfileVersion(major, minor);
  }
}

class FitFileHeader {
  FitFileHeader(
      {required this.recordsSize,
      ProtocolVersion? protocolVersion,
      ProfileVersion? profileVersion,
      int? crc,
      bool genCrc = false})
      : protocolVersion = protocolVersion ?? Fit.protocolVersion,
        profileVersion = profileVersion ?? Fit.profileVersion,
        crc = genCrc
            ? generateCrc(protocolVersion ?? Fit.protocolVersion,
                profileVersion ?? Fit.profileVersion, recordsSize)
            : crc {
    if (recordsSize < 0 || recordsSize > maxUint32) {
      throw ArgumentError.value(
          recordsSize, 'recordsLength', 'not in range [0,$maxUint32]');
    }
    if (crc != null && (crc < 0 || crc > maxUint16)) {
      throw ArgumentError.value(crc, 'crc', 'not in range [0,$maxUint16]');
    }
  }

  final ProtocolVersion protocolVersion;
  final ProfileVersion profileVersion;
  final int recordsSize;

  /// By including the CRC in the header you effectively reset the CRC for the
  /// file, (when you CRC-16 a value with itself the CRC returned is 0)
  final int? crc; //crc16 of header bytes 0-11

  int get size {
    if (crc != null) {
      return 14;
    } else {
      return 12;
    }
  }

  Uint8List toBytes() {
    final builder = BytesBuilder();

    builder.addByte(size);
    builder.add(protocolVersion.toBytes());
    builder.add(profileVersion.toBytes());

    final byteData1 = ByteData(4);
    byteData1.setUint32(0, recordsSize, Endian.little);
    builder.add(byteData1.buffer.asUint8List());

    builder.add(utf8.encode('.FIT'));

    if (crc != null) {
      final byteData = ByteData(2);
      byteData.setUint16(0, crc!, Endian.little);
      builder.add(byteData.buffer.asUint8List());
    }

    return builder.toBytes();
  }

  static int generateCrc(ProtocolVersion protocolVersion,
      ProfileVersion profileVersion, int recordsSize) {
    final builder = BytesBuilder();
    builder.addByte(14);
    builder.add(protocolVersion.toBytes());
    builder.add(profileVersion.toBytes());
    final byteData1 = ByteData(4);
    byteData1.setUint32(0, recordsSize, Endian.little);
    builder.add(byteData1.buffer.asUint8List());
    builder.add(utf8.encode('.FIT'));
    return crc16(builder.toBytes());
  }

  static FitFileHeader fromBytes(Uint8List bytes) {
    final byteData = ByteData.sublistView(bytes);
    var byteOffset = 0;
    final size = byteData.getUint8(byteOffset);
    if (size != bytes.length) {
      throw FormatException(
          'Size $size does not match bytes length: ${bytes.length}');
    }
    byteOffset += 1;

    final protocolVersion = ProtocolVersion.fromBytes(
        Uint8List.sublistView(bytes, byteOffset, byteOffset + 1));
    byteOffset += 1;

    final profileVersion = ProfileVersion.fromBytes(
        Uint8List.sublistView(bytes, byteOffset, byteOffset + 2));
    byteOffset += 2;

    // records length
    final recordsLength = byteData.getUint32(byteOffset, Endian.little);
    byteOffset += 4;

    // .FIT
    final tagValue =
        utf8.decode(Uint8List.sublistView(bytes, byteOffset, byteOffset + 4));
    byteOffset += 4;
    if (tagValue != '.FIT') {
      throw Exception('".FIT" not in header.');
    }

    int? crc;
    if (bytes.length == 14) {
      crc = byteData.getUint16(byteOffset, Endian.little);
    }

    return FitFileHeader(
        protocolVersion: protocolVersion,
        profileVersion: profileVersion,
        recordsSize: recordsLength,
        crc: crc);
  }
}
