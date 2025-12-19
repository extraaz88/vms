class TelecallingRecord {
  final String leadName;
  final String status; // e.g. Demo, Follow up, Closed
  final String businessType;
  final String productType; // SPOS, BPOS, EPOS
  final String location;
  final String phoneNumber;
  final String amount;
  final String remark;
  final String nextReminderDate; // simple string like "Dec 14, 2025"
  final String time; // e.g. "02:00 PM"

  TelecallingRecord({
    required this.leadName,
    required this.status,
    required this.businessType,
    required this.productType,
    required this.location,
    required this.phoneNumber,
    required this.amount,
    required this.remark,
    required this.nextReminderDate,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'leadName': leadName,
      'status': status,
      'businessType': businessType,
      'productType': productType,
      'location': location,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'remark': remark,
      'nextReminderDate': nextReminderDate,
      'time': time,
    };
  }

  factory TelecallingRecord.fromJson(Map<String, dynamic> json) {
    return TelecallingRecord(
      leadName: json['leadName'] as String? ?? '',
      status: json['status'] as String? ?? 'Demo',
      businessType: json['businessType'] as String? ?? '',
      productType: json['productType'] as String? ?? '',
      location: json['location'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      nextReminderDate: json['nextReminderDate'] as String? ?? '',
      time: json['time'] as String? ?? '',
    );
  }
}
