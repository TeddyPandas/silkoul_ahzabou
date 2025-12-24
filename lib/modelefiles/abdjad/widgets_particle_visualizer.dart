import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;

/// Modèle d'une particule unique
class Particle {
  v.Vector3 position;
  Color color;
  double baseSize;

  Particle({required this.position, required this.color, required this.baseSize});
}

class ParticleVisualizer extends StatefulWidget {
  // Ce booléen permettra de déclencher l'effet "danse" quand le son joue
  final bool isActive;

  const ParticleVisualizer({Key? key, required this.isActive}) : super(key: key);

  @override
  _ParticleVisualizerState createState() => _ParticleVisualizerState();
}

class _ParticleVisualizerState extends State<ParticleVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];
  final int particleCount = 2000; // Nombre de particules (ajuster selon performance)
  final double fieldRadius = 200.0; // Taille de la sphère de particules
  double rotationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _initParticles();
    
    // Boucle d'animation infinie (60 FPS visés)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Durée arbitraire pour une rotation lente
    )..repeat();
  }

  void _initParticles() {
    final rng = math.Random();
    particles.clear();
    for (int i = 0; i < particleCount; i++) {
      // Création de positions aléatoires dans une sphère
      // Utilisation de coordonnées sphériques pour une meilleure répartition
      double theta = rng.nextDouble() * 2 * math.pi;
      double phi = math.acos(2 * rng.nextDouble() - 1);
      double r = fieldRadius * math.pow(rng.nextDouble(), 1/3); // Racine cubique pour uniformiser

      double x = r * math.sin(phi) * math.cos(theta);
      double y = r * math.sin(phi) * math.sin(theta);
      double z = r * math.cos(phi);

      // Couleurs style "Cyberpunk/Nébuleuse" (Bleu/Violet/Cyan)
      Color color = HSLColor.fromAHSL(
        0.6 + rng.nextDouble() * 0.4, // Opacité
        180 + rng.nextDouble() * 80,  // Teinte (Hue) entre Cyan et Violet
        0.8,                          // Saturation
        0.5 + rng.nextDouble() * 0.2  // Luminosité
      ).toColor();

      particles.add(Particle(
        position: v.Vector3(x, y, z),
        color: color,
        baseSize: 0.5 + rng.nextDouble() * 1.5,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // À chaque frame, on fait tourner légèrement la scène
        rotationAngle += 0.002;
        
        return CustomPaint(
          painter: ParticlePainter(
            particles: particles,
            rotationAngle: rotationAngle,
            // Si actif, on simule une "intensité" qui repousse les particules
            intensity: widget.isActive ? 0.2 : 0.0,
          ),
          child: Container(),
        );
      },
    );
  }
}

/// Le Peintre qui convertit la 3D en 2D sur le Canvas
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
    // "Focale" de la caméra. Plus c'est grand, plus le champ de vision est étroit.
    final fov = size.width * 0.8; 

    // Matrice de rotation autour de l'axe Y (pour faire tourner la scène)
    final rotationMatrix = v.Matrix3.rotationY(rotationAngle);

    for (var particle in particles) {
      // 1. Appliquer la rotation à la position de base
      v.Vector3 rotatedPos = rotationMatrix.transformed(particle.position);

      // 2. Simuler la réactivité audio (les faire "pulser" vers l'extérieur)
      if (intensity > 0) {
        // On pousse la particule loin du centre (0,0,0)
        rotatedPos.add(rotatedPos.normalized() * intensity * 20);
      }

      // 3. Projection 3D vers 2D (Perspective simple)
      // On décale Z pour que le centre de la scène soit devant la caméra
      double zDepth = rotatedPos.z + fov; 

      // Si la particule est derrière la caméra, on ne la dessine pas
      if (zDepth <= 0) continue;

      double scaleFactor = fov / zDepth;
      double x2d = centerX + rotatedPos.x * scaleFactor;
      double y2d = centerY + rotatedPos.y * scaleFactor;

      // 4. Dessiner la particule
      // La taille dépend de la distance (scaleFactor)
      double drawingSize = particle.baseSize * scaleFactor;
      
      // L'opacité dépend aussi de la distance (les lointaines sont plus transparentes)
      double distanceOpacity = (scaleFactor * 0.8).clamp(0.0, 1.0);
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.color.opacity * distanceOpacity)
        ..style = PaintingStyle.fill;

      // On utilise des cercles pour les particules
      canvas.drawCircle(Offset(x2d, y2d), drawingSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    // On doit redessiner à chaque fois que l'angle ou l'intensité change
    return oldDelegate.rotationAngle != rotationAngle || oldDelegate.intensity != intensity;
  }
}
