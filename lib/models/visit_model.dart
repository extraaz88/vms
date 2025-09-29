class Visit {
  final String id;
  final String clientName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double latitude;
  final double longitude;
  final String? notes;
  final String? checkOutNotes;
  final String userId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Visit({
    required this.id,
    required this.clientName,
    required this.checkInTime,
    this.checkOutTime,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.checkOutNotes,
    required this.userId,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'].toString(),
      clientName: json['client_name'] ?? '',
      checkInTime: DateTime.parse(json['check_in_time']),
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time'])
          : null,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      notes: json['notes'],
      checkOutNotes: json['check_out_notes'],
      userId: json['user_id'].toString(),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      'user_id': userId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  // Computed properties
  bool get isActive => checkOutTime == null;
  
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
