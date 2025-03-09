import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class PDFViewScreen extends StatefulWidget {
  final String fileUrl;
  final String fileExtension; // e.g. 'pdf', 'doc', 'docx', etc.

  const PDFViewScreen({
    Key? key,
    required this.fileUrl,
    required this.fileExtension,
  }) : super(key: key);

  @override
  _PDFViewScreenState createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? localFilePath;
  bool isLoading = true;

  // For PDFs
  int totalPages = 0;
  int currentPage = 0;
  bool showControls = false;
  late PDFViewController pdfController;

  // For docx via Google Docs in WebView
  bool isWebViewInitialized = false;

  @override
  void initState() {
    super.initState();
    _initFileViewer();
  }

  Future<void> _initFileViewer() async {
    final extension = widget.fileExtension.toLowerCase();
    if (extension == 'pdf') {
      await _downloadAndLoadPDF();
    } else if (extension == 'doc' || extension == 'docx') {
      setState(() {
        isLoading = false;
        isWebViewInitialized = true;
      });
    } else {
      // unsupported
      setState(() => isLoading = false);
    }
  }

  Future<void> _downloadAndLoadPDF() async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/temp_file.pdf';
      final response = await http.get(Uri.parse(widget.fileUrl));
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
      setState(() => isLoading = false);
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
    final extension = widget.fileExtension.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            extension == 'pdf'
                ? 'PDF Viewer'
                : (extension == 'doc' || extension == 'docx')
                    ? 'DOCX Viewer'
                    : 'File Viewer',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        actions: [
          if (!isLoading && extension == 'pdf')
            InkWell(
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
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (extension == 'pdf' && localFilePath != null) _buildPDFView(),
            if ((extension == 'doc' || extension == 'docx') &&
                isWebViewInitialized)
              _buildDocxView(),
            if (extension != 'pdf' && extension != 'doc' && extension != 'docx')
              _buildUnsupportedView(),
          ],
          if (showControls && extension == 'pdf') _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildPDFView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: PDFView(
          filePath: localFilePath!,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: true,
          pageFling: true,
          fitEachPage: true,
          onRender: (pages) {
            setState(() {
              totalPages = pages ?? 0;
            });
          },
          onViewCreated: (controller) {
            pdfController = controller;
          },
          onPageChanged: (page, _) {
            setState(() {
              currentPage = page ?? 0;
            });
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $error')),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocxView() {
    // Use Google Docs viewer link
    final docxUrl = widget.fileUrl;
    final googleDocsUrl =
        'https://docs.google.com/gview?embedded=true&url=$docxUrl';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: const Text('...'), // or a WebView, see below
      ),
    );
  }

  Widget _buildUnsupportedView() {
    return const Center(
      child: Text('Unsupported file type'),
    );
  }

  Widget _buildControlsOverlay() {
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
