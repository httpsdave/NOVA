import 'package:home_widget/home_widget.dart';
import 'database_service.dart';

class WidgetService {
  static final WidgetService instance = WidgetService._init();
  
  WidgetService._init();

  /// Initialize home widgets
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('group.com.nova.app');
    } catch (e) {
      print('Error initializing widgets: $e');
    }
  }

  /// Update all widgets with latest data
  Future<void> updateAllWidgets() async {
    try {
      await updateQuickNoteWidget();
      await updateRecentNotesWidget();
      await updatePinnedNotesWidget();
      
      // Trigger widget update
      await HomeWidget.updateWidget(
        androidName: 'QuickNoteWidgetProvider',
      );
      await HomeWidget.updateWidget(
        androidName: 'RecentNotesWidgetProvider',
      );
      await HomeWidget.updateWidget(
        androidName: 'PinnedNotesWidgetProvider',
      );
    } catch (e) {
      print('Error updating widgets: $e');
    }
  }

  /// Update quick note widget
  Future<void> updateQuickNoteWidget() async {
    try {
      final notes = await DatabaseService.instance.getAllNotes();
      final noteCount = notes.length;
      
      await HomeWidget.saveWidgetData<int>('note_count', noteCount);
    } catch (e) {
      print('Error updating quick note widget: $e');
    }
  }

  /// Update recent notes widget
  Future<void> updateRecentNotesWidget() async {
    try {
      final notes = await DatabaseService.instance.getAllNotes();
      final recentNotes = notes.take(5).toList();
      
      // Save note titles and IDs
      for (int i = 0; i < recentNotes.length; i++) {
        await HomeWidget.saveWidgetData<String>(
          'recent_note_${i}_title',
          recentNotes[i].title.isEmpty ? 'Untitled' : recentNotes[i].title,
        );
        await HomeWidget.saveWidgetData<String>(
          'recent_note_${i}_id',
          recentNotes[i].id,
        );
        
        // Truncate content for preview
        final preview = recentNotes[i].content.length > 100
            ? '${recentNotes[i].content.substring(0, 100)}...'
            : recentNotes[i].content;
        await HomeWidget.saveWidgetData<String>(
          'recent_note_${i}_preview',
          preview,
        );
      }
      
      await HomeWidget.saveWidgetData<int>('recent_notes_count', recentNotes.length);
    } catch (e) {
      print('Error updating recent notes widget: $e');
    }
  }

  /// Update pinned notes widget
  Future<void> updatePinnedNotesWidget() async {
    try {
      final notes = await DatabaseService.instance.getAllNotes();
      final pinnedNotes = notes.where((note) => note.isPinned).take(5).toList();
      
      // Save pinned note titles and IDs
      for (int i = 0; i < pinnedNotes.length; i++) {
        await HomeWidget.saveWidgetData<String>(
          'pinned_note_${i}_title',
          pinnedNotes[i].title.isEmpty ? 'Untitled' : pinnedNotes[i].title,
        );
        await HomeWidget.saveWidgetData<String>(
          'pinned_note_${i}_id',
          pinnedNotes[i].id,
        );
        
        // Truncate content for preview
        final preview = pinnedNotes[i].content.length > 100
            ? '${pinnedNotes[i].content.substring(0, 100)}...'
            : pinnedNotes[i].content;
        await HomeWidget.saveWidgetData<String>(
          'pinned_note_${i}_preview',
          preview,
        );
      }
      
      await HomeWidget.saveWidgetData<int>('pinned_notes_count', pinnedNotes.length);
    } catch (e) {
      print('Error updating pinned notes widget: $e');
    }
  }

  /// Handle widget tap - returns the note ID or action
  static Future<String?> getWidgetData() async {
    try {
      final data = await HomeWidget.getWidgetData<String>('widget_action');
      return data;
    } catch (e) {
      print('Error getting widget data: $e');
      return null;
    }
  }

  /// Clear widget data
  Future<void> clearWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_action', null);
    } catch (e) {
      print('Error clearing widget data: $e');
    }
  }
}
