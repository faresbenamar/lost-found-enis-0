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
            // Image — tap to open fullscreen
            if (imageBytes != null)
              GestureDetector(
                onTap: () => openFullImage(context, imageBytes!),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: postType == 'lost' ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
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

            // Title
            const Text(
              'Title',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            Text(data['title'] ?? '-', style: const TextStyle(fontSize: 18)),
            const Divider(),

            // Description
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            Text(
              data['description'] ?? '-',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(),

            // Place
            const Text(
              'Place',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            Text(data['place'] ?? '-', style: const TextStyle(fontSize: 16)),
            const Divider(),

            // Contacts
            const Text(
              'Contacts',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            ...contacts.map(
              (email) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(email, style: const TextStyle(fontSize: 16)),
                    if (email == data['ownerEmail']) ...[
                      const SizedBox(width: 8),
                      const Text(
                        '(owner)',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(),

            // Date
            const Text(
              'Date Posted',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            Text(formattedDate, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
