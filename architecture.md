# FitnessTracker - Architecture Documentation

## App Overview

Voice-first iOS fitness tracking app with OpenAI GPT integration for natural language workout logging and querying.

**Primary Use Case**: User speaks workout description ("I did 3 sets of bench press at 185 pounds, RPE 7") → AI parses into structured data → User reviews/edits → Saves to local CoreData.

**Key Features**:
- Voice-based workout and nutrition logging using Apple Speech Recognition
- AI-powered parsing with auto-generated workout names (OpenAI GPT-4o-mini)
- Date extraction from voice input with timezone correction ("on jan 2nd", "yesterday", "this past Saturday")
- Inline editing of parsed workouts/meals before saving
- Template system for workouts and meals with voice and UI-based selection, editing, and deletion
- Calendar view with green highlights for logged dates
- AI-powered history chat with conversation memory for both workouts and nutrition
- Recovery activities (sauna, stretching) and cardio recognized as valid exercises
- Data backup and restore via JSON export/import (preserves data across reinstalls)
- Settings screen with data management tools
- Local-only data storage (no cloud sync)
- Minimal, clean UI design inspired by Apple Health

---

## Tech Stack

- **Platform**: iOS 17+ (deployment target can be lowered based on device)
- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Data Persistence**: CoreData with NSPersistentContainer
- **AI Service**: OpenAI GPT-4o-mini API (structured JSON output)
- **Speech Recognition**: Apple Speech Framework (SFSpeechRecognizer + AVFoundation)
- **Secure Storage**: iOS Keychain Services (for API key)
- **Reactive Programming**: Combine framework (for @Published properties)

---

## Architecture Pattern: MVVM

### Models
- **CoreData Entities**: `Workout`, `Exercise`, `Meal`, `FoodItem` (managed objects)
- **Swift Structs**: `WorkoutSession`, `WorkoutExercise`, `MealSession`, `MealFood` (clean data transfer objects)
- **Chat Models**: `ChatMessage`, `ConversationContext` (for history queries)
- Purpose: Separation between persistence layer and business logic

### Views
- SwiftUI views with declarative UI
- Sheet-based modal navigation
- Environment-based dismissal patterns
- Reusable components for chat bubbles, voice input, etc.

### ViewModels
- `@MainActor` classes conforming to `ObservableObject`
- Manage state with `@Published` properties
- Coordinate between Services and Views
- **CRITICAL**: All ViewModels require `import Combine`

---

## Critical Technical Notes

### 1. Combine Framework Requirement
**All ViewModels MUST import Combine**:
```swift
import Foundation
import SwiftUI
import Combine  // ← REQUIRED for ObservableObject

@MainActor
class MyViewModel: ObservableObject {
    @Published var someProperty: String = ""
}
```
Without this import, you'll get: "Type does not conform to protocol 'ObservableObject'"

### 2. Speech Recognition
- **Requires physical iPhone device** - does not work in simulator
- Needs microphone and speech recognition permissions in Info.plist
- Real-time transcription using `SFSpeechRecognizer`
- AVAudioEngine for audio input

### 3. API Key Management
- Stored securely in iOS Keychain (never UserDefaults or plist)
- First-run experience prompts user for OpenAI API key
- Key validation checks for "sk-" prefix

### 4. CoreData to Swift Struct Mapping
- CoreData entities for persistence
- Swift structs (Codable, Identifiable) for passing data in app
- Repository layer handles conversion between both

### 5. Navigation Patterns
- Sheet presentation for modal flows
- Callback closures for nested view dismissal
- Example: LogWorkoutView → WorkoutConfirmationView both dismiss on save

### 6. Scrolling and Keyboard Management
- ScrollView content should have sufficient bottom padding (100+ pts)
- Use `.scrollDismissesKeyboard(.interactively)` for better UX
- Prevents content from being hidden behind keyboard

---

## Data Models

### CoreData Entities

#### Workout Entity
| Attribute | Type | Optional | Notes |
|-----------|------|----------|-------|
| id | UUID | No | Primary key |
| date | Date | No | Workout timestamp |
| name | String | Yes | Descriptive workout name (e.g., "Chest & Triceps") |
| isTemplate | Bool | No | True if saved as template, false for regular workouts |
| exercises | Relationship | No | → [Exercise] with cascade delete |

#### Exercise Entity
| Attribute | Type | Optional | Notes |
|-----------|------|----------|-------|
| id | UUID | No | Primary key |
| name | String | No | Exercise name (e.g., "Bench Press") |
| sets | Int16 | No | Number of sets |
| reps | Int16 | No | Repetitions per set (or minutes for cardio) |
| weight | Double | No | Weight in pounds (0 if bodyweight/cardio/recovery) |
| rpe | Int16 | No | Rate of Perceived Exertion (0-10, 0=not set) |
| notes | String | Yes | Optional notes/comments |
| order | Int16 | No | Display order within workout |
| workout | Relationship | No | ← Workout (inverse) |

#### Meal Entity
| Attribute | Type | Optional | Notes |
|-----------|------|----------|-------|
| id | UUID | No | Primary key |
| date | Date | No | Meal timestamp |
| name | String | Yes | Meal name (template or descriptive) |
| mealType | String | Yes | breakfast, lunch, dinner, snack |
| foodItems | Relationship | No | → [FoodItem] with cascade delete |

#### FoodItem Entity
| Attribute | Type | Optional | Notes |
|-----------|------|----------|-------|
| id | UUID | No | Primary key |
| name | String | No | Food name (e.g., "Grilled Chicken Breast") |
| portionSize | String | Yes | Portion (e.g., "6 oz", "1 cup") |
| calories | Double | Yes | Estimated calories |
| protein | Double | Yes | Grams of protein |
| carbs | Double | Yes | Grams of carbs |
| fat | Double | Yes | Grams of fat |
| notes | String | Yes | Optional notes |
| order | Int16 | No | Display order within meal |
| meal | Relationship | No | ← Meal (inverse) |

### Swift Structs

#### WorkoutExercise
```swift
struct WorkoutExercise: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double
    var rpe: Int  // 0-10 scale
    var notes: String?
    var order: Int
}
```

#### WorkoutSession
```swift
struct WorkoutSession: Identifiable, Codable {
    var id: UUID
    var date: Date
    var name: String?  // Descriptive name ("Chest & Triceps") or template name
    var isTemplate: Bool  // True if saved template
    var exercises: [WorkoutExercise]
}
```

#### MealFood
```swift
struct MealFood: Identifiable, Codable {
    var id: UUID
    var name: String
    var portionSize: String?
    var calories: Double?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var notes: String?
    var order: Int
}
```

#### MealSession
```swift
struct MealSession: Identifiable, Codable {
    var id: UUID
    var date: Date
    var name: String?  // Meal name
    var mealType: String?  // breakfast/lunch/dinner/snack
    var foodItems: [MealFood]

    var totalCalories: Double { /* computed */ }
    var totalProtein: Double { /* computed */ }
    var totalCarbs: Double { /* computed */ }
    var totalFat: Double { /* computed */ }
}
```

#### ChatMessage
```swift
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
}
```

#### ConversationContext
```swift
struct ConversationContext {
    var messages: [ChatMessage]
    let maxContextMessages: Int = 10  // Token management

    func getRecentContext() -> [ChatMessage]
    func formatForPrompt() -> String
    mutating func addMessage(_ message: ChatMessage)
    mutating func clear()
}
```

### Templates
- Templates have `isTemplate = true` flag
- Regular workouts/meals have `isTemplate = false`
- All workouts now have descriptive names (GPT-generated or user-edited)
- Repository filters using `isTemplate == YES` for templates
- Templates can be selected via UI picker or voice command ("use my push day template")

---

## File Structure

```
FitnessTracker/
├── FitnessTrackerApp.swift          # App entry point
│
├── Models/
│   ├── FitnessTracker.xcdatamodeld  # CoreData schema (Workout, Exercise, Meal, FoodItem)
│   ├── Workout+Extensions.swift     # CoreData helpers for Workout
│   ├── Meal+Extensions.swift        # CoreData helpers for Meal
│   ├── WorkoutModel.swift           # Swift structs (WorkoutSession, WorkoutExercise)
│   ├── MealModel.swift              # Swift structs (MealSession, MealFood)
│   ├── ChatMessage.swift            # Chat message model
│   └── ConversationContext.swift    # Conversation history management
│
├── Views/
│   ├── RootView.swift               # Router: checks API key → HomeView or APIKeyInputView
│   ├── HomeView.swift               # Main screen: 2x2 grid (workouts + nutrition)
│   ├── APIKeyInputView.swift        # First-run: secure API key input
│   ├── LogWorkoutView.swift         # Voice recording → AI parsing → display results
│   ├── WorkoutConfirmationView.swift # Edit parsed workout (with name field) + save
│   ├── TemplatePickerView.swift     # Select and edit workout templates
│   ├── TemplateEditView.swift       # Edit workout template name and exercises
│   ├── ReviewWorkoutsView.swift     # Calendar view + workout list + floating chat
│   ├── WorkoutDayListView.swift     # Shows workouts for selected date with edit/delete
│   ├── LogMealView.swift            # Voice recording → AI meal parsing → display
│   ├── MealConfirmationView.swift   # Edit parsed meal + save + template prompt
│   ├── NutritionTemplatePickerView.swift # Select and edit meal templates
│   ├── NutritionTemplateEditView.swift # Edit meal template
│   ├── ReviewNutritionView.swift    # Calendar view + meal list + floating chat
│   ├── MealDayListView.swift        # Shows meals for selected date with edit/delete
│   └── Components/
│       ├── VoiceRecordButton.swift  # Reusable voice recording UI with pulsing animation
│       ├── ChatBubbleView.swift     # User (blue) and AI (gray) message bubbles
│       ├── ExampleQuestionsView.swift # Horizontal scrolling question chips
│       ├── ChatInputView.swift      # Text field + voice button + send button
│       ├── VoiceInputSheet.swift    # Sheet for voice input in chat
│       ├── TypingIndicatorView.swift # Animated typing indicator
│       ├── CalendarView.swift       # Monthly calendar with green date highlights
│       └── FloatingChatButton.swift # Animated floating chat button (bottom right)
│
├── ViewModels/
│   ├── LogWorkoutViewModel.swift         # State for workout logging flow
│   ├── WorkoutConfirmationViewModel.swift # State for editing/validation/saving
│   ├── TemplateEditViewModel.swift       # State for workout template editing
│   ├── ReviewWorkoutsViewModel.swift     # State for workout chat interface
│   ├── CalendarViewModel.swift           # State for calendar (month navigation, selection)
│   ├── LogMealViewModel.swift            # State for meal logging flow
│   ├── MealConfirmationViewModel.swift   # State for meal editing/validation/saving
│   ├── NutritionTemplateEditViewModel.swift # State for meal template editing
│   └── ReviewNutritionViewModel.swift    # State for nutrition chat interface
│
├── Services/
│   ├── PersistenceController.swift  # CoreData stack (singleton)
│   ├── WorkoutRepository.swift      # Workout data access (CRUD + templates)
│   ├── NutritionRepository.swift    # Meal data access (CRUD + templates)
│   ├── KeychainManager.swift        # Secure API key storage
│   ├── OpenAIService.swift          # API integration (parsing + querying + date extraction)
│   ├── SpeechRecognizer.swift       # Voice recognition wrapper
│   └── DataSeeder.swift             # One-time data seeding utility
│
└── Utilities/
    ├── PromptTemplates.swift        # OpenAI prompt engineering
    └── Constants.swift              # (Future) App-wide constants
```

---

## Phase Completion Status

### ✅ Phase 1: Project Foundation & Data Layer
- **Chunk 1.1**: Xcode project setup with folder structure
- **Chunk 1.2**: CoreData model (Workout + Exercise entities)
- **Chunk 1.3**: Swift models + WorkoutRepository (CRUD + templates)

### ✅ Phase 2: API Key Management & OpenAI Integration
- **Chunk 2.1**: KeychainManager + APIKeyInputView (secure storage)
- **Chunk 2.2**: OpenAIService (parseWorkoutText + queryWorkoutHistory)

### ✅ Phase 3: Voice Recognition
- **Chunk 3.1**: SpeechRecognizer setup (requires physical iPhone)
- **Chunk 3.2**: VoiceRecordButton component with animations

### ✅ Phase 4: Main Navigation & Home Screen
- **Chunk 4.1**: RootView router + HomeView with main buttons

### ✅ Phase 5: Log Workout Feature
- **Chunk 5.1**: LogWorkoutView (voice input → AI parsing → display)
- **Chunk 5.2**: WorkoutConfirmationView (inline editing)
- **Chunk 5.3**: Template save prompt after workout save

### ✅ Phase 6: Template System
- **Chunk 6.1**: Template selection via UI and voice commands with AI-based matching
- **Chunk 6.2**: Template editing and management (TemplateEditView + TemplateEditViewModel)

### ✅ Phase 7: Review Workout Feature
- **Chunk 7.1**: Chat interface for querying workout history
  - ChatMessage and ConversationContext models
  - ReviewWorkoutsViewModel with conversation memory (10 messages)
  - Chat UI components (ChatBubbleView, ExampleQuestionsView, ChatInputView)
  - VoiceInputSheet for voice queries
  - Example question chips that immediately send on tap
  - "New Conversation" button to clear history
  - Auto-scroll to latest messages

### ✅ Phase 8: Nutrition Tracking
- **Chunk 8.1**: Nutrition data model (Meal + FoodItem CoreData entities, MealSession + MealFood structs)
- **Chunk 8.2**: NutritionRepository for meal CRUD operations
- **Chunk 8.3**: GPT prompts for meal parsing with macro estimation
- **Chunk 8.4**: LogMealView + MealConfirmationView (parallel to workout flow)
- **Chunk 8.5**: Meal templates with voice/UI selection
- **Chunk 8.6**: ReviewNutritionView with chat interface

### ✅ Phase 9: Calendar View & Enhancements
- **Chunk 9.1**: CalendarView component with month navigation
- **Chunk 9.2**: Green highlights for dates with logged data
- **Chunk 9.3**: WorkoutDayListView and MealDayListView for date-specific entries
- **Chunk 9.4**: FloatingChatButton component (bottom right)
- **Chunk 9.5**: Workout naming system (GPT-generated descriptive names)
- **Chunk 9.6**: Date extraction from voice input ("on jan 2nd", "yesterday")
- **Chunk 9.7**: isTemplate boolean field (replaced name-based template detection)
- **Chunk 9.8**: Recovery activities (sauna, stretching) and cardio recognized as exercises

### 🔲 Phase 10: Polish & Edge Cases
- **Chunk 8.1**: Error handling improvements
- **Chunk 8.2**: Onboarding experience polish
- **Chunk 8.3**: UI polish + accessibility (VoiceOver, Dark Mode)
- **Chunk 8.4**: Performance optimization
- **Chunk 8.5**: Final testing & bug fixes

### ✅ Phase 10 Enhancements (January 2026)

**Edit Workflow Fixes**:
- Fixed workout/meal editing to update existing entries instead of creating duplicates
- Repository pattern now checks for existing workout/meal by ID before saving
- Added `isEditMode` flag to confirmation views to skip template prompts when editing
- Proper update vs create distinction in `saveWorkout()` and `saveMeal()` methods

**Template System Improvements**:
- Fixed critical bug where templates loaded via "Use Template" were saved with `isTemplate: true`
- Template-loaded workouts now correctly marked as regular workouts (`isTemplate: false`)
- Added template deletion functionality with confirmation dialogs
- Delete buttons added to both workout and nutrition template cards

**Data Backup & Restore**:
- New `BackupService` for exporting all data to JSON format
- Settings screen with export/import functionality using iOS share sheet and file picker
- Exports include all workouts, meals, and templates with full metadata
- Import validates and restores data from previously exported backups
- Critical for preserving data across app reinstalls (especially for free Apple Developer accounts)

**Date Extraction Timezone Fix**:
- Fixed timezone bug where dates extracted from voice ("January 9th") were off by one day
- AI returns dates in UTC, now properly converted to local timezone at 8:00 AM
- Day-of-week context added to AI prompt (e.g., "Today is Sunday") for accurate relative dates
- Fixes apply to both workout and meal date parsing

**UI/UX Improvements**:
- Fixed scrolling issue in LogWorkoutView parsed results (wrapped in ScrollView)
- Fixed calendar week day ForEach duplicate ID warning (S and T appeared twice)
- Added bottom padding to scrollable content to prevent content hiding behind keyboard
- Improved visual feedback with consistent use of `.scrollDismissesKeyboard()`

**Known Limitations**:
- Free Apple Developer accounts: Apps expire every 7 days, requiring reinstall and data restore
- Paid accounts: No expiration, data persists indefinitely
- Relative date parsing ("this past Saturday") requires day-of-week context in prompt
- Batch logging (multiple templates at once) not yet implemented

---

## Navigation Flow

```
RootView (checks API key)
├── [No Key] → APIKeyInputView
│               └── Save → HomeView
│
└── [Has Key] → HomeView
                ├── "Log New Workout" → LogWorkoutView (sheet)
                │                        ├── "Use Template" button (if templates exist)
                │                        │   └── TemplatePickerView (sheet)
                │                        │       ├── Tap card → Load template
                │                        │       └── Tap edit icon → TemplateEditView (sheet)
                │                        ├── VoiceRecordButton
                │                        │   └── Can say "use my [template name]" to load template
                │                        ├── Processing state (AI parsing)
                │                        ├── Error state (retry button)
                │                        └── Success → "Continue" → WorkoutConfirmationView (sheet)
                │                                                     ├── Edit fields inline
                │                                                     ├── Add/Delete exercises
                │                                                     └── "Save Workout"
                │                                                         └── Alert: "Save as Template?"
                │                                                             ├── Yes → Template name input
                │                                                             │        → Success alert
                │                                                             └── No → Success alert
                │                                                                      → dismiss both sheets
                │
                └── "Review Workouts" → ReviewWorkoutsView (sheet)
                                        ├── Example question chips (always visible)
                                        ├── Chat history with conversation memory
                                        ├── Text input + voice button
                                        ├── Auto-scroll to latest message
                                        └── "New Conversation" button (clear history)
```

---

## Key Services & Their Responsibilities

### PersistenceController
- Manages CoreData stack (NSPersistentContainer)
- Singleton pattern: `PersistenceController.shared`
- Preview instance with sample data for SwiftUI previews

### WorkoutRepository
**Methods**:
- `saveWorkout(_ workout: WorkoutSession) -> Bool`
- `fetchAllWorkouts() -> [WorkoutSession]`
- `fetchWorkouts(from: Date, to: Date) -> [WorkoutSession]`
- `deleteWorkout(id: UUID) -> Bool`
- `saveTemplate(name: String, exercises: [WorkoutExercise]) -> Bool`
- `fetchTemplates() -> [WorkoutSession]`
- `updateTemplate(id: UUID, name: String, exercises: [WorkoutExercise]) -> Bool`

**Responsibilities**:
- Converts between CoreData entities and Swift structs
- Filters templates using `isTemplate == YES` predicate
- Handles all workout-related CoreData operations

### NutritionRepository
**Methods**:
- `saveMeal(_ meal: MealSession) -> Bool`
- `fetchAllMeals() -> [MealSession]`
- `fetchMeals(from: Date, to: Date) -> [MealSession]`
- `deleteMeal(id: UUID) -> Bool`
- `saveTemplate(name: String, foodItems: [MealFood], mealType: String?) -> Bool`
- `fetchTemplates() -> [MealSession]`
- `updateTemplate(id: UUID, name: String, foodItems: [MealFood], mealType: String?) -> Bool`

**Responsibilities**:
- Converts between CoreData Meal/FoodItem entities and Swift structs
- Parallel structure to WorkoutRepository for consistency
- Handles all meal-related CoreData operations

### OpenAIService
**Methods**:
- `parseWorkoutText(_ text: String, previousWorkout: WorkoutSession?, availableTemplates: [WorkoutSession]) async throws -> WorkoutSession`
- `parseMealText(_ text: String, previousMeal: MealSession?, availableTemplates: [MealSession]) async throws -> MealSession`
- `queryWorkoutHistory(_ question: String, context: [WorkoutSession]) async throws -> String`
- `queryWorkoutHistoryWithContext(_ question: String, workouts: [WorkoutSession], conversationContext: ConversationContext) async throws -> String`
- `queryNutritionHistory(_ question: String, meals: [MealSession]) async throws -> String`
- `queryNutritionHistoryWithContext(_ question: String, meals: [MealSession], conversationContext: ConversationContext) async throws -> String`

**Configuration**:
- Model: `gpt-4o-mini`
- Uses structured JSON output mode for reliable parsing
- Error handling with custom `OpenAIError` enum
- Response limit: 500 tokens for chat queries

**Prompt Engineering**:
- Workout parsing: Natural language → JSON with workout name generation
- Date extraction: Parses dates from voice ("on jan 2nd", "yesterday") to ISO 8601
- Recovery/cardio recognition: Treats sauna, stretching, running as valid exercises
- Nutrition parsing: Estimates all macros (calories, protein, carbs, fat) based on food descriptions
- Supports "same as last time" by passing previous workout/meal
- Supports template matching and modifications ("use push day but add 5 pounds")
- Query answering: Analyzes workout/nutrition data with conversation context
- Chat-optimized: Concise responses (2-3 paragraphs max) that fit in chat bubbles

### KeychainManager
**Methods**:
- `saveAPIKey(_ key: String) -> Bool`
- `getAPIKey() -> String?`
- `deleteAPIKey() -> Bool`
- `hasAPIKey() -> Bool`
- `static isValidAPIKeyFormat(_ key: String) -> Bool` (checks "sk-" prefix)

### SpeechRecognizer
**Properties**:
- `@Published var transcription: String`
- `@Published var isRecording: Bool`
- `@Published var isAuthorized: Bool`

**Methods**:
- `startRecording()`
- `stopRecording()`
- `requestAuthorization()`

**NOTE**: Requires `import Combine` and physical device for testing

---

## Common Error Patterns & Fixes

### Error 1: "Type does not conform to protocol 'ObservableObject'"
**Cause**: Missing `import Combine` in ViewModel
**Fix**: Add `import Combine` at top of file

### Error 2: "Property 'viewContext' is not available"
**Cause**: Missing `import CoreData`
**Fix**: Add `import CoreData` in views using CoreData

### Error 3: iOS Deployment Target Mismatch
**Cause**: Xcode deployment target higher than physical device iOS version
**Fix**: Lower deployment target in project settings (currently iOS 17.0)

### Error 4: Speech Recognition Not Working
**Cause**: Running in simulator (requires physical device)
**Fix**: Run on physical iPhone with microphone permissions granted

### Error 5: Nested Sheet Dismissal Issues
**Cause**: Parent view not dismissing when child saves
**Fix**: Use callback closures passed to child views
```swift
// Child view
var onComplete: (() -> Void)?
// On completion:
dismiss()
onComplete?()

// Parent view
ChildView {
    dismiss()  // Dismiss parent too
}
```

### Error 6: Content Hidden Behind Keyboard or Bottom of Screen
**Cause**: Insufficient bottom padding in ScrollView
**Fix**: Add `.padding(.bottom, 100)` to last element in ScrollView and `.scrollDismissesKeyboard(.interactively)` to ScrollView

---

## OpenAI Integration Details

### Workout Parsing Prompt Strategy
1. Provide clear JSON schema for structured output
2. Handle missing data gracefully (use 0/null for RPE if not mentioned)
3. Standardize exercise names ("benching" → "Bench Press")
4. Support "same as last time" by providing previous workout context
5. Support template references with flexible matching:
   - Pass all available templates in prompt
   - AI matches template name (case-insensitive, partial matching)
   - AI applies modifications ("add 5 pounds", "skip exercise", "12 reps instead")

### Query Prompt Strategy
1. Pass entire workout history as JSON context
2. Include conversation history (last 10 messages) for follow-up questions
3. Request natural language response (no tables/charts)
4. Keep responses concise (2-3 paragraphs max) for chat UI
5. Answer questions about:
   - Recent workouts ("What did I do last week?")
   - Progress tracking ("How much weight added to bench press?")
   - Frequency analysis ("Most frequent exercise?")
   - Follow-up questions using conversation context

### Cost Optimization
- Use GPT-4o-mini (cheaper than GPT-4)
- Typical cost: ~$0.01-0.05 per workout
- Structured output reduces token usage
- 500 token limit on chat responses
- 10 message conversation limit (token management)

---

## Chat Feature Details

### Conversation Memory
- Maintains last 10 messages (5 exchanges) for context
- Token limit management prevents API overflow
- Formatted as "User: question\nAssistant: answer" for prompts

### Example Questions
- Displayed as horizontal scrolling chips at top
- Always visible throughout conversation
- Tap to immediately send (no input field fill)
- Current examples:
  1. "What exercises did I do most last month?"
  2. "Show me my bench press progress"
  3. "How many workouts this week?"
  4. "What was my heaviest squat?"

### Chat UI Components
- **ChatBubbleView**: Rounded bubbles (20pt corner radius, continuous style)
  - User messages: Blue background, right-aligned
  - AI messages: Gray background, left-aligned
  - Max width: 75% of screen
- **ExampleQuestionsView**: Scrolling chips with tap handlers
- **ChatInputView**: Text field + microphone button + send button
- **TypingIndicatorView**: Animated dots while AI processes
- **VoiceInputSheet**: Full-screen voice input for queries

### Auto-Scroll Behavior
- Scrolls to latest message when new message added
- Scrolls to typing indicator while processing
- Uses ScrollViewReader with message IDs

---

## Current Development Status

**Last Completed**: Phase 10 Enhancements (January 2026)

**Fully Functional**:
- Complete voice-to-save workout and nutrition logging
- AI-generated workout names with inline editing
- Date extraction from voice input with timezone correction for historical logging
- Template system for workouts and meals with deletion support
- Calendar view with green highlights for logged dates
- Floating chat interface for workout and nutrition history
- Recovery activities and cardio recognized as exercises
- Conversation memory and follow-up questions
- Data backup and restore via JSON export/import
- Edit existing workouts/meals (updates instead of duplicating)
- Settings screen with data management

**Production Ready Features**:
- Voice recording and transcription
- AI parsing with date/name/macro estimation and day-of-week context
- Inline editing of all workout/meal fields
- Template creation, editing, deletion, and reuse
- Calendar-based navigation and visualization
- Chat-based history analysis with context
- Edit/delete past entries from calendar view
- Data export/import for backup purposes

**Remaining Phase 10 Tasks**:
- Error handling improvements
- Onboarding experience polish
- Accessibility support (VoiceOver, Dynamic Type)
- Performance optimization
- Batch logging (multiple templates at once)
- Final testing and bug fixes

---

## Testing Guidelines

### What Works in Simulator
- UI navigation and layout
- CoreData persistence
- OpenAI API calls (if network available)
- Manual text input
- Chat interface

### Requires Physical Device
- Voice recording (SFSpeechRecognizer)
- Microphone permissions
- Real-world speech transcription testing
- Voice input in chat

### Testing Checklist per Feature
1. Build succeeds without warnings
2. App launches without crashes
3. Follow test steps provided by developer
4. Verify expected behavior matches actual behavior
5. Check Xcode console for success/error messages
6. Test scrolling with large content
7. Test keyboard dismissal
8. Report results: "works as expected" or describe issues

### Known Issues & Fixes Applied
- ✅ Scroll issue with many exercises: Fixed with `.padding(.bottom, 100)` and `.scrollDismissesKeyboard()`
- ✅ Chat bubbles too rectangular: Fixed with `cornerRadius: 20, style: .continuous`

---

## Design Principles

1. **Voice-First**: Primary interaction via voice, fallback to manual editing
2. **Minimal UI**: Clean, Apple Health-inspired design
3. **Local-Only**: No cloud sync, all data stays on device
4. **Editable Results**: Always allow user to review/edit AI parsing
5. **Incremental Saves**: Save workout immediately, template optional
6. **Fail Gracefully**: Show retry options, clear error messages
7. **Conversational**: Chat feels natural with memory and context

---

## Distribution & Deployment

### Requirements for TestFlight
- **Apple Developer Program**: $99/year (individual or organization)
- **Bundle Identifier**: Unique (e.g., `com.pranavmenon.FitnessTracker`)
- **App Icon**: 1024x1024px required
- **Privacy Policy**: Required (app collects workout data, uses OpenAI)
- **App Store Connect**: Create app listing

### Development Testing
- **Free Developer Account**: Install directly on iPhone via Xcode
- **Limitation**: App expires every 7 days, requires reinstall
- **Paid Account**: Use TestFlight (apps last 90 days, up to 100 testers)

### Data Management
- Delete and reinstall app to clear all data (CoreData stored in app container)
- No cloud backup - data lost on app deletion

---

## Future Enhancements (Post-MVP)

*Not included in current build plan:*
- Settings screen (API key management, preferences)
- Data export functionality (CSV/JSON)
- Charts and visualizations (progress graphs, volume tracking)
- Apple Health integration
- Widget support
- Share workouts with others
- Workout reminders and scheduling
- Exercise library with form videos
- Custom AI prompt editing
- Cloud sync across devices
- PostgreSQL backend migration

---

**Last Updated**: Phase 10 Enhancements (January 2026) - Edit Workflow, Data Backup, Timezone Fixes

**App Status**: Production-ready with workout + nutrition tracking, calendar views, AI chat, data backup/restore, and template management. Key bug fixes applied for editing, date extraction, and timezone handling.
