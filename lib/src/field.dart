import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'base_type.dart';
import 'field_component.dart';
import 'field_definition.dart';
import 'sub_field.dart';
import 'utils/logger.dart';

class Field {
  Field({
    this.name = '',
    this.id = 0,
    this.type = BaseType.ENUM,
    this.offset,
    this.scale,
    this.units = '',
    this.isAccumulated = false,
    this.isExpandedField = false,
    List<SubField>? subFields,
    List<FieldComponent>? components,
    this.size = 0,
    this.growable = false,
    this.mainTypeName = '',
  })  : subFields = subFields ?? <SubField>[],
        components = components ?? <FieldComponent>[],
        encodedValues = List<dynamic>.filled(
            getLengthFromSize(type, size), null,
            growable: growable || type == BaseType.STRING);

  Field.fromField(final Field other)
      : id = other.id,
        name = other.name,
        type = other.type,
        offset = other.offset,
        scale = other.scale,
        units = other.units,
        isAccumulated = other.isAccumulated,
        isExpandedField = other.isExpandedField,
        size = other.size,
        growable = other.growable,
        encodedValues = [...other.encodedValues],
        //shallow copy
        subFields = [...other.subFields],
        //shallow copy
        //shallow copy
        components = [...other.components],
        //shallow copy
        mainTypeName = other.mainTypeName;

  Field.fromFieldDefinition(final FieldDefinition definition)
      : id = definition.id,
        name = 'field',
        type = definition.type,
        offset = null,
        scale = null,
        units = '',
        isAccumulated = false,
        isExpandedField = false,
        size = definition.size,
        growable = false,
        encodedValues = List<dynamic>.filled(
            getLengthFromSize(definition.type, definition.size), null,
            growable: definition.type == BaseType.STRING),
        subFields = [],
        components = [],
        mainTypeName = '';

  final int id;
  final String name;
  final BaseType type;
  final double? offset;
  final double? scale;
  final String units;
  final bool isAccumulated;
  final bool isExpandedField;
  final String mainTypeName;

  final List<FieldComponent> components;
  final List<SubField> subFields;

  int size; // number of total bytes for field
  final bool growable; // if true allow the field to grow in size.

  // encoded field values.
  List<dynamic> encodedValues;

  String getName(
      {SubField? subField, String? subFieldName, int? subFieldIndex}) {
    SubField? sb;

    if (subField != null) {
      sb = subField;
    } else if (subFieldName != null) {
      sb = getSubField(name: subFieldName);
    } else if (subFieldIndex != null) {
      sb = getSubField(index: subFieldIndex);
    }

    if (sb == null) {
      return name;
    } else {
      return sb.name;
    }
  }

  String getUnits(
      {SubField? subField, String? subFieldName, int? subFieldIndex}) {
    SubField? sb;

    if (subField != null) {
      sb = subField;
    } else if (subFieldName != null) {
      sb = getSubField(name: subFieldName);
    } else if (subFieldIndex != null) {
      sb = getSubField(index: subFieldIndex);
    }

    if (sb == null) {
      return units;
    } else {
      return sb.units;
    }
  }

  BaseType getType(
      {SubField? subField, String? subFieldName, int? subFieldIndex}) {
    SubField? sb;

    if (subField != null) {
      sb = subField;
    } else if (subFieldName != null) {
      sb = getSubField(name: subFieldName);
    } else if (subFieldIndex != null) {
      sb = getSubField(index: subFieldIndex);
    }

    if (sb == null) {
      return type;
    } else {
      return sb.type;
    }
  }

  double? getOffset(
      {SubField? subField, String? subFieldName, int? subFieldIndex}) {
    SubField? sb;

    if (subField != null) {
      sb = subField;
    } else if (subFieldName != null) {
      sb = getSubField(name: subFieldName);
    } else if (subFieldIndex != null) {
      sb = getSubField(index: subFieldIndex);
    }

    if (sb == null) {
      return offset;
    } else {
      return sb.offset;
    }
  }

  double? getScale(
      {SubField? subField, String? subFieldName, int? subFieldIndex}) {
    SubField? sb;

    if (subField != null) {
      sb = subField;
    } else if (subFieldName != null) {
      sb = getSubField(name: subFieldName);
    } else if (subFieldIndex != null) {
      sb = getSubField(index: subFieldIndex);
    }

    if (sb == null) {
      return scale;
    } else {
      return sb.scale;
    }
  }

  void clear() {
    size = 0;
    encodedValues = [];
  }

  bool isValid() {
    return size != 0;
  }

  bool isNotValid() {
    return !isValid();
  }

  dynamic getValue({int index = 0, SubField? subField}) {
    if (index < 0 || index >= encodedValues.length) {
      return null;
    }

    final encodedValue = encodedValues[index];

    if (encodedValue == type.invalidRawValue) {
      return null;
    }

    return decodeValue(encodedValue, subField);
  }

  // Return values as a list
  dynamic getValues() {
    return encodedValues.map((e) => decodeValue(e, null)).toList();
  }

  dynamic decodeValue(dynamic encodedValue, SubField? subField) {
    if (encodedValue is String || encodedValue == null) {
      return encodedValue;
    }

    num value;

    final scale = getScale(subField: subField);
    final offset = getOffset(subField: subField);
    if ((scale == null || scale == 1.0) && (offset == null || offset == 0.0)) {
      // no scaling
      value = encodedValue;
    } else {
      value = unScaleOffsetValue(encodedValue, scale ?? 1.0, offset ?? 0.0);
      if (mainTypeName == 'date_time') {
        value = value.round();
      }
    }
    return value;
  }

  int get length {
    return encodedValues.length;
  }

  void setValue(int index, dynamic value, SubField? subField) {
    final encodedValue = encodeValue(value, subField);
    setEncodedValue(index, encodedValue);
  }

  void setValues(List<dynamic> values) {
    int index = 0;
    for (var value in values) {
      final encodedValue = encodeValue(value, null);
      setEncodedValue(index, encodedValue);
      index++;
    }
  }

  void setEncodedValue(int index, dynamic encodedValue) {
    if (index < 0) {
      return;
    }
    var sizeChanged = false;
    while (index >= length) {
      if (type != BaseType.STRING && !growable) {
        throw Exception('Field is not growable.');
      }
      encodedValues.add(null);
      sizeChanged = true;
    }

    encodedValues[index] = encodedValue;

    if (sizeChanged || type == BaseType.STRING) {
      final newSize = calculateSize();
      if (newSize > size) {
        if (!growable) {
          throw Exception(
              'Size exceeds fixed field size of $size bytes. Consider making field growable.');
        }
        size = newSize;
      }
    }
  }

  dynamic encodeValue(dynamic value, SubField? subField) {
    if (value is String) {
      return value;
    }

    int encodedValue;

    if (value == null) {
      encodedValue = type.invalidRawValue;
    } else {
      final scale = getScale(subField: subField);
      final offset = getOffset(subField: subField);
      final type = getType(subField: subField);

      if ((scale == null || scale == 1.0) &&
          (offset == null || offset == 0.0)) {
        // no scaling
        return value;
      } else {
        final scale_ = scale ?? 1.0;
        final offset_ = offset ?? 0.0;

        if (type.isFloat()) {
          // if it's a float type, don't do any int conversion but apply scaling and offset
          encodedValue = (value + offset_) * scale;
        } else {
          encodedValue = scaleOffsetValue(value.toDouble(), scale_, offset_);
        }
      }
    }
    return encodedValue;
  }

  int scaleOffsetValue(double value, double scale, double offset) {
    final encodedValue = ((value + offset) * scale).round();

    return encodedValue;
  }

  double unScaleOffsetValue(int encodedValue, double scale, double offset) {
    final value = encodedValue / scale - offset;

    return value;
  }

  dynamic getEncodedValueFromBytes(Uint8List bytes,
      {int offset = 0, Endian endian = Endian.little}) {
    final byteData = ByteData.sublistView(bytes, offset, type.size);

    final dynamic value;
    switch (type) {
      case BaseType.ENUM:
        value = byteData.getUint8(0);
        break;

      case BaseType.UINT8:
      case BaseType.UINT8Z:
      case BaseType.BYTE:
        value = byteData.getUint8(0);
        break;

      case BaseType.SINT8:
        value = byteData.getInt8(0);
        break;

      case BaseType.SINT16:
        value = byteData.getInt16(0, endian);
        break;

      case BaseType.UINT16:
      case BaseType.UINT16Z:
        value = byteData.getUint16(0, endian);
        break;

      case BaseType.SINT32:
        value = byteData.getInt32(0, endian);
        break;

      case BaseType.UINT32:
      case BaseType.UINT32Z:
        value = byteData.getUint32(0, endian);
        break;

      case BaseType.SINT64:
        Int64 int64;
        if (endian == Endian.little) {
          int64 = Int64.fromBytes(byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        } else {
          int64 = Int64.fromBytesBigEndian(byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        }

        value = BigInt.parse(int64.toString());
        break;

      case BaseType.FLOAT32:
        value = byteData.getFloat32(0, endian);
        break;

      case BaseType.FLOAT64:
        value = byteData.getFloat64(0, endian);
        break;

      case BaseType.STRING:
        value = utf8.decode(bytes.sublist(0, bytes.length - 1),
            allowMalformed: true);
        break;

      case BaseType.UINT64:
      case BaseType.UINT64Z:
        Int64 int64;
        if (endian == Endian.little) {
          int64 = Int64.fromBytes(byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        } else {
          int64 = Int64.fromBytesBigEndian(byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        }

        value = BigInt.parse(int64.toString()).toUnsigned(64);
        break;
    }

    return value;
  }

  SubField? getSubField({String? name, int? index}) {
    if (index != null && index >= 0 && index < subFields.length) {
      return subFields[index];
    }

    if (name != null) {
      for (var subField in subFields) {
        if (subField.name == name) {
          return subField;
        }
      }
    }

    return null;
  }

  Uint8List encodedValueToBytes(dynamic encodedValue,
      {Endian endian = Endian.little}) {
    if (encodedValue == null) {
      throw ArgumentError.value(encodedValue, 'encodedValue');
    }

    if (type == BaseType.STRING) {
      final encodedBytes = utf8.encode(encodedValue);
      final bb = BytesBuilder()
        ..add(encodedBytes)
        ..addByte(0);
      return bb.toBytes();
    }

    final byteData = ByteData(type.size);

    switch (type) {
      case BaseType.ENUM:
        byteData.setUint8(0, encodedValue);
        break;

      case BaseType.UINT8:
      case BaseType.UINT8Z:
      case BaseType.BYTE:
        byteData.setUint8(0, encodedValue);
        break;

      case BaseType.SINT8:
        byteData.setInt8(0, encodedValue);
        break;

      case BaseType.SINT16:
        byteData.setInt16(0, encodedValue, endian);
        break;

      case BaseType.UINT16:
      case BaseType.UINT16Z:
        byteData.setUint16(0, encodedValue, endian);
        break;

      case BaseType.SINT32:
        byteData.setInt32(0, encodedValue, endian);
        break;

      case BaseType.UINT32:
      case BaseType.UINT32Z:
        byteData.setUint32(0, encodedValue, endian);
        break;

      case BaseType.FLOAT32:
        if (encodedValue == null) {
          byteData.setUint32(0, type.invalidRawValue, endian);
        } else {
          byteData.setFloat32(0, encodedValue, endian);
        }
        break;

      case BaseType.FLOAT64:
        if (encodedValue == null) {
          byteData.setUint64(0, type.invalidRawValue, endian);
        } else {
          byteData.setFloat64(0, encodedValue, endian);
        }
        break;

      case BaseType.STRING:
        break;

      case BaseType.UINT64:
      case BaseType.UINT64Z:
      case BaseType.SINT64:
        encodedValue as BigInt;
        final stringValue = encodedValue.toRadixString(16);
        final int64 = Int64.parseRadix(stringValue, 16);
        var bytes = int64.toBytes();
        if (endian == Endian.big) {
          bytes = bytes.reversed.toList();
        }
        return Uint8List.fromList(bytes);
    }

    return byteData.buffer.asUint8List();
  }

  void readAllFromBytes(Uint8List bytes,
      {SubField? subField, Endian endian = Endian.little}) {
    // final type = getType(subField: subField);

    if (type == BaseType.STRING) {
      readStringsFromBytes(bytes);
    } else {
      var start = 0;
      for (var index = 0; index < encodedValues.length; index++) {
        final valueBytes =
            Uint8List.sublistView(bytes, start, start + type.size);
        readFromBytes(valueBytes, index, endian: endian);
        start += type.size;
      }
    }
  }

  void readFromBytes(Uint8List bytes, int index,
      {Endian endian = Endian.little}) {
    if (type == BaseType.STRING) {
      throw Exception('Type cannot be string');
    }

    final encodedValue = getEncodedValueFromBytes(bytes, endian: endian);
    setEncodedValue(index, encodedValue);
  }

  void readStringsFromBytes(Uint8List bytes) {
    // The number of strings is dynamic and is determined by the number of null
    // terminations in the string container

    final stringContainer = utf8.decode(bytes, allowMalformed: true);
    final strings = stringContainer.split('\u0000');
    strings.removeLast();
    encodedValues.clear();
    encodedValues.addAll(strings);
  }

  static int getLengthFromSize(BaseType type, int size) {
    if (type == BaseType.STRING) {
      return size == 0 ? 0 : 1;
    } else {
      final length = (size / type.size).floor();

      if (length * type.size != size) {
        logger.w('Size is not a multiple of type: size: $size, type: $type');
      }
      return length;
    }
  }

  int calculateSize() {
    if (type == BaseType.STRING) {
      var calcSize = 0;
      for (var value in encodedValues) {
        if (value != null) {
          final bytes = utf8.encode(value);
          calcSize += bytes.length + 1;
        }
      }
      return calcSize;
    } else {
      return length * type.size;
    }
  }

  Uint8List toBytes({Endian endian = Endian.little}) {
    final bb = BytesBuilder();
    for (var value in encodedValues) {
      final bytes = encodedValueToBytes(value, endian: endian);
      bb.add(bytes);
    }

    // sometimes subfields or strings can be less then the allocated field size,
    // so we pad the buffer with 0's.
    if (bb.length < size) {
      bb.add(Uint8List(size - bb.length));
    }

    return Uint8List.sublistView(bb.toBytes(), 0, size);
  }

  SubField? getValidSubField(List<Field> fields) {
    if (subFields.isEmpty) {
      return null;
    }

    for (var subField in subFields) {
      if (subField.isValid(fields)) {
        return subField;
      }
    }

    return null;
  }

  List<dynamic> toRow({SubField? subField}) {
    final row = <dynamic>[];

    final values = <dynamic>[encodedValues.length];
    for (var i = 0; i < values.length; i++) {
      values[i] = getValue(index: i, subField: subField);
    }

    row.add(subField?.name ?? name);
    if (values.length == 1) {
      row.add(values[0]);
    } else {
      final valuesArray = '[${values.join(',')}]';
      row.add(valuesArray);
    }
    row.add(subField?.units.toString() ?? units);
    return row;
  }
}

// BigInt readBigIntFromUint8List(Uint8List bytes) {
//   BigInt read(int start, int end) {
//     if (end - start <= 4) {
//       var result = 0;
//       for (var i = end - 1; i >= start; i--) {
//         result = result * 256 + bytes[i];
//       }
//       return BigInt.from(result);
//     }
//     var mid = start + ((end - start) >> 1);
//     var result = read(start, mid) + read(mid, end) * (BigInt.one << ((mid - start) * 8));
//     return result;
//   }
//   return read(0, bytes.length);
// }
//
// Uint8List bigIntAsUint8List(BigInt number) {
//   // Not handling negative numbers. Decide how you want to do that.
//   var bytes = (number.bitLength + 7) >> 3;
//   var b256 = BigInt.from(256);
//   var result = Uint8List(bytes);
//   for (var i = 0; i < bytes; i++) {
//     result[i] = number.remainder(b256).toInt();
//     number = number >> 8;
//   }
//   return result;
// }
//
// /// Decode a BigInt from bytes in big-endian encoding.
// BigInt decodeBigInt(List<int> bytes) {
//   BigInt result = new BigInt.from(0);
//   for (int i = 0; i < bytes.length; i++) {
//     result += new BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
//   }
//   return result;
// }
//
// var _byteMask = new BigInt.from(0xff);
//
// /// Encode a BigInt into bytes using big-endian encoding.
// Uint8List encodeBigInt(BigInt number) {
//   // Not handling negative numbers. Decide how you want to do that.
//   int size = (number.bitLength + 7) >> 3;
//   var result = new Uint8List(size);
//   for (int i = 0; i < size; i++) {
//     result[size - i - 1] = (number & _byteMask).toInt();
//     number = number >> 8;
//   }
//   return result;
// }
