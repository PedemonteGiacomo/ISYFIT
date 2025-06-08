import 'package:flutter/material.dart';

class ImageViewScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document View',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16), // Margin outside the border
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey, // Border color
              width: 2, // Border width
            ),
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          padding: const EdgeInsets.all(16), // Padding inside the border
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10), // Clipping corners
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain, // Ensure the image fits well
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child; // Display image when fully loaded
                }
                return const Center(
                  child:
                      CircularProgressIndicator(), // Show a loader while the image is loading
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ); // Display an error message if the image fails to load
              },
            ),
          ),
        ),
      ),
    );
  }
}
