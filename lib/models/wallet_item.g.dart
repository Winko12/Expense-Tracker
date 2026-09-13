// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletItemAdapter extends TypeAdapter<WalletItem> {
  @override
  final int typeId = 3;

  @override
  WalletItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletItem(
      id: fields[0] as String,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WalletItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
