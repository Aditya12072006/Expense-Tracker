import 'package:flutter/material.dart';

class TransactionCategory {
  const TransactionCategory(this.name, this.icon);

  final String name;
  final IconData icon;
}

const List<TransactionCategory> kTransactionCategories = [
  TransactionCategory('Food', Icons.ramen_dining_rounded),
  TransactionCategory('Transport', Icons.directions_car_filled_rounded),
  TransactionCategory('Subscriptions', Icons.subscriptions_rounded),
  TransactionCategory('Shopping', Icons.shopping_bag_rounded),
  TransactionCategory('Bills', Icons.receipt_long_rounded),
  TransactionCategory('Entertainment', Icons.movie_filter_rounded),
  TransactionCategory('Health', Icons.favorite_rounded),
  TransactionCategory('Salary', Icons.payments_rounded),
  TransactionCategory('Freelance', Icons.laptop_mac_rounded),
  TransactionCategory('Savings', Icons.savings_rounded),
  TransactionCategory('Others', Icons.category_rounded),
];