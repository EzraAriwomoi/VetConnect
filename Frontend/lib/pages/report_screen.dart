import 'package:flutter/material.dart';
import '../services/report_service.dart';

class ReportScreen extends StatefulWidget {
  final String userId;

  const ReportScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = false;
  String? _reportPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate Report',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Generate a comprehensive report of your activity on VetConnect, including your registered animals, appointment history, and consultation sessions.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Activity Report',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This report includes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    _buildBulletPoint('Your registered animals'),
                    _buildBulletPoint('Appointment history'),
                    _buildBulletPoint('Chat sessions with veterinarians'),
                    _buildBulletPoint('Login activity'),
                    SizedBox(height: 16),
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _reportPath != null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.visibility),
                                    label: Text('View Report'),
                                    onPressed: () {
                                      ReportService.openReport(_reportPath!);
                                    },
                                  ),
                                  SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.share),
                                    label: Text('Share Report'),
                                    onPressed: () {
                                      ReportService.shareReport(_reportPath!);
                                    },
                                  ),
                                ],
                              )
                            : Center(
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.download),
                                  label: Text('Generate Report'),
                                  onPressed: _generateReport,
                                ),
                              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final path = await ReportService.generateUserReport(widget.userId);
      setState(() {
        _reportPath = path;
      });

      if (_reportPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
