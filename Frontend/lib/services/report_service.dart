import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'api_service.dart';

class ReportService {
  // Generate user activity report
  static Future<String?> generateUserReport(String userId) async {
    try {
      // Get report URL from API
      final response = await ApiService.authenticatedRequest(
        method: 'GET',
        endpoint: '/reports/user',
      );
      
      if (response.statusCode != 200) {
        print('Error generating report: ${response.statusCode} - ${response.body}');
        return null;
      }
      
      final data = json.decode(response.body);
      final reportUrl = data['reportUrl'];
      
      if (reportUrl == null) {
        return null;
      }
      
      // Download the report
      final downloadResponse = await http.get(Uri.parse(reportUrl));
      
      if (downloadResponse.statusCode != 200) {
        return null;
      }
      
      // Save the report to a temporary file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/vetconnect_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(downloadResponse.bodyBytes);
      
      return file.path;
    } catch (e) {
      print('Error generating report: $e');
      return null;
    }
  }

  // Open the generated report
  static Future<void> openReport(String filePath) async {
    await OpenFile.open(filePath);
  }

  // Share the generated report
  static Future<void> shareReport(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'VetConnect Activity Report');
  }
}

