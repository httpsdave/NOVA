import 'package:flutter/material.dart';
import '../models/note_template.dart';
import 'note_editor_screen.dart';

class TemplateSelectionScreen extends StatelessWidget {
  final List<Color> availableColors;

  const TemplateSelectionScreen({super.key, required this.availableColors});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final templates = NoteTemplate.getDefaultTemplates();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Template'),
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return _TemplateCard(
            template: template,
            isDark: isDark,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => NoteEditorScreen(
                    availableColors: availableColors,
                    initialTemplate: template,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final NoteTemplate template;
  final bool isDark;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;

    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Text(
                template.icon,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              
              // Name
              Text(
                template.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                template.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
