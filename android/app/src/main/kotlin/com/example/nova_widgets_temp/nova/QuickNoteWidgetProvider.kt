package com.nova.nova

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
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_note_widget)
            
            // Get widget data from SharedPreferences
            val widgetData = HomeWidgetPlugin.getData(context)
            val noteCount = widgetData.getInt("note_count", 0)
            
            // Update note count
            views.setTextViewText(R.id.note_count, "$noteCount notes")
            
            // Set click handler to open app
            val pendingIntent = HomeWidgetPlugin.getPendingIntentForOpeningApp(
                context, 
                appWidgetId
            )
            views.setOnClickPendingIntent(R.id.widget_icon, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
