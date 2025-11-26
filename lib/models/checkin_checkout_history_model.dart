class CheckInCheckOutHistory {
  final int id;
  final int userId;
  final String userName;
  final double inLatitude;
  final double inLongitude;
  final double outLatitude;
  final double outLongitude;
  final double inAccuracy;
  final double inBatteryPercent;
  final double outAccuracy;
  final double outBatteryPercent;
  final String inNotes;
  final String outNotes;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CheckInCheckOutHistory({
    required this.id,
    required this.userId,
    required this.userName,
    required this.inLatitude,
    required this.inLongitude,
    required this.outLatitude,
    required this.outLongitude,
    required this.inAccuracy,
    required this.inBatteryPercent,
    required this.outAccuracy,
    required this.outBatteryPercent,
    required this.inNotes,
    required this.outNotes,
    required this.checkInTime,
    this.checkOutTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CheckInCheckOutHistory.fromJson(Map<String, dynamic> json) {
    return CheckInCheckOutHistory(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      inLatitude:
          double.tryParse(json['in_latitude']?.toString() ?? '0') ?? 0.0,
      inLongitude:
          double.tryParse(json['in_longitude']?.toString() ?? '0') ?? 0.0,
      outLatitude:
          double.tryParse(json['out_latitude']?.toString() ?? '0') ?? 0.0,
      outLongitude:
          double.tryParse(json['out_longitude']?.toString() ?? '0') ?? 0.0,
      inAccuracy:
          double.tryParse(json['in_accuracy']?.toString() ?? '0') ?? 0.0,
      inBatteryPercent:
          double.tryParse(json['in_battery_percent']?.toString() ?? '0') ?? 0.0,
      outAccuracy:
          double.tryParse(json['out_accuracy']?.toString() ?? '0') ?? 0.0,
      outBatteryPercent:
          double.tryParse(json['out_battery_percent']?.toString() ?? '0') ??
          0.0,
      inNotes: json['in_notes'] ?? '',
      outNotes: json['out_notes'] ?? '',
      checkInTime: DateTime.parse(
        json['check_in_time'] ?? DateTime.now().toIso8601String(),
      ),
      checkOutTime: json['check_out_time'] != null &&
              json['check_out_time'].toString().trim().isNotEmpty &&
              json['check_out_time'].toString().toLowerCase() != 'null'
          ? DateTime.parse(json['check_out_time'])
          : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'in_latitude': inLatitude,
      'in_longitude': inLongitude,
      'out_latitude': outLatitude,
      'out_longitude': outLongitude,
      'in_accuracy': inAccuracy,
      'in_battery_percent': inBatteryPercent,
      'out_accuracy': outAccuracy,
      'out_battery_percent': outBatteryPercent,
      'in_notes': inNotes,
      'out_notes': outNotes,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Calculate duration between check-in and check-out
  Duration get duration {
    if (checkOutTime == null) {
      return DateTime.now().difference(checkInTime);
    }
    return checkOutTime!.difference(checkInTime);
  }

  // Check if the session is completed
  bool get isCompleted => checkOutTime != null && checkOutTime!.isAfter(checkInTime);

  @override
  String toString() {
    return 'CheckInCheckOutHistory(id: $id, userName: $userName, checkInTime: $checkInTime, checkOutTime: $checkOutTime)';
  }
}

class UserCheckInCheckOutHistory {
  final int id;
  final String username;
  final String name;
  final String? title;
  final int planIsActive;
  final String email;
  final DateTime? emailVerifiedAt;
  final double storageLimit;
  final String? phone;
  final String? gender;
  final String type;
  final int isActive;
  final int isEnableLogin;
  final String? userRoles;
  final String lang;
  final String mode;
  final String? avatar;
  final int plan;
  final DateTime? planExpireDate;
  final String isTrialDone;
  final int requestedPlan;
  final DateTime? trialExpireDate;
  final int createdBy;
  final int activeStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int darkMode;
  final String? messengerColor;
  final int isDisable;
  final String typeName;
  final String userRolesName;
  final List<CheckInCheckOutHistory> userCheckInCheckOutDetails;

  const UserCheckInCheckOutHistory({
    required this.id,
    required this.username,
    required this.name,
    this.title,
    required this.planIsActive,
    required this.email,
    this.emailVerifiedAt,
    required this.storageLimit,
    this.phone,
    this.gender,
    required this.type,
    required this.isActive,
    required this.isEnableLogin,
    this.userRoles,
    required this.lang,
    required this.mode,
    this.avatar,
    required this.plan,
    this.planExpireDate,
    required this.isTrialDone,
    required this.requestedPlan,
    this.trialExpireDate,
    required this.createdBy,
    required this.activeStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.darkMode,
    this.messengerColor,
    required this.isDisable,
    required this.typeName,
    required this.userRolesName,
    required this.userCheckInCheckOutDetails,
  });

  factory UserCheckInCheckOutHistory.fromJson(Map<String, dynamic> json) {
    return UserCheckInCheckOutHistory(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      title: json['title'],
      planIsActive: json['plan_is_active'] ?? 0,
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      storageLimit:
          double.tryParse(json['storage_limit']?.toString() ?? '0') ?? 0.0,
      phone: json['phone'],
      gender: json['gender'],
      type: json['type'] ?? '',
      isActive: json['is_active'] ?? 0,
      isEnableLogin: json['is_enable_login'] ?? 0,
      userRoles: json['user_roles'],
      lang: json['lang'] ?? 'en',
      mode: json['mode'] ?? 'light',
      avatar: json['avatar'],
      plan: json['plan'] ?? 0,
      planExpireDate: json['plan_expire_date'] != null
          ? DateTime.parse(json['plan_expire_date'])
          : null,
      isTrialDone: json['is_trial_done']?.toString() ?? '0',
      requestedPlan: json['requested_plan'] ?? 0,
      trialExpireDate: json['trial_expire_date'] != null
          ? DateTime.parse(json['trial_expire_date'])
          : null,
      createdBy: json['created_by'] ?? 0,
      activeStatus: json['active_status'] ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      darkMode: json['dark_mode'] ?? 0,
      messengerColor: json['messenger_color'],
      isDisable: json['is_disable'] ?? 0,
      typeName: json['type_name'] ?? '',
      userRolesName: json['user_roles_name'] ?? '',
      userCheckInCheckOutDetails:
          (json['user_check_in_check_out_details'] as List<dynamic>?)
              ?.map((item) => CheckInCheckOutHistory.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'title': title,
      'plan_is_active': planIsActive,
      'email': email,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'storage_limit': storageLimit,
      'phone': phone,
      'gender': gender,
      'type': type,
      'is_active': isActive,
      'is_enable_login': isEnableLogin,
      'user_roles': userRoles,
      'lang': lang,
      'mode': mode,
      'avatar': avatar,
      'plan': plan,
      'plan_expire_date': planExpireDate?.toIso8601String(),
      'is_trial_done': isTrialDone,
      'requested_plan': requestedPlan,
      'trial_expire_date': trialExpireDate?.toIso8601String(),
      'created_by': createdBy,
      'active_status': activeStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'dark_mode': darkMode,
      'messenger_color': messengerColor,
      'is_disable': isDisable,
      'type_name': typeName,
      'user_roles_name': userRolesName,
      'user_check_in_check_out_details': userCheckInCheckOutDetails
          .map((item) => item.toJson())
          .toList(),
    };
  }

  @override
  String toString() {
    return 'UserCheckInCheckOutHistory(id: $id, name: $name, email: $email, checkInCheckOutDetails: ${userCheckInCheckOutDetails.length})';
  }
}
