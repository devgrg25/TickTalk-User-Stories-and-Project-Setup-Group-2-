import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedPageTitle extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double fontSize;

  const AnimatedPageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.fontSize = 34,
  });

  @override
  State<AnimatedPageTitle> createState() => _AnimatedPageTitleState();
}

class _AnimatedPageTitleState extends State<AnimatedPageTitle>
    with SingleTickerProviderStateMixin {

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, -0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));

    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _fade.value,
        child: SlideTransition(
          position: _slide,
          child: Column(
            children: [
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: GoogleFonts.orbitron(
                    color: Colors.white70,
                    fontSize: widget.fontSize * 0.40,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.8,
                  ),
                ),
              Text(
                widget.title,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
