import 'package:flutter/material.dart';
import 'custom_youtube_player.dart';

class CustomYoutubePlayerScreen extends StatelessWidget {
  final String youtubeUrl;
  final String? title;

  const CustomYoutubePlayerScreen({
    super.key,
    required this.youtubeUrl,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title ?? 'ভিডিও প্লেয়ার',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Center(
        child: CustomYoutubePlayer(
          youtubeUrl: youtubeUrl,
          autoPlay: true,
        ),
      ),
    );
  }
}

