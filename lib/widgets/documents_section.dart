import 'package:flutter/material.dart';

class DocumentsSection extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> documentsFuture;
  final VoidCallback onUpload;
  final Function(Map<String, dynamic>) onDelete;
  final Function(BuildContext, String, String) onView;

  const DocumentsSection({
    Key? key,
    required this.documentsFuture,
    required this.onUpload,
    required this.onDelete,
    required this.onView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: documentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('No documents uploaded yet.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Document'),
                ),
              ],
            ),
          );
        }

        final documents = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return ListTile(
                title: Text(doc['fileName']),
                trailing: Wrap(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => onView(context, doc['downloadUrl'], doc['fileType']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onDelete(doc),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
