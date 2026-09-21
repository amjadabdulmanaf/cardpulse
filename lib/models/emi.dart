enum EmiType { self, others }

class EmiScheduleItem {
  final int installmentNumber; // 1, 2, 3...
  final String monthLabel; // e.g. "Oct-26"
  final int year; // e.g. 2026
  final int month; // 1..12
  double amount; // e.g. 1959.0
  bool isPaid;

  EmiScheduleItem({
    required this.installmentNumber,
    required this.monthLabel,
    required this.year,
    required this.month,
    required this.amount,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() => {
        'installmentNumber': installmentNumber,
        'monthLabel': monthLabel,
        'year': year,
        'month': month,
        'amount': amount,
        'isPaid': isPaid,
      };

  factory EmiScheduleItem.fromJson(Map<String, dynamic> json) =>
      EmiScheduleItem(
        installmentNumber: json['installmentNumber'] as int,
        monthLabel: json['monthLabel'] as String,
        year: json['year'] as int,
        month: json['month'] as int,
        amount: (json['amount'] as num).toDouble(),
        isPaid: json['isPaid'] as bool? ?? false,
      );
}

class EmiItem {
  final String id;
  final String cardId;
  final String title; // e.g. "iPhone 15 Pro"
  final double totalAmount; // Total transaction cost
  final EmiType type; // self or others
  final String? beneficiaryName; // Name if for others
  final List<EmiScheduleItem> schedule; // Month-by-month table
  final DateTime createdAt;

  EmiItem({
    required this.id,
    required this.cardId,
    required this.title,
    required this.totalAmount,
    required this.type,
    this.beneficiaryName,
    required this.schedule,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardId': cardId,
        'title': title,
        'totalAmount': totalAmount,
        'type': type.name,
        'beneficiaryName': beneficiaryName,
        'schedule': schedule.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory EmiItem.fromJson(Map<String, dynamic> json) => EmiItem(
        id: json['id'] as String,
        cardId: json['cardId'] as String,
        title: json['title'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        type: json['type'] == 'others' ? EmiType.others : EmiType.self,
        beneficiaryName: json['beneficiaryName'] as String?,
        schedule: (json['schedule'] as List)
            .map((e) => EmiScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  /// Helper to get amount due for a given cycle or month
  double getAmountForDate(DateTime date) {
    for (var item in schedule) {
      if (item.year == date.year && item.month == date.month) {
        return item.amount;
      }
    }
    return 0.0;
  }
}
