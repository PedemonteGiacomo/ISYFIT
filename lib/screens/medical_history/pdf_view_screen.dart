import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PDFViewScreen extends StatefulWidget {
  final String pdfUrl;

  const PDFViewScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  _PDFViewScreenState createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? localFilePath;
  bool isLoading = true;
  int totalPages = 0;
  int currentPage = 0;
  bool showControls = false;

  late PDFViewController pdfController;

  @override
  void initState() {
    super.initState();
    _downloadAndLoadPDF();
  }

  Future<void> _downloadAndLoadPDF() async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/temp_pdf.pdf';

      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          localFilePath = filePath;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading PDF: $e')),
      );
    }
  }

  void _toggleControls() {
    setState(() {
      showControls = !showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        actions: [
          if (!isLoading)
            GestureDetector(
              onTap: _toggleControls,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Page ${currentPage + 1} of $totalPages',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  margin: const EdgeInsets.all(16), // Margin outside the border
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // Border color
                      width: 2, // Border width
                    ),
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  padding:
                      const EdgeInsets.all(16), // Padding inside the border
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10), // Clipping corners
                    child: PDFView(
                      filePath: localFilePath!,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: true,
                      pageFling: true,
                      fitEachPage: true,
                      onRender: (pages) {
                        setState(() {
                          totalPages = pages!;
                        });
                      },
                      onViewCreated: (PDFViewController controller) {
                        pdfController = controller;
                      },
                      onPageChanged: (page, _) {
                        setState(() {
                          currentPage = page!;
                        });
                      },
                      onError: (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $error')),
                        );
                      },
                    ),
                  ),
                ),
          if (showControls) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Go to page:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Page',
                    ),
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page > 0 && page <= totalPages) {
                        pdfController.setPage(page - 1);
                        setState(() {
                          currentPage = page - 1;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid page number')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (currentPage > 0) {
                      pdfController.setPage(currentPage - 1);
                      setState(() {
                        currentPage--;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (currentPage < totalPages - 1) {
                      pdfController.setPage(currentPage + 1);
                      setState(() {
                        currentPage++;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
