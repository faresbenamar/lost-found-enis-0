import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final placeController = TextEditingController();
  final extraContactController = TextEditingController();

  String type = 'lost';
  String category = 'electronics';
  Uint8List? imageBytes;
  bool isLoading = false;
  String? userEmail;
  List<String> extraContacts = [];

  final List<String> categories = [
    'electronics',
    'clothes',
    'money',
    'keys',
    'wallets',
    'others',
  ];

  @override
  void initState() {
    super.initState();
    loadEmail();
  }

  Future<void> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail');
    });
  }

  Future pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 600,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        imageBytes = bytes;
      });
    }
  }

  void addExtraContact() {
    final email = extraContactController.text.trim();
    if (!email.endsWith('@enis.tn')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Extra contact must also end with @enis.tn'),
        ),
      );
      return;
    }
    if (email == userEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is already your email')),
      );
      return;
    }
    if (extraContacts.contains(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email already added')));
      return;
    }
    setState(() {
      extraContacts.add(email);
      extraContactController.clear();
    });
  }

  Future<void> submit() async {
    if (imageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick an image')));
      return;
    }
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    setState(() => isLoading = true);

    final base64Image = base64Encode(imageBytes!);

    await FirebaseFirestore.instance.collection('posts').add({
      'type': type,
      'category': category,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'place': placeController.text.trim(),
      'ownerEmail': userEmail,
      'contacts': [userEmail, ...extraContacts],
      'imageBase64': base64Image,
      'createdAt': Timestamp.now(),
    });

    setState(() => isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => type = 'lost'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: type == 'lost'
                            ? Colors.red[400]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Lost',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: type == 'lost' ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => type = 'found'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: type == 'found'
                            ? Colors.green[400]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Found',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: type == 'found'
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Category selector
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((c) {
                final isSelected = category == c;
                return GestureDetector(
                  onTap: () => setState(() => category = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1565C0)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      c[0].toUpperCase() + c.substring(1),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Title
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title, color: Color(0xFF1565C0)),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description, color: Color(0xFF1565C0)),
              ),
            ),
            const SizedBox(height: 12),

            // Place
            TextField(
              controller: placeController,
              decoration: const InputDecoration(
                labelText: 'Place',
                prefixIcon: Icon(Icons.location_on, color: Color(0xFF1565C0)),
              ),
            ),

            const SizedBox(height: 20),

            // Owner email
            const Text(
              'Owner Contact',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(
                    userEmail ?? '',
                    style: const TextStyle(color: Color(0xFF1565C0)),
                  ),
                  const Spacer(),
                  const Text(
                    'You',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Extra contacts
            const Text(
              'Extra Contacts (optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: extraContactController,
                    decoration: const InputDecoration(
                      labelText: 'Add contact (@enis.tn)',
                      prefixIcon: Icon(Icons.email, color: Color(0xFF1565C0)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: addExtraContact,
                  child: const Text('Add'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (extraContacts.isNotEmpty) ...[
              ...extraContacts.map(
                (email) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.email, color: Colors.green),
                    title: Text(email),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() => extraContacts.remove(email));
                      },
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Image preview
            if (imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  imageBytes!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Pick image button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.image),
                label: Text(imageBytes == null ? 'Pick Image' : 'Change Image'),
              ),
            ),

            const SizedBox(height: 12),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                      ),
                      child: const Text(
                        'Submit Post',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
