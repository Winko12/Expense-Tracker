import 'package:hive/hive.dart';

part 'wallet_item.g.dart';

@HiveType(typeId: 3) // Transaction=0, Category=1, Debt=2, Wallet=3
class WalletItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  WalletItem({required this.id, required this.name});
}
