import 'dart:convert';

class Lead {
  final String id;
  final String name;
  final String? account;
  final String? company;
  final String email;
  final String phone;
  final String? title;
  final String? website;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final LeadStatus status;
  final LeadSource source;
  final double? opportunityAmount;
  final String? campaign;
  final String industry;
  final String? assignedUser;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lead({
    required this.id,
    required this.name,
    this.account,
    this.company,
    required this.email,
    required this.phone,
    this.title,
    this.website,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    required this.status,
    required this.source,
    this.opportunityAmount,
    this.campaign,
    required this.industry,
    this.assignedUser,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from JSON
  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      account: json['account'],
      company: json['company'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      title: json['title'],
      website: json['website'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postal_code'],
      country: json['country'],
      status: LeadStatus.fromString(json['status'] ?? 'new'),
      source: LeadSource.fromString(json['source'] ?? 'cold_calling'),
      opportunityAmount: json['opportunity_amount']?.toDouble(),
      campaign: json['campaign'],
      industry: json['industry'] ?? 'Sales',
      assignedUser: json['assigned_user'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'account': account,
      'company': company,
      'email': email,
      'phone': phone,
      'title': title,
      'website': website,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'status': status.value,
      'source': source.value,
      'opportunity_amount': opportunityAmount,
      'campaign': campaign,
      'industry': industry,
      'assigned_user': assignedUser,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create new lead
  static Lead create({
    required String name,
    String? account,
    String? company,
    required String email,
    required String phone,
    String? title,
    String? website,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    LeadStatus status = LeadStatus.newLead,
    LeadSource source = LeadSource.coldCalling,
    double? opportunityAmount,
    String? campaign,
    String industry = 'Sales',
    String? assignedUser,
    String? description,
  }) {
    final now = DateTime.now();
    return Lead(
      id: 'lead_${now.millisecondsSinceEpoch}',
      name: name,
      account: account,
      company: company,
      email: email,
      phone: phone,
      title: title,
      website: website,
      address: address,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      status: status,
      source: source,
      opportunityAmount: opportunityAmount,
      campaign: campaign,
      industry: industry,
      assignedUser: assignedUser,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copy with method
  Lead copyWith({
    String? name,
    String? account,
    String? company,
    String? email,
    String? phone,
    String? title,
    String? website,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    LeadStatus? status,
    LeadSource? source,
    double? opportunityAmount,
    String? campaign,
    String? industry,
    String? assignedUser,
    String? description,
  }) {
    return Lead(
      id: id,
      name: name ?? this.name,
      account: account ?? this.account,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      title: title ?? this.title,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      status: status ?? this.status,
      source: source ?? this.source,
      opportunityAmount: opportunityAmount ?? this.opportunityAmount,
      campaign: campaign ?? this.campaign,
      industry: industry ?? this.industry,
      assignedUser: assignedUser ?? this.assignedUser,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// Lead Status Enum
enum LeadStatus {
  newLead('new', 'New'),
  contacted('contacted', 'Contacted'),
  qualified('qualified', 'Qualified'),
  proposal('proposal', 'Proposal'),
  negotiation('negotiation', 'Negotiation'),
  closedWon('closed_won', 'Closed Won'),
  closedLost('closed_lost', 'Closed Lost');

  const LeadStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static LeadStatus fromString(String value) {
    return LeadStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => LeadStatus.newLead,
    );
  }
}

// Lead Source Enum
enum LeadSource {
  coldCalling('cold_calling', 'Cold Calling'),
  email('email', 'Email'),
  website('website', 'Website'),
  referral('referral', 'Referral'),
  socialMedia('social_media', 'Social Media'),
  tradeShow('trade_show', 'Trade Show'),
  advertising('advertising', 'Advertising'),
  other('other', 'Other');

  const LeadSource(this.value, this.displayName);

  final String value;
  final String displayName;

  static LeadSource fromString(String value) {
    return LeadSource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => LeadSource.coldCalling,
    );
  }
}
