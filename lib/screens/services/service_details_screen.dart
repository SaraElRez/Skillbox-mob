import 'package:flutter/material.dart';
import 'package:skillbox/screens/chat/chat_screen.dart';
import 'package:skillbox/services/chat_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/services_service.dart';
import '../../services/api_service.dart';
import '../../models/service.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final int serviceId;

  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  late Future<Map<String, dynamic>> _futureDetails;

  @override
  void initState() {
    super.initState();
    _futureDetails = ServicesService.getServiceDetails(widget.serviceId);
  }

  // Helper method to open CV
  // Helper method to open CV
  Future<void> _openCV(String cvPath) async {
    try {
      // Use the API base URL from .env
      final String baseUrl = ApiService.baseUrl;

      // The CV path from API is like: "public/uploads/portfolios/2/2_20251024_CV.pdf"
      // We need to extract just: "portfolios/2/2_20251024_CV.pdf"

      String cleanPath = cvPath;

      // Remove 'public/uploads/' prefix if it exists
      if (cleanPath.startsWith('public/uploads/')) {
        cleanPath = cleanPath.replaceFirst('public/uploads/', '');
      }
      // Or just 'uploads/' prefix
      else if (cleanPath.startsWith('uploads/')) {
        cleanPath = cleanPath.replaceFirst('uploads/', '');
      }

      // Use API endpoint to serve the file
      final String fullUrl = '$baseUrl/api/cv/$cleanPath';

      print('🔗 Attempting to open CV: $fullUrl');
      print('📄 Original CV path: $cvPath');
      print('🧹 Clean path: $cleanPath');

      final Uri uri = Uri.parse(fullUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open CV: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Helper method to open LinkedIn
  Future<void> _openLinkedIn(String linkedinUrl) async {
    try {
      final Uri uri = Uri.parse(linkedinUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open LinkedIn: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to start chat
  void _startChat(int workerId, String workerName) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Start or get conversation
      final result = await ChatService.startConversation(workerId);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Navigate to chat screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: result['conversation'].id,
              otherUserId: workerId,
              otherUserName: workerName,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Service Details"),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: _futureDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load service details',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _futureDetails = ServicesService.getServiceDetails(
                          widget.serviceId,
                        );
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final data = snapshot.data!;
          final service = Service.fromJson(data["service"]);
          final workers = data["workers"] as List<dynamic>;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Service Title
                  Text(
                    service.title,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.07,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Service Description
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Workers Section
                  Text(
                    "Our Expert Workers",
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.055,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Workers List
                  workers.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'No workers assigned to this service yet.',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.04,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: workers.length,
                          itemBuilder: (context, index) {
                            final worker = workers[index];
                            return _buildWorkerCard(worker);
                          },
                        ),

                  const SizedBox(height: 24),

                  // Back Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(
                        'Back to Services',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    final String fullName = worker['full_name'] ?? 'Unknown';
    final String email = worker['email'] ?? 'N/A';
    final String? phone = worker['phone'];
    final String? linkedin = worker['linkedin'];
    final String? cv = worker['cv'];
    final int workerId = worker['id'] ?? 0;

    // Get first letter for avatar
    final String initial = fullName.isNotEmpty
        ? fullName[0].toUpperCase()
        : 'U';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar Circle
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.cyan[100],
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan[800],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Worker Name
            Text(
              fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Worker Details
            _buildInfoRow(Icons.email, 'Email', email),
            if (phone != null && phone.isNotEmpty)
              _buildInfoRow(Icons.phone, 'Phone', phone),
            if (linkedin != null && linkedin.isNotEmpty)
              _buildClickableInfoRow(
                Icons.link,
                'LinkedIn',
                linkedin,
                () => _openLinkedIn(linkedin),
              ),

            const SizedBox(height: 16),

            // Action Buttons
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 350) {
                  // Wide enough: side by side
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cv != null && cv.isNotEmpty
                                ? Colors.blue
                                : Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: cv != null && cv.isNotEmpty
                              ? () => _openCV(cv)
                              : null,
                          icon: const Icon(Icons.description, size: 18),
                          label: Text(
                            cv != null && cv.isNotEmpty ? 'View CV' : 'No CV',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _startChat(workerId, fullName),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Chat', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Narrow: stacked
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cv != null && cv.isNotEmpty
                                ? Colors.blue
                                : Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: cv != null && cv.isNotEmpty
                              ? () => _openCV(cv)
                              : null,
                          icon: const Icon(Icons.description, size: 18),
                          label: Text(
                            cv != null && cv.isNotEmpty ? 'View CV' : 'No CV',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _startChat(workerId, fullName),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Chat', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableInfoRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
