import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import './widgets/content_edit_modal_widget.dart';

class AdminEditOverlaySystemScreen extends StatelessWidget {
  final Widget child;
  final String contentType;
  final String? contentId;
  final Map<String, dynamic>? contentData;

  const AdminEditOverlaySystemScreen({
    super.key,
    required this.child,
    required this.contentType,
    this.contentId,
    this.contentData,
  });

  void _openEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentEditModalWidget(
        contentType: contentType,
        contentId: contentId,
        contentData: contentData,
        onSaved: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAdmin) return child;

    final admin = Provider.of<AdminProvider>(context);
    if (!admin.isEditMode) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openEditor(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
