class LeaveApplication {
  final String? id;
  final String userId;
  final String leaveType;
  final String description;
  final DateTime fromDate;
  final DateTime toDate;
  final String status; // pending, approved, rejected
  final DateTime? appliedDate;
  final String? remarks;

  const LeaveApplication({
    this.id,
    required this.userId,
    required this.leaveType,
    required this.description,
    required this.fromDate,
    required this.toDate,
    this.status = 'pending',
    this.appliedDate,
    this.remarks,
  });

  // Calculate number of days
  int get numberOfDays {
    return toDate.difference(fromDate).inDays + 1;
  }

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      leaveType: json['leave_type'] ?? '',
      description: json['description'] ?? '',
      fromDate: json['from_date'] != null
          ? DateTime.parse(json['from_date'])
          : DateTime.now(),
      toDate: json['to_date'] != null
          ? DateTime.parse(json['to_date'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      appliedDate: json['applied_date'] != null
          ? DateTime.parse(json['applied_date'])
          : null,
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'leave_type': leaveType,
      'description': description,
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
      'status': status,
      if (appliedDate != null) 'applied_date': appliedDate!.toIso8601String(),
      if (remarks != null) 'remarks': remarks,
    };
  }

  LeaveApplication copyWith({
    String? id,
    String? userId,
    String? leaveType,
    String? description,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    DateTime? appliedDate,
    String? remarks,
  }) {
    return LeaveApplication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      leaveType: leaveType ?? this.leaveType,
      description: description ?? this.description,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      remarks: remarks ?? this.remarks,
    );
  }
}

// Leave Types Constants
class LeaveTypes {
  static const String sick = 'Sick Leave';
  static const String casual = 'Casual Leave';
  static const String earned = 'Earned Leave';
  static const String maternity = 'Maternity Leave';
  static const String paternity = 'Paternity Leave';
  static const String unpaid = 'Unpaid Leave';
  static const String compensatory = 'Compensatory Leave';
  static const String emergency = 'Emergency Leave';
  static const String other = 'Other';

  static List<String> get allTypes => [
        sick,
        casual,
        earned,
        maternity,
        paternity,
        unpaid,
        compensatory,
        emergency,
        other,
      ];
}

