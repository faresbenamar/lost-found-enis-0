import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isOwner;
  final bool isAuthorized;

  const PostDetailsPage({
    super.key,
    required this.data,
    required this.docId,
    required this.isOwner,
    required this.isAuthorized,
  });

  void openFullImage(BuildContext context, Uint8List imageBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.memory(imageBytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(data['imageBase64'] ?? '');
    } catch (_) {}

    final date = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    final formattedDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final contacts = List<String>.from(data['contacts'] ?? []);
    final postType = data['type'] ?? 'lost';

    return Scaffold(
      appBar: AppBar(
        title: Text(data['title'] ?? 'Post Details'),
        actions: [
          if (isAuthorized)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'toggle') {
                  final newType = postType == 'lost' ? 'found' : 'lost';
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(docId)
                      .update({'type': newType});
                  Navigator.pop(context);
                } else if (value == 'delete' && isOwner) {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(docId)
                      .delete();
                  Navigator.pop(context);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    postType == 'lost' ? 'Mark as Found' : 'Mark as Lost',
                  ),
                ),
                if (isOwner)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Post'),
                  ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (imageBytes != null)
              GestureDetector(
                onTap: () => openFullImage(context, imageBytes!),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        imageBytes,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: postType == 'lost' ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    postType == 'lost' ? Icons.search : Icons.check_circle,
                    color: postType == 'lost' ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    postType.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: postType == 'lost' ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Info card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.title, 'Title', data['title'] ?? '-'),
                    const Divider(),
                    _infoRow(
                      Icons.description,
                      'Description',
                      data['description'] ?? '-',
                    ),
                    const Divider(),
                    _infoRow(Icons.location_on, 'Place', data['place'] ?? '-'),
                    const Divider(),
                    _infoRow(
                      Icons.calendar_today,
                      'Date Posted',
                      formattedDate,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contacts card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contacts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...contacts.map(
                      (email) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.email,
                              size: 18,
                              color: Color(0xFF1565C0),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                email,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            if (email == data['ownerEmail'])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1565C0,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'owner',
                                  style: TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
