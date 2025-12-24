import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;

/// Modèle d'une particule unique
class Particle {
  v.Vector3 position;
  v.Vector3 basePosition;
  Color color;
  double baseSize;

  Particle({
    required this.position,
    required this.color,
    required this.baseSize,
  }) : basePosition = position.clone();
}

/// Visualisation 3D de particules réactive à l'audio
class ParticleVisualizer extends StatefulWidget {
  /// Nombre de particules à afficher (basé sur la valeur Abjad)
  final int particleCount;

  /// Intensité de l'effet audio (0.0 = calme, 1.0 = pulsation max)
  final double audioIntensity;

  /// Couleur de thème principale
  final Color primaryColor;

  const ParticleVisualizer({
    super.key,
    this.particleCount = 500,
    this.audioIntensity = 0.0,
    this.primaryColor = const Color(0xFF0FA958),
  });

  @override
  State<ParticleVisualizer> createState() => _ParticleVisualizerState();
}

class _ParticleVisualizerState extends State<ParticleVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];
  double rotationAngle = 0.0;
  double fieldRadius = 150.0;
  int _currentParticleCount = 0;

  @override
  void initState() {
    super.initState();
    _initParticles();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _controller.addListener(_onTick);
  }

  @override
  void didUpdateWidget(ParticleVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.particleCount != widget.particleCount) {
      _initParticles();
    }
  }

  void _initParticles() {
    final count = widget.particleCount.clamp(100, 5000);
    if (count == _currentParticleCount) return;

    _currentParticleCount = count;
    final rng = math.Random();
    particles.clear();

    for (int i = 0; i < count; i++) {
      // Distribution sphérique uniforme
      double theta = rng.nextDouble() * 2 * math.pi;
      double phi = math.acos(2 * rng.nextDouble() - 1);
      double r = fieldRadius * math.pow(rng.nextDouble(), 1 / 3);

      double x = r * math.sin(phi) * math.cos(theta);
      double y = r * math.sin(phi) * math.sin(theta);
      double z = r * math.cos(phi);

      // Couleurs Cyan/Violet/Teal
      Color color = HSLColor.fromAHSL(
        0.6 + rng.nextDouble() * 0.4,
        180 + rng.nextDouble() * 80,
        0.8,
        0.5 + rng.nextDouble() * 0.2,
      ).toColor();

      particles.add(Particle(
        position: v.Vector3(x, y, z),
        color: color,
        baseSize: 0.8 + rng.nextDouble() * 1.5,
      ));
    }
  }

  void _onTick() {
    if (mounted) {
      setState(() {
        rotationAngle += 0.003;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: ParticlePainter(
            particles: particles,
            rotationAngle: rotationAngle,
            intensity: widget.audioIntensity,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

/// CustomPainter qui projette les particules 3D sur le canvas 2D
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double rotationAngle;
  final double intensity;

  ParticlePainter({
    required this.particles,
    required this.rotationAngle,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final fov = size.width * 0.6;

    // Matrice de rotation Y
    final rotationMatrix = v.Matrix3.rotationY(rotationAngle);

    // Trier par profondeur (Z) pour un rendu correct
    final sortedParticles = List<Particle>.from(particles);
    sortedParticles.sort((a, b) {
      final aZ = rotationMatrix.transformed(a.position).z;
      final bZ = rotationMatrix.transformed(b.position).z;
      return bZ.compareTo(aZ);
    });

    for (var particle in sortedParticles) {
      // Appliquer la rotation
      v.Vector3 rotatedPos = rotationMatrix.transformed(particle.position);

      // Effet de pulsation audio
      if (intensity > 0) {
        final pulse = rotatedPos.normalized() * intensity * 30;
        rotatedPos = rotatedPos + pulse;
      }

      // Projection 3D vers 2D
      double zDepth = rotatedPos.z + fov;
      if (zDepth <= 0) continue;

      double scaleFactor = fov / zDepth;
      double x2d = centerX + rotatedPos.x * scaleFactor;
      double y2d = centerY + rotatedPos.y * scaleFactor;

      // Taille basée sur la distance
      double drawingSize = particle.baseSize * scaleFactor;
      if (drawingSize < 0.5) continue;

      // Opacité basée sur la distance
      double distanceOpacity = (scaleFactor * 0.8).clamp(0.0, 1.0);

      final paint = Paint()
        ..color =
            particle.color.withValues(alpha: particle.color.a * distanceOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x2d, y2d), drawingSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.intensity != intensity;
  }
}
