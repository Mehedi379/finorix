class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });

  // Convert to Map for saving in shared_preferences (as JSON)
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category,
      };

  // Convert back from Map
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        title: json['title'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        category: json['category'],
      );
}
