package com.example.nova

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class NotesListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return NotesListRemoteViewsFactory(this.applicationContext, intent)
    }
}

class NotesListRemoteViewsFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {
    
    private var notes: List<NoteItem> = emptyList()
    private val widgetType: String = intent.getStringExtra("widget_type") ?: "recent"
    
    data class NoteItem(val id: String, val title: String, val preview: String)
    
    override fun onCreate() {
        loadNotes()
    }
    
    override fun onDataSetChanged() {
        loadNotes()
    }
    
    private fun loadNotes() {
        val widgetData = HomeWidgetPlugin.getData(context)
        val dataKey = if (widgetType == "pinned") "pinned_notes" else "recent_notes"
        val notesJson = widgetData.getString(dataKey, "[]")
        
        notes = try {
            val jsonArray = JSONArray(notesJson)
            (0 until jsonArray.length()).map { i ->
                val noteObj = jsonArray.getJSONObject(i)
                NoteItem(
                    id = noteObj.getString("id"),
                    title = noteObj.optString("title", "Untitled"),
                    preview = noteObj.optString("preview", "")
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    override fun onDestroy() {
        notes = emptyList()
    }
    
    override fun getCount(): Int = notes.size
    
    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.note_item)
        
        if (position < notes.size) {
            val note = notes[position]
            views.setTextViewText(R.id.note_title, note.title)
            views.setTextViewText(R.id.note_preview, note.preview)
            
            // Set fill-in intent for when item is clicked
            val fillInIntent = Intent().apply {
                putExtra("note_id", note.id)
            }
            views.setOnClickFillInIntent(R.id.note_title, fillInIntent)
        }
        
        return views
    }
    
    override fun getLoadingView(): RemoteViews? = null
    
    override fun getViewTypeCount(): Int = 1
    
    override fun getItemId(position: Int): Long = position.toLong()
    
    override fun hasStableIds(): Boolean = true
}
