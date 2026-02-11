import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Un AppBar personnalisé et harmonisé pour l'ensemble de l'application.
/// Style : Titre centré, sans ombre, icône retour iOS, typographie Poppins.
class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPress;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const PrimaryAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPress,
    this.backgroundColor = Colors.white,
    this.foregroundColor = AppColors.primary,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: 'Poppins',
        ),
      ),
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: showBackButton && Navigator.of(context).canPop()
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: foregroundColor,
                size: 20,
              ),
              onPressed: onBackPress ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      bottom: bottom ?? PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: Colors.grey.withValues(alpha: 0.1),
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
