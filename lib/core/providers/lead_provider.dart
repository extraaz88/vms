import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/lead_model.dart';

class LeadProvider extends ChangeNotifier {
  List<Lead> _leads = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Lead> get leads => _leads;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize provider
  Future<void> initialize() async {
    await _loadLeads();
  }

  // Load leads from local storage
  Future<void> _loadLeads() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final leadsJson = prefs.getString('leads_data');

      if (leadsJson != null) {
        final List<dynamic> leadsList = json.decode(leadsJson);
        _leads = leadsList.map((json) => Lead.fromJson(json)).toList();
      } else {
        // Add some sample leads
        await _addSampleLeads();
      }
    } catch (e) {
      _error = 'Failed to load leads: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save leads to local storage
  Future<void> _saveLeads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final leadsJson = json.encode(_leads.map((lead) => lead.toJson()).toList());
      await prefs.setString('leads_data', leadsJson);
    } catch (e) {
      _error = 'Failed to save leads: $e';
      notifyListeners();
    }
  }

  // Add sample leads
  Future<void> _addSampleLeads() async {
    final sampleLeads = [
      Lead.create(
        name: 'John Smith',
        email: 'john.smith@company.com',
        phone: '+1 (555) 123-4567',
        title: 'CEO',
        company: 'Tech Corp',
        industry: 'Technology',
        status: LeadStatus.newLead,
        source: LeadSource.website,
        opportunityAmount: 50000.0,
        description: 'Interested in our enterprise solution',
      ),
      Lead.create(
        name: 'Sarah Johnson',
        email: 'sarah.j@startup.io',
        phone: '+1 (555) 987-6543',
        title: 'Marketing Director',
        company: 'Startup Inc',
        industry: 'Marketing',
        status: LeadStatus.contacted,
        source: LeadSource.email,
        opportunityAmount: 25000.0,
        description: 'Looking for marketing automation tools',
      ),
      Lead.create(
        name: 'Mike Wilson',
        email: 'mike.w@retail.com',
        phone: '+1 (555) 456-7890',
        title: 'Operations Manager',
        company: 'Retail Solutions',
        industry: 'Retail',
        status: LeadStatus.qualified,
        source: LeadSource.referral,
        opportunityAmount: 75000.0,
        description: 'Referred by existing client',
      ),
    ];

    _leads.addAll(sampleLeads);
    await _saveLeads();
  }

  // Create new lead
  Future<bool> createLead(Lead lead) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _leads.add(lead);
      await _saveLeads();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create lead: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update lead
  Future<bool> updateLead(Lead updatedLead) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final index = _leads.indexWhere((lead) => lead.id == updatedLead.id);
      if (index != -1) {
        _leads[index] = updatedLead;
        await _saveLeads();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update lead: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete lead
  Future<bool> deleteLead(String leadId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _leads.removeWhere((lead) => lead.id == leadId);
      await _saveLeads();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete lead: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get lead by ID
  Lead? getLeadById(String leadId) {
    try {
      return _leads.firstWhere((lead) => lead.id == leadId);
    } catch (e) {
      return null;
    }
  }

  // Filter leads by status
  List<Lead> getLeadsByStatus(LeadStatus status) {
    return _leads.where((lead) => lead.status == status).toList();
  }

  // Filter leads by source
  List<Lead> getLeadsBySource(LeadSource source) {
    return _leads.where((lead) => lead.source == source).toList();
  }

  // Search leads
  List<Lead> searchLeads(String query) {
    if (query.isEmpty) return _leads;

    final lowercaseQuery = query.toLowerCase();
    return _leads.where((lead) {
      return lead.name.toLowerCase().contains(lowercaseQuery) ||
             lead.email.toLowerCase().contains(lowercaseQuery) ||
             lead.phone.toLowerCase().contains(lowercaseQuery) ||
             (lead.title?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (lead.company?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Get leads statistics
  Map<String, int> getLeadsStatistics() {
    final stats = <String, int>{};
    
    for (final status in LeadStatus.values) {
      stats[status.displayName] = getLeadsByStatus(status).length;
    }
    
    return stats;
  }

  // Clear all leads
  Future<void> clearAllLeads() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _leads.clear();
      await _saveLeads();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear leads: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh leads
  Future<void> refreshLeads() async {
    await _loadLeads();
  }
}
