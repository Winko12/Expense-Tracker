import 'package:hive/hive.dart';

part 'debt_item.g.dart';

@HiveType(typeId: 2) // Transaction is 0, Category is 1, Debt is 2!
class DebtItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String personName;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  bool isOwedToMe; // true = I lent them money. false = I borrowed from them.

  @HiveField(5)
  bool isSettled; // true = Debt is paid off!

  @HiveField(6, defaultValue: 'Cash')
  String paymentMethod;

  DebtItem({
    required this.id,
    required this.personName,
    required this.amount,
    required this.date,
    required this.isOwedToMe,
    this.isSettled = false,
    required this.paymentMethod,
  });
}
