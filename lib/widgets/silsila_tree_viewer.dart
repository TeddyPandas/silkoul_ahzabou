import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:silkoul_ahzabou/models/silsila_node.dart';
import 'dart:math' as math;

class SilsilaTreeViewer extends StatefulWidget {
  final List<SilsilaNode> nodes;
  final Function(SilsilaNode)? onNodeTap;

  const SilsilaTreeViewer({
    super.key,
    required this.nodes,
    this.onNodeTap,
  });

  @override
  State<SilsilaTreeViewer> createState() => _SilsilaTreeViewerState();
}

class _SilsilaTreeViewerState extends State<SilsilaTreeViewer> {
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity()..translate(0.0, 50.0);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // LAYOUT LOGIC : Barycenter Heuristic (Centrer les parents au-dessus des enfants)
    final Map<int, List<SilsilaNode>> levels = {};
    for (var node in widget.nodes) {
      levels.putIfAbsent(node.level, () => []).add(node);
    }
    
    const double levelHeight = 220.0; 
    const double nodeWidth = 140.0;   
    const double siblingSpacing = 40.0; // Plus d'espace entre frères/cousins
    
    int maxLevel = levels.keys.fold(0, math.max);
    double totalHeight = (maxLevel + 1) * levelHeight + 200;
    
    // 1. Positionner le Niveau 0 (Utilisateur) au centre
    if (levels.containsKey(0)) {
       var rootNodes = levels[0]!;
       double rowWidth = rootNodes.length * nodeWidth + (rootNodes.length - 1) * siblingSpacing;
       double startX = -(rowWidth / 2) + (nodeWidth / 2);
       for (int i = 0; i < rootNodes.length; i++) {
         rootNodes[i].x = startX + i * (nodeWidth + siblingSpacing);
         rootNodes[i].y = totalHeight - 100; // Bas
       }
    }

    // 2. Propager vers le haut (Niveau 1 -> Max)
    double globalMaxRowWidth = 0;

    for (int lvl = 1; lvl <= maxLevel; lvl++) {
      if (!levels.containsKey(lvl)) continue;
      
      final currentNodes = levels[lvl]!;
      final prevNodes = levels[lvl - 1] ?? [];
      
      // A. Calculer la position idéale (Moyenne des X des enfants)
      for (var node in currentNodes) {
        // Trouver les enfants présents dans le niveau inférieur
        final childrenInGraph = prevNodes.where((n) => node.childrenIds.contains(n.id)).toList();
        
        if (childrenInGraph.isNotEmpty) {
          double sumX = childrenInGraph.fold(0.0, (sum, n) => sum + n.x);
          node.x = sumX / childrenInGraph.length; // Position "idéale" (Barycentre)
        } else {
          // Si orphelin de branche (ex: ajouté manuellement sans lien bas), on le met à 0 temporairement
          node.x = 0;
        }
        // Y Position
        node.y = totalHeight - ((lvl + 1) * levelHeight) + 100;
      }
      
      // B. Trier pour minimiser les croisements (ceux qui ont des enfants à gauche vont à gauche)
      currentNodes.sort((a, b) => a.x.compareTo(b.x));
      
      // C. Résoudre les chevauchements (Spacing)
      // On écarte vers l'extérieur si trop proches
      for (int i = 0; i < currentNodes.length - 1; i++) {
        final nodeA = currentNodes[i];
        final nodeB = currentNodes[i + 1];
        final dist = nodeB.x - nodeA.x;
        final minDist = nodeWidth + siblingSpacing;
        
        if (dist < minDist) {
          // Chevauchement ! On pousse B vers la droite et A vers la gauche
          double push = (minDist - dist) / 2;
          nodeA.x -= push;
          nodeB.x += push;
        }
      }
      
      // Pour être sûr, on repasse pour s'assurer qu'on n'a pas écrasé les voisins précédents 
      // (Simple passe gauche->droite pour garantir l'espacement min)
      for (int i = 1; i < currentNodes.length; i++) {
         final prev = currentNodes[i-1];
         final curr = currentNodes[i];
         if (curr.x < prev.x + nodeWidth + siblingSpacing) {
            curr.x = prev.x + nodeWidth + siblingSpacing;
         }
      }
      
      // D. Recentrer la rangée entiére (Optionnel mais esthétique)
      if (currentNodes.isNotEmpty) {
        double minX = currentNodes.first.x;
        double maxX = currentNodes.last.x;
        double center = (minX + maxX) / 2;
        // On shift tout le monde pour que le centre soit 0
        for (var n in currentNodes) {
          n.x -= center;
        }
        
        double width = maxX - minX + nodeWidth;
        if (width > globalMaxRowWidth) globalMaxRowWidth = width;
      }
    }

    // 🚀 FIX: Force "Le Pôle" (Cheikh Ahmad At-Tidiani) to be Apex (Top Center)
    // Regardless of the level calculation, he must be visually above everyone else.
    try {
      final poleNode = widget.nodes.firstWhere((n) => 
        n.name.toLowerCase().contains('cheikh ahmad at-tidiani') ||
        n.name.toLowerCase().contains('cheikh ahmad tijani')
      );
      
      // Force Position: Top Center
      // We assume x=0 is the center of the canvas in our coordinate system relative to transforms.
      // But adhering to the calculated X (barycenter) is usually better to keep children connected straight.
      // However, to make him "Alone at the Top", we ensure his Y is strictly smaller (higher up) than any other node.
      
      double minY = widget.nodes.where((n) => n != poleNode).map((n) => n.y).fold(double.infinity, math.min);
      
      // If the Pole shares text Y with others or is below, move him UP.
      // We give him a generous margin above the highest node.
      if (poleNode.y >= minY - 100) {
        poleNode.y = minY - 180; // Large spacing above everyone else
      }
      
      // Optional: Force perfect centering (x=0) if desired, but keeping calculated X 
      // preserves the visual tree flow better if the tree is unbalanced.
      // Let's stick to Y separation for now as requested ("au sommet tout seul").
      
    } catch (_) {
      // No pole found, ignore
    }

    final screenSize = MediaQuery.of(context).size;
    final canvasWidth = math.max(screenSize.width, globalMaxRowWidth + 200);

    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: const EdgeInsets.all(500),
      minScale: 0.1,
      maxScale: 2.0,
      constrained: false,
      child: Container(
        width: canvasWidth,
        height: totalHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arrière-plan subtil
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(color: Theme.of(context).dividerColor.withOpacity(0.05)),
              ),
            ),
            
            // Lignes de connexion
            Positioned.fill(
              child: CustomPaint(
                painter: SilsilaLinkPainter(
                  nodes: widget.nodes,
                  lineColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Nœuds
            ...widget.nodes.map((node) {
              return Positioned(
                left: (canvasWidth / 2) + node.x - (nodeWidth / 2),
                top: node.y - 60, // Ajustement pour centrer verticalement
                width: nodeWidth,
                child: _buildGenealogicalNode(context, node),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenealogicalNode(BuildContext context, SilsilaNode node) {
    final theme = Theme.of(context);
    final isRoot = node.isGlobal && node.parentIds.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. LE CERCLE (AVATAR)
        GestureDetector(
          onTap: () => widget.onNodeTap?.call(node),
          child: Container(
            width: isRoot ? 100 : 70, 
            height: isRoot ? 100 : 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.scaffoldBackgroundColor,
              border: Border.all(
                color: isRoot ? const Color(0xFFFFD700) : theme.colorScheme.primary.withOpacity(0.5),
                width: isRoot ? 4 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isRoot 
                      ? const Color(0xFFFFD700).withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isRoot ? 25 : 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0), // Espace entre bordure et image
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: node.image != null 
                      ? DecorationImage(image: AssetImage(node.image!), fit: BoxFit.cover)
                      : null,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                child: node.image == null 
                    ? Icon(
                        isRoot ? Icons.star_rounded : (node.isUser ? Icons.person_outline : Icons.mosque_outlined),
                        size: isRoot ? 50 : 28, // Plus grand pour l'étoile
                        color: isRoot ? const Color(0xFFFFD700) : theme.colorScheme.primary,
                      )
                    : null,
              ),
            ),
          ),
        ).animate()
         .scale(duration: 400.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 12),

        // 2. LE TEXTE (NOM & TITRE)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: isRoot ? BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
          ) : null,
          child: Text(
            node.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isRoot ? FontWeight.w800 : FontWeight.w600,
              fontSize: isRoot ? 16 : 13,
              height: 1.2,
              letterSpacing: 0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ).animate().fadeIn(delay: 200.ms),
        
        if (isRoot)
           Padding(
             padding: const EdgeInsets.only(top: 4.0),
             child: Icon(Icons.star, size: 16, color: const Color(0xFFFFD700))
                 .animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8,0.8), end: const Offset(1.2,1.2)),
           ),
      ],
    );
  }
}

class SilsilaLinkPainter extends CustomPainter {
  final List<SilsilaNode> nodes;
  final Color lineColor;

  SilsilaLinkPainter({required this.nodes, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (var node in nodes) {
      if (node.parentIds.isNotEmpty) {
        final startX = centerX + node.x;
        final startY = node.y - 60; // Haut du cercle enfant (approx)

        for (var parentId in node.parentIds) {
          try {
            final parent = nodes.firstWhere((n) => n.id == parentId);
            final endX = centerX + parent.x;
            final endY = parent.y + 40; // Bas du cercle parent (approx)

            // Dégradé pour la ligne
            paint.shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                 const Color(0xFFFFD700), // Or (Parent)
                 lineColor.withOpacity(0.8), // Couleur thème (Enfant)
              ],
            ).createShader(Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)));

            final path = Path();
            path.moveTo(startX, startY);
            // Courbe plus "organique"
            path.cubicTo(
              startX, startY - 80, // Control point 1 
              endX, endY + 80,     // Control point 2
              endX, endY           // Destination
            );

            canvas.drawPath(path, paint);
          } catch (e) { continue; }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Juste pour donner un repère spatial subtil
class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawCircle(Offset(i, 0), 1, paint);
      for (double j = 0; j < size.height; j += step) {
         if ((i/step).floor() % 2 == 0 && (j/step).floor() % 2 == 0) {
            canvas.drawCircle(Offset(i, j), 1.5, paint);
         }
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
