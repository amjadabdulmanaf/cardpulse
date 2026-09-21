class CreditCard {
  final String id;
  final String cardName; // e.g. "Regalia Gold", "SimplyCLICK"
  final String bank; // e.g. "HDFC Bank", "SBI Card", "ICICI Bank"
  final String last4; // e.g. "4321"
  final double monthlyLimit; // e.g. 75000.0
  final int billGenerationDay; // 1..31 day of month
  final int colorIndex; // Theme gradient index

  CreditCard({
    required this.id,
    required this.cardName,
    required this.bank,
    required this.last4,
    required this.monthlyLimit,
    required this.billGenerationDay,
    this.colorIndex = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardName': cardName,
        'bank': bank,
        'last4': last4,
        'monthlyLimit': monthlyLimit,
        'billGenerationDay': billGenerationDay,
        'colorIndex': colorIndex,
      };

  factory CreditCard.fromJson(Map<String, dynamic> json) => CreditCard(
        id: json['id'] as String,
        cardName: json['cardName'] as String,
        bank: json['bank'] as String,
        last4: json['last4'] as String,
        monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
        billGenerationDay: json['billGenerationDay'] as int,
        colorIndex: (json['colorIndex'] as int?) ?? 0,
      );

  CreditCard copyWith({
    String? id,
    String? cardName,
    String? bank,
    String? last4,
    double? monthlyLimit,
    int? billGenerationDay,
    int? colorIndex,
  }) {
    return CreditCard(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      bank: bank ?? this.bank,
      last4: last4 ?? this.last4,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      billGenerationDay: billGenerationDay ?? this.billGenerationDay,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }
}
