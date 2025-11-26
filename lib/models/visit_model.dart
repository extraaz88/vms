class Visit {
  final String id;
  final String clientName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double latitude;
  final double longitude;
  final String? notes;
  final String? checkOutNotes;
  final String? visitingReason;
  final String? visitingArea;
  final String? photoPath;
  final String userId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Lead information fields
  final String? visitingPlace;
  final String? visitingPerson;
  final String? leadId;
  final String? leadName;
  final String? leadEmail;
  final String? leadPhone;

  const Visit({
    required this.id,
    required this.clientName,
    required this.checkInTime,
    this.checkOutTime,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.checkOutNotes,
    this.visitingReason,
    this.visitingArea,
    this.photoPath,
    required this.userId,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.visitingPlace,
    this.visitingPerson,
    this.leadId,
    this.leadName,
    this.leadEmail,
    this.leadPhone,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'].toString(),
      // Handle different field names for client
      clientName: json['client_name'] ?? 
                  json['user_name'] ?? 
                  json['person_name'] ?? 
                  json['visiting_person'] ??
                  'Unknown',
      // Handle different field names for check-in time
      checkInTime: json['check_in_time'] != null 
          ? DateTime.parse(json['check_in_time'])
          : DateTime.parse(json['created_at']),
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      latitude: double.parse(
        (json['latitude'] ?? json['in_latitude'] ?? '0').toString(),
      ),
      longitude: double.parse(
        (json['longitude'] ?? json['in_longitude'] ?? '0').toString(),
      ),
      notes: json['notes'] ?? json['in_notes'] ?? json['reason'],
      checkOutNotes: json['check_out_notes'] ?? json['out_notes'],
      visitingReason: json['visiting_reason'] ?? json['reason'],
      visitingArea: json['visiting_area'] ?? json['area_name'],
      photoPath: json['photo_path'] ?? json['photo'],
      userId: json['user_id'].toString(),
      status: json['status']?.toString() ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      visitingPlace: json['visiting_place'],
      visitingPerson: json['visiting_person'] ?? json['person_name'],
      leadId: json['lead_id']?.toString(),
      leadName: json['lead_name'] ?? json['get_lead']?['name'],
      leadEmail: json['lead_email'] ?? json['get_lead']?['email'],
      leadPhone: json['lead_phone'] ?? json['get_lead']?['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_name': clientName,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'check_out_notes': checkOutNotes,
      'visiting_reason': visitingReason,
      'visiting_area': visitingArea,
      'photo_path': photoPath,
      'user_id': userId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'visiting_place': visitingPlace,
      'visiting_person': visitingPerson,
      'lead_id': leadId,
      'lead_name': leadName,
      'lead_email': leadEmail,
      'lead_phone': leadPhone,
    };
  }

  // Computed properties
  bool get isActive => checkOutTime == null;

  // Visit time - for direct visits, this is the same as checkInTime
  DateTime get visitTime => checkInTime;

  Duration? get duration {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  String get durationString {
    final dur = duration;
    if (dur == null) return 'Active';

    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Visit copyWith({
    String? id,
    String? clientName,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? latitude,
    double? longitude,
    String? notes,
    String? checkOutNotes,
    String? visitingReason,
    String? visitingArea,
    String? photoPath,
    String? userId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Visit(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      checkOutNotes: checkOutNotes ?? this.checkOutNotes,
      visitingReason: visitingReason ?? this.visitingReason,
      visitingArea: visitingArea ?? this.visitingArea,
      photoPath: photoPath ?? this.photoPath,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Visit(id: $id, clientName: $clientName, checkInTime: $checkInTime, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Visit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
