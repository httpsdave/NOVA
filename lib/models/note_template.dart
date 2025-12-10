class NoteTemplate {
  final String id;
  final String name;
  final String description;
  final String content;
  final String icon;
  final int color;
  final List<String> tags;

  NoteTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.content,
    required this.icon,
    required this.color,
    required this.tags,
  });

  static List<NoteTemplate> getDefaultTemplates() {
    return [
      NoteTemplate(
        id: 'blank',
        name: 'Blank Note',
        description: 'Start with a blank note',
        content: '',
        icon: '📝',
        color: 0xFFFFFFFF,
        tags: [],
      ),
      NoteTemplate(
        id: 'meeting',
        name: 'Meeting Notes',
        description: 'Template for meeting notes',
        content: '''**Meeting Title:**

**Date:** 
**Attendees:**
**Location:**

**Agenda:**
1. 
2. 
3. 

**Discussion Points:**
- 

**Action Items:**
- [ ] 
- [ ] 

**Next Meeting:**''',
        icon: '📅',
        color: 0xFF2196F3,
        tags: ['meeting', 'work'],
      ),
      NoteTemplate(
        id: 'todo',
        name: 'To-Do List',
        description: 'Checklist template',
        content: '''**To-Do List**

**Priority Tasks:**
- [ ] 
- [ ] 
- [ ] 

**Regular Tasks:**
- [ ] 
- [ ] 
- [ ] 

**Notes:**''',
        icon: '✅',
        color: 0xFF4CAF50,
        tags: ['todo', 'tasks'],
      ),
      NoteTemplate(
        id: 'project',
        name: 'Project Planning',
        description: 'Plan your next project',
        content: '''**Project Name:**

**Goal:**

**Timeline:**
- Start Date:
- End Date:

**Milestones:**
1. 
2. 
3. 

**Resources Needed:**
- 
- 

**Key Tasks:**
- [ ] 
- [ ] 
- [ ] 

**Notes:**''',
        icon: '🎯',
        color: 0xFF9C27B0,
        tags: ['project', 'planning'],
      ),
      NoteTemplate(
        id: 'journal',
        name: 'Daily Journal',
        description: 'Daily reflection template',
        content: '''**Date:** ${_getTodayDate()}

**Mood:** 

**Highlights:**
- 
- 

**Challenges:**
- 

**Grateful For:**
1. 
2. 
3. 

**Tomorrow's Goals:**
- [ ] 
- [ ] 

**Reflections:**''',
        icon: '📔',
        color: 0xFFFF9800,
        tags: ['journal', 'personal'],
      ),
      NoteTemplate(
        id: 'idea',
        name: 'Idea Brainstorm',
        description: 'Capture and develop ideas',
        content: '''**Idea Title:**

**Core Concept:**

**Why This Matters:**

**Key Components:**
1. 
2. 
3. 

**Pros:**
- 
- 

**Cons:**
- 
- 

**Next Steps:**
- [ ] 
- [ ] 

**Resources:**''',
        icon: '💡',
        color: 0xFFFFEB3B,
        tags: ['ideas', 'brainstorm'],
      ),
      NoteTemplate(
        id: 'recipe',
        name: 'Recipe',
        description: 'Save your favorite recipes',
        content: '''**Recipe Name:**

**Servings:** 
**Prep Time:** 
**Cook Time:** 

**Ingredients:**
- 
- 
- 

**Instructions:**
1. 
2. 
3. 

**Notes:**

**Rating:** ⭐⭐⭐⭐⭐''',
        icon: '🍳',
        color: 0xFFFF5722,
        tags: ['recipe', 'food'],
      ),
      NoteTemplate(
        id: 'book',
        name: 'Book Notes',
        description: 'Track your reading',
        content: '''**Book Title:**

**Author:**
**Started:** 
**Finished:** 

**Key Takeaways:**
1. 
2. 
3. 

**Favorite Quotes:**
> 

**My Thoughts:**

**Rating:** ⭐⭐⭐⭐⭐
**Would Recommend:** Yes/No''',
        icon: '📚',
        color: 0xFF795548,
        tags: ['books', 'reading'],
      ),
      NoteTemplate(
        id: 'travel',
        name: 'Travel Planning',
        description: 'Plan your next trip',
        content: '''**Destination:**

**Dates:** 

**Budget:**

**Accommodation:**

**Transportation:**

**Things to Do:**
- [ ] 
- [ ] 
- [ ] 

**Places to Visit:**
1. 
2. 
3. 

**Restaurants to Try:**
- 
- 

**Packing List:**
- [ ] 
- [ ] 

**Notes:**''',
        icon: '✈️',
        color: 0xFF00BCD4,
        tags: ['travel', 'planning'],
      ),
      NoteTemplate(
        id: 'fitness',
        name: 'Workout Log',
        description: 'Track your fitness',
        content: '''**Date:** ${_getTodayDate()}

**Workout Type:**

**Duration:**

**Exercises:**
1. 
   - Sets: 
   - Reps: 
   - Weight: 

2. 
   - Sets: 
   - Reps: 
   - Weight: 

**Cardio:**
- Type: 
- Duration: 
- Distance: 

**Notes:**

**Energy Level:** 1-10
**Overall Feel:**''',
        icon: '💪',
        color: 0xFFE91E63,
        tags: ['fitness', 'health'],
      ),
    ];
  }

  static String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
