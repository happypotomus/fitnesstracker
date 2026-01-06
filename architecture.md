# FitnessTracker - Architecture Documentation

## App Overview

Voice-first iOS fitness tracking app with OpenAI GPT integration for natural language workout logging and querying.

**Primary Use Case**: User speaks workout description ("I did 3 sets of bench press at 185 pounds, RPE 7") → AI parses into structured data → User reviews/edits → Saves to local CoreData.

**Key Features**:
- Voice-based workout logging using Apple Speech Recognition
- AI-powered workout parsing (OpenAI GPT-4o-mini)
- Inline editing of parsed workouts before saving
- Template system with voice and UI-based selection
- Template editing and management
- AI-powered workout history chat with conversation memory
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
- **CoreData Entities**: `Workout`, `Exercise` (managed objects)
- **Swift Structs**: `WorkoutSession`, `WorkoutExercise` (clean data transfer objects)
- **Chat Models**: `ChatMessage`, `ConversationContext` (for workout history queries)
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
| name | String | Yes | Template name (null for regular workouts) |
| exercises | Relationship | No | → [Exercise] with cascade delete |

#### Exercise Entity
| Attribute | Type | Optional | Notes |
|-----------|------|----------|-------|
| id | UUID | No | Primary key |
| name | String | No | Exercise name (e.g., "Bench Press") |
| sets | Int16 | No | Number of sets |
| reps | Int16 | No | Repetitions per set |
| weight | Double | No | Weight in pounds (0 if bodyweight) |
| rpe | Int16 | No | Rate of Perceived Exertion (0-10, 0=not set) |
| notes | String | Yes | Optional notes/comments |
| order | Int16 | No | Display order within workout |
| workout | Relationship | No | ← Workout (inverse) |

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
    var name: String?  // Template name (if applicable)
    var exercises: [WorkoutExercise]
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
- Templates are Workout entities with a `name` field set
- Regular workouts have `name = nil`
- Repository filters using name predicate: `name != nil` for templates
- Templates can be selected via UI picker or voice command ("use my push day template")

---

## File Structure

```
FitnessTracker/
├── FitnessTrackerApp.swift          # App entry point
│
├── Models/
│   ├── FitnessTracker.xcdatamodeld  # CoreData schema
│   ├── Workout+Extensions.swift     # CoreData helpers
│   ├── WorkoutModel.swift           # Swift structs (WorkoutSession, WorkoutExercise)
│   ├── ChatMessage.swift            # Chat message model
│   └── ConversationContext.swift    # Conversation history management
│
├── Views/
│   ├── RootView.swift               # Router: checks API key → HomeView or APIKeyInputView
│   ├── HomeView.swift               # Main screen: "Log New Workout" + "Review Workouts" buttons
│   ├── APIKeyInputView.swift        # First-run: secure API key input
│   ├── LogWorkoutView.swift         # Voice recording → AI parsing → display results
│   ├── WorkoutConfirmationView.swift # Edit parsed workout + save + template prompt
│   ├── TemplatePickerView.swift     # Select and edit templates
│   ├── TemplateEditView.swift       # Edit template name and exercises
│   ├── ReviewWorkoutsView.swift     # Chat interface for querying workout history
│   └── Components/
│       ├── VoiceRecordButton.swift  # Reusable voice recording UI with pulsing animation
│       ├── ChatBubbleView.swift     # User (blue) and AI (gray) message bubbles
│       ├── ExampleQuestionsView.swift # Horizontal scrolling question chips
│       ├── ChatInputView.swift      # Text field + voice button + send button
│       ├── VoiceInputSheet.swift    # Sheet for voice input in chat
│       └── TypingIndicatorView.swift # Animated typing indicator
│
├── ViewModels/
│   ├── LogWorkoutViewModel.swift         # State for workout logging flow
│   ├── WorkoutConfirmationViewModel.swift # State for editing/validation/saving
│   ├── TemplateEditViewModel.swift       # State for template editing
│   └── ReviewWorkoutsViewModel.swift     # State for chat interface
│
├── Services/
│   ├── PersistenceController.swift  # CoreData stack (singleton)
│   ├── WorkoutRepository.swift      # Data access layer (CRUD + templates)
│   ├── KeychainManager.swift        # Secure API key storage
│   ├── OpenAIService.swift          # API integration (parsing + querying)
│   └── SpeechRecognizer.swift       # Voice recognition wrapper
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

### 🔲 Phase 8: Polish & Edge Cases
- **Chunk 8.1**: Error handling improvements
- **Chunk 8.2**: Onboarding experience polish
- **Chunk 8.3**: UI polish + accessibility (VoiceOver, Dark Mode)
- **Chunk 8.4**: Performance optimization
- **Chunk 8.5**: Final testing & bug fixes

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
- Filters templates (name != nil) vs regular workouts (name == nil)
- Handles all CoreData save operations

### OpenAIService
**Methods**:
- `parseWorkoutText(_ text: String, previousWorkout: WorkoutSession?, availableTemplates: [WorkoutSession]) async throws -> WorkoutSession`
- `queryWorkoutHistory(_ question: String, context: [WorkoutSession]) async throws -> String`
- `queryWorkoutHistoryWithContext(_ question: String, workouts: [WorkoutSession], conversationContext: ConversationContext) async throws -> String`

**Configuration**:
- Model: `gpt-4o-mini`
- Uses structured JSON output mode for reliable parsing
- Error handling with custom `OpenAIError` enum
- Response limit: 500 tokens for chat queries

**Prompt Engineering**:
- Workout parsing: Converts natural language → JSON
- Supports "same as last time" by passing previous workout
- Supports template matching and modifications ("use push day but add 5 pounds")
- Query answering: Analyzes workout data with conversation context
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

**Last Completed**: Phase 7 - Review Workouts Chat Feature

**Fully Functional**:
- Complete voice-to-save workout logging
- Template system with UI and voice selection
- Template editing and management
- AI-powered chat for workout history queries
- Conversation memory and follow-up questions

**Production Ready Features**:
- Voice recording and transcription
- AI workout parsing with template support
- Inline editing of all workout fields
- Template creation, editing, and reuse
- Chat-based workout history analysis
- Conversation context for natural follow-ups

**Next Up**: Phase 8 - Polish & Edge Cases
- Error handling improvements
- Onboarding experience polish
- Accessibility support (VoiceOver, Dynamic Type)
- Performance optimization
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
- Settings screen (API key management, preferences, data export)
- Export workout data (CSV/JSON)
- Bulk edit/delete past workouts
- Calendar view of workout history
- Charts and visualizations (progress graphs, volume tracking)
- Apple Health integration
- Widget support
- Share workouts with others
- Workout reminders and scheduling
- Exercise library with form videos
- Custom AI prompt editing

---

**Last Updated**: Phase 7 Complete - Chat Feature with Conversation Memory

**App Status**: Feature-complete MVP ready for TestFlight beta testing
