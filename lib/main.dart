import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'add_post_page.dart';
import 'post_details_page.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/home': (_) => const HomePage(),
        '/login': (_) => const LoginPage(),
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');
    if (email != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    loadEmail();
  }

  Future<void> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserEmail = prefs.getString('userEmail');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found ENIS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('userEmail');
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPostPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No posts yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final contacts = List<String>.from(data['contacts'] ?? []);
              final isOwner = data['ownerEmail'] == currentUserEmail;
              final isAuthorized = contacts.contains(currentUserEmail);

              Uint8List? imageBytes;
              try {
                imageBytes = base64Decode(data['imageBase64']);
              } catch (_) {}

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            imageBytes,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image, size: 60),
                  title: Text(data['title'] ?? ''),
                  subtitle: Text('${data['type']} - ${data['place']}'),
                  trailing: Text(
                    (data['createdAt'] as Timestamp)
                        .toDate()
                        .toString()
                        .substring(0, 10),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailsPage(
                          data: data,
                          docId: doc.id,
                          isOwner: isOwner,
                          isAuthorized: isAuthorized,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
