class TransactionItem {
  final String id;
  final String cardId;
  final String title; // Merchant name or payment detail
  final double amount;
  final DateTime date;
  final String category; // "Shopping", "Dining", "Bills", "Fuel", "EMI", "Other"
  final bool isEmi;
  final String? emiId; // Linked EMI ID if this is an EMI installment
  final String? rawSms; // Original SMS text if auto-fetched
  final bool isOthersSpend; // True if spend was done for someone else
  final String? personName; // e.g. "Rahul", "Mom"
  final String? purpose; // e.g. "Dinner", "Gift"

  TransactionItem({
    required this.id,
    required this.cardId,
    required this.title,
    required this.amount,
    required this.date,
    this.category = 'General',
    this.isEmi = false,
    this.emiId,
    this.rawSms,
    this.isOthersSpend = false,
    this.personName,
    this.purpose,
  });

  TransactionItem copyWith({
    String? id,
    String? cardId,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    bool? isEmi,
    String? emiId,
    String? rawSms,
    bool? isOthersSpend,
    String? personName,
    String? purpose,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      isEmi: isEmi ?? this.isEmi,
      emiId: emiId ?? this.emiId,
      rawSms: rawSms ?? this.rawSms,
      isOthersSpend: isOthersSpend ?? this.isOthersSpend,
      personName: personName ?? this.personName,
      purpose: purpose ?? this.purpose,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardId': cardId,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category,
        'isEmi': isEmi,
        'emiId': emiId,
        'rawSms': rawSms,
        'isOthersSpend': isOthersSpend,
        'personName': personName,
        'purpose': purpose,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        id: json['id'] as String,
        cardId: json['cardId'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        category: (json['category'] as String?) ?? 'General',
        isEmi: (json['isEmi'] as bool?) ?? false,
        emiId: json['emiId'] as String?,
        rawSms: json['rawSms'] as String?,
        isOthersSpend: (json['isOthersSpend'] as bool?) ?? false,
        personName: json['personName'] as String?,
        purpose: json['purpose'] as String?,
      );
}
