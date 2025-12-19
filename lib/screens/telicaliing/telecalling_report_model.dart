class TelecallingDailyReport {
  final DateTime date;
  final int totalCalls;
  final int ringing;
  final int notConnected;
  final int invalidNumber;
  final int notRequired;
  final int notInterested;
  final int whatsappPdfSent;

  TelecallingDailyReport({
    required this.date,
    required this.totalCalls,
    required this.ringing,
    required this.notConnected,
    required this.invalidNumber,
    required this.notRequired,
    required this.notInterested,
    required this.whatsappPdfSent,
  });

  double get successPercent {
    if (totalCalls <= 0) return 0;
    final unsuccessful =
        ringing + notConnected + invalidNumber + notRequired + notInterested;
    final successful = totalCalls - unsuccessful;
    if (successful <= 0) return 0;
    return (successful / totalCalls) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalCalls': totalCalls,
      'ringing': ringing,
      'notConnected': notConnected,
      'invalidNumber': invalidNumber,
      'notRequired': notRequired,
      'notInterested': notInterested,
      'whatsappPdfSent': whatsappPdfSent,
    };
  }

  factory TelecallingDailyReport.fromJson(Map<String, dynamic> json) {
    return TelecallingDailyReport(
      date: DateTime.parse(json['date'] as String),
      totalCalls: (json['totalCalls'] as num?)?.toInt() ?? 0,
      ringing: (json['ringing'] as num?)?.toInt() ?? 0,
      notConnected: (json['notConnected'] as num?)?.toInt() ?? 0,
      invalidNumber: (json['invalidNumber'] as num?)?.toInt() ?? 0,
      notRequired: (json['notRequired'] as num?)?.toInt() ?? 0,
      notInterested: (json['notInterested'] as num?)?.toInt() ?? 0,
      whatsappPdfSent: (json['whatsappPdfSent'] as num?)?.toInt() ?? 0,
    );
  }
}
