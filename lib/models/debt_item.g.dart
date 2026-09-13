// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtItemAdapter extends TypeAdapter<DebtItem> {
  @override
  final int typeId = 2;

  @override
  DebtItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtItem(
      id: fields[0] as String,
      personName: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      isOwedToMe: fields[4] as bool,
      isSettled: fields[5] as bool,
      paymentMethod: fields[6] == null ? 'Cash' : fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DebtItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.isOwedToMe)
      ..writeByte(5)
      ..write(obj.isSettled)
      ..writeByte(6)
      ..write(obj.paymentMethod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
