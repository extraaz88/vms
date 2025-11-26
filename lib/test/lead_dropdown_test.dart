import 'package:flutter/foundation.dart';
import '../services/lead_dropdown_service.dart';
import '../models/lead_model.dart';

/// Test class to verify the lead dropdown implementation
class LeadDropdownTest {
  static Future<void> testLeadDropdowns() async {
    if (kDebugMode) {
      print('\n🧪 TESTING LEAD DROPDOWN IMPLEMENTATION');
      print('═══════════════════════════════════════');
    }

    try {
      // Test status list
      print('\n📋 Testing Lead Status List...');
      final statusList = await LeadDropdownService.getLeadStatusList();
      print('✅ Status List: $statusList');

      // Test source map
      print('\n📋 Testing Lead Source Map...');
      final sourceMap = await LeadDropdownService.getLeadSourceMap('1');
      print('✅ Source Map: $sourceMap');

      // Test enum conversion
      print('\n🔄 Testing Enum Conversion...');
      final status = LeadDropdownService.getStatusFromApiString('New');
      final source = LeadDropdownService.getSourceFromApiString('Cold Calling');
      print('✅ Status Enum: ${status.displayName}');
      print('✅ Source Enum: ${source.displayName}');

      print('\n🎉 ALL TESTS PASSED!');
      print('═══════════════════════════════════════');
    } catch (e) {
      print('\n❌ TEST FAILED: $e');
      print('═══════════════════════════════════════');
    }
  }
}
