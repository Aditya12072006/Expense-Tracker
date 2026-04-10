import 'package:hive/hive.dart';

enum TransactionType { income, expense }

class ExpenseTransaction {
  const ExpenseTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  static const int typeIdValue = 1;

  @override
  final int typeId = typeIdValue;

  @override
  TransactionType read(BinaryReader reader) {
    return TransactionType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    writer.writeInt(obj.index);
  }
}

class ExpenseTransactionAdapter extends TypeAdapter<ExpenseTransaction> {
  static const int typeIdValue = 2;

  @override
  final int typeId = typeIdValue;

  @override
  ExpenseTransaction read(BinaryReader reader) {
    return ExpenseTransaction(
      id: reader.readString(),
      title: reader.readString(),
      amount: reader.readDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      category: reader.readString(),
      type: TransactionType.values[reader.readInt()],
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseTransaction obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeDouble(obj.amount);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeString(obj.category);
    writer.writeInt(obj.type.index);
  }
}