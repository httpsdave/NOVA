package com.example.nova

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class QuickNoteWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.quick_note_widget)
            
            // Get note count from shared preferences
            val widgetData = HomeWidgetPlugin.getData(context)
            val noteCount = widgetData.getInt("note_count", 0)
            views.setTextViewText(R.id.note_count, "$noteCount notes")
            
            // Set up click handler to open app
            val pendingIntent = HomeWidgetPlugin.getPendingIntentForOpeningApp(context)
            views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
