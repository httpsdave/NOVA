package com.nova.nova

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class RecentNotesWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.recent_notes_widget)
            
            // Set up the intent for the ListView
            val intent = Intent(context, NotesListService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                putExtra("widget_type", "recent")
            }
            views.setRemoteAdapter(R.id.notes_list, intent)
            
            // Set click handler for list items
            val clickIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = HomeWidgetPlugin.getPendingIntentForOpeningApp(
                context,
                appWidgetId
            )
            views.setPendingIntentTemplate(R.id.notes_list, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.notes_list)
        }
    }
}
