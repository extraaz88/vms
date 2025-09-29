class LocationLog {
  final String id;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double battery;
  final DateTime timestamp;
  final String userId;
  
  const LocationLog({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.battery,
    required this.timestamp,
    required this.userId,
  });
  
  factory LocationLog.fromJson(Map<String, dynamic> json) {
    return LocationLog(
      id: json['id'].toString(),
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      accuracy: double.parse(json['accuracy'].toString()),
      battery: double.parse(json['battery'].toString()),
      timestamp: DateTime.parse(json['logged_at']),
      userId: json['user_id'].toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'battery': battery,
      'logged_at': timestamp.toIso8601String(),
      'user_id': userId,
    };
  }
  
  // Create LocationLog without ID (for new entries)
  factory LocationLog.create({
    required double latitude,
    required double longitude,
    required double accuracy,
    required double battery,
    required String userId,
    DateTime? timestamp,
  }) {
    return LocationLog(
      id: '',
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      battery: battery,
      timestamp: timestamp ?? DateTime.now(),
      userId: userId,
    );
  }
  
  LocationLog copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? battery,
    DateTime? timestamp,
    String? userId,
  }) {
    return LocationLog(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      battery: battery ?? this.battery,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
    );
  }
  
  @override
  String toString() {
    return 'LocationLog(id: $id, lat: $latitude, lng: $longitude, time: $timestamp)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationLog && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

class LiveTrackingData {
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final DateTime lastUpdate;
  
  const LiveTrackingData({
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.lastUpdate,
  });
  
  factory LiveTrackingData.fromJson(Map<String, dynamic> json) {
    return LiveTrackingData(
      userId: json['user']['id'].toString(),
      userName: json['user']['name'] ?? '',
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      lastUpdate: DateTime.parse(json['logged_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': userId,
        'name': userName,
      },
      'latitude': latitude,
      'longitude': longitude,
      'logged_at': lastUpdate.toIso8601String(),
    };
  }
}
