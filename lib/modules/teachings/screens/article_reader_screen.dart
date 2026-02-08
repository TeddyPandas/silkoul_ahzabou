
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/article.dart';

class ArticleReaderScreen extends StatefulWidget {
  final Article article;
  final String? heroTag;

  const ArticleReaderScreen({
    super.key, 
    required this.article,
    this.heroTag, // Allow passing a Hero tag for animation
  });

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  double _fontSize = 18.0;
  bool _isDarkMode = false;
  bool _isArabic = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode ? Colors.black : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    const starColor = Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.format_size, color: textColor),
            onPressed: () => _showFormatSettings(context),
          ),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: textColor),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.translate, color: textColor),
            onPressed: () {
               setState(() => _isArabic = !_isArabic);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO ANIMATION: SACRED STAR
            if (widget.heroTag != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Hero(
                    tag: widget.heroTag!,
                    child: Icon(
                      Icons.star_rounded,
                      size: 100,
                      color: starColor,
                      shadows: [
                        Shadow(color: starColor.withOpacity(0.5), blurRadius: 20),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds)
                  .shimmer(color: Colors.white, duration: 2.seconds),
                ),
              ),

            // Title
            Text(
              _isArabic ? widget.article.titleAr : widget.article.titleFr,
              textAlign: _isArabic ? TextAlign.right : TextAlign.left,
              textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: _isArabic 
                  ? GoogleFonts.amiri(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)
                  : GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 10),
            
            // Meta Info
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: widget.article.author?.imageUrl != null 
                      ? NetworkImage(widget.article.author!.imageUrl!) 
                      : null,
                  child: widget.article.author?.imageUrl == null 
                      ? const Icon(Icons.person, size: 12) : null,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.article.author?.name ?? "Inconnu",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  "${widget.article.readTimeMinutes} min",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 30),
            
            // Content
            Html(
              data: _isArabic ? widget.article.contentAr : widget.article.contentFr,
              style: {
                "body": Style(
                  fontSize: FontSize(_fontSize),
                  color: textColor,
                  fontFamily: _isArabic ? GoogleFonts.amiri().fontFamily : GoogleFonts.poppins().fontFamily,
                  textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                  direction: _isArabic ? TextDirection.rtl : TextDirection.ltr,
                  lineHeight: const LineHeight(1.6),
                ),
                "p": Style(
                  margin: Margins.only(bottom: 12),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFormatSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Taille de la police", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
              Slider(
                value: _fontSize,
                min: 14.0,
                max: 30.0,
                divisions: 8,
                label: _fontSize.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
