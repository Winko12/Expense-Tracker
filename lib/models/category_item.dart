import 'package:hive/hive.dart';

part 'category_item.g.dart';

@HiveType(typeId: 1)
class CategoryItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isExpense;

  CategoryItem({required this.id, required this.name, required this.isExpense});
}
