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
  Uint8List? imageBytes;
  bool isLoading = false;
  String? userEmail;
  List<String> extraContacts = [];

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
        const SnackBar(content: Text('Extra contact must also end with @enis.tn')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email already added')),
      );
      return;
    }
    setState(() {
      extraContacts.add(email);
      extraContactController.clear();
    });
  }

  Future<void> submit() async {
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an image')),
      );
      return;
    }
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => isLoading = true);

    final base64Image = base64Encode(imageBytes!);

    await FirebaseFirestore.instance.collection('posts').add({
      'type': type,
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
            DropdownButton<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: 'lost', child: Text('Lost')),
                DropdownMenuItem(value: 'found', child: Text('Found')),
              ],
              onChanged: (v) => setState(() => type = v!),
            ),

            // Title
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),

            // Description
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),

            // Place
            TextField(
              controller: placeController,
              decoration: const InputDecoration(labelText: 'Place'),
            ),

            const SizedBox(height: 16),

            // Owner email display
            const Text('Owner Contact',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(userEmail ?? '',
                      style: const TextStyle(color: Colors.blue)),
                  const Spacer(),
                  const Text('You',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Extra contacts
            const Text('Extra Contacts (optional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: extraContactController,
                    decoration: const InputDecoration(
                      labelText: 'Add contact (@enis.tn)',
                      border: OutlineInputBorder(),
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

            // Extra contacts list
            if (extraContacts.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...extraContacts.map((email) => Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.email, color: Colors.green),
                      title: Text(email),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle,
                            color: Colors.red),
                        onPressed: () {
                          setState(() => extraContacts.remove(email));
                        },
                      ),
                    ),
                  )),
            ],

            const SizedBox(height: 16),

            // Image preview
            if (imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(imageBytes!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],

            // Pick image button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.image),
                label: Text(
                    imageBytes == null ? 'Pick Image' : 'Change Image'),
              ),
            ),

            const SizedBox(height: 8),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: submit,
                      child: const Text('Submit'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}