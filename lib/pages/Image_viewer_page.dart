import 'package:flutter/material.dart';

class ImageViewerPage extends StatelessWidget {
  final String title;
  final String imagePath;

  const ImageViewerPage({
    super.key,
    required this.title,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: MediaQuery.of(context).size.width * 0.08,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          // allows pinch to zoom
          child: Image.asset(imagePath),
        ),
      ),
    );
  }
}
