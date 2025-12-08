package com.example.nova

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class PinnedNotesWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.pinned_notes_widget)
            
            // Set up the intent for the RemoteViewsService
            val intent = Intent(context, NotesListService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                putExtra("widget_type", "pinned")
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            
            views.setRemoteAdapter(R.id.pinned_notes_list, intent)
            
            // Set up click handler for list items
            val clickIntent = Intent(context, MainActivity::class.java)
            val clickPendingIntent = HomeWidgetPlugin.getPendingIntentForOpeningApp(context)
            views.setPendingIntentTemplate(R.id.pinned_notes_list, clickPendingIntent)
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
