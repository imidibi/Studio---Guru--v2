# Studio Guru 2.0
## Integrated Studio + Session Management Architecture

**Purpose:**  
This document defines the proposed architecture for expanding Studio Guru to incorporate the session-management capabilities developed in Seshun, while preserving Studio Guru’s existing studio, device, connection, signal-flow, session snapshot, and gear-management functionality.

The objective is to make Studio Guru a unified operational system for recording studios, producers, engineers, musicians, and creators.

---

# 1. Product Vision

Studio Guru should evolve from:

> “How is my studio connected?”

to:

> “How is my studio set up, what happened in every session, who did what, and how did we record it?”

The integrated product should manage both the **physical studio environment** and the **creative/session history** associated with that studio.

The central concept is:

**A Session is a first-class business object that references a Studio.**

Sessions should not simply be saved versions of the studio canvas. Instead, a Session should represent an actual dated studio event containing:

- Studio used
- Project
- Artist/client
- Participants
- Session roles
- Songs worked on
- Performance credits
- Writing/creative credits
- Gear used
- Signal-flow/setup snapshot
- Notes
- Files
- Photos
- Session history

---

# 2. Core Data Domains

Studio Guru 2.0 should be organized around these primary domains:

1. Studio
2. Session
3. Project
4. Person
5. Work / Song
6. Equipment
7. Configuration Snapshot
8. Contributions / Credits
9. Files / Assets
10. Templates

These entities should reference one another through IDs/relationships rather than duplicate data unnecessarily.

---

# 3. Studio

A Studio represents the relatively persistent physical environment.

## Studio Entity

Suggested properties:

```swift
Studio
- id: UUID
- name: String
- location: String?
- notes: String?
- createdAt: Date
- modifiedAt: Date
```

Relationships:

```text
Studio
 ├── Rooms
 ├── Devices
 ├── Connections
 ├── Gear
 ├── Sessions
 ├── Documents
 └── Photos
```

A Studio may contain:

- Rooms
- Permanently installed equipment
- Portable/stored equipment
- Patch bays
- Signal connections
- Documents/manuals
- Images
- Saved setup presets
- Sessions

---

# 4. Equipment Model

Studio Guru should explicitly distinguish between:

## Installed Equipment

Equipment that normally forms part of the studio’s permanent configuration.

Examples:

- Audio interfaces
- Consoles
- Computers
- Studio monitors
- Patch bays
- Permanently racked processors
- Network devices

Suggested property:

```swift
storageStatus: EquipmentStorageStatus
```

Possible enum:

```swift
enum EquipmentStorageStatus: String, Codable {
    case installed
    case gearLocker
    case external
}
```

---

## Gear Locker

Portable equipment that may be pulled into a session.

Examples:

- Microphones
- Guitar amplifiers
- Instruments
- Effects pedals
- Portable preamps
- DI boxes
- Stands
- Headphones
- Portable outboard equipment

The UI term should remain:

**Gear Locker**

This provides a broad studio-industry term without being limited to microphones.

---

# 5. Session

Session becomes the central operational record.

## Session Entity

Suggested properties:

```swift
Session
- id: UUID
- studioID: UUID
- projectID: UUID?
- name: String
- sessionDate: Date
- startTime: Date?
- endTime: Date?
- status: SessionStatus
- sessionType: SessionType
- artistName: String?
- clientName: String?
- notes: String?
- createdAt: Date
- modifiedAt: Date
```

Recommended enums:

```swift
enum SessionStatus: String, Codable {
    case planned
    case active
    case completed
    case cancelled
}
```

```swift
enum SessionType: String, Codable {
    case tracking
    case overdub
    case songwriting
    case rehearsal
    case editing
    case mixing
    case mastering
    case podcast
    case liveRecording
    case other
}
```

Relationships:

```text
Session
 ├── Studio
 ├── Project?
 ├── Participants
 ├── Works
 ├── Performances
 ├── Creative Contributions
 ├── Equipment Usage
 ├── Configuration Snapshot
 ├── Notes
 ├── Files
 └── Photos
```

---

# 6. Important Architectural Rule: Session Snapshot

A Session must **not** simply reference the Studio’s current signal-flow state.

When a session is created or finalized, Studio Guru should preserve a frozen snapshot of the setup used for that session.

This prevents historical sessions from changing when the studio is later rewired.

Example:

```text
August 11, 2026 — Vocal Session

U67
 ↓
Neve 1073
 ↓
1176
 ↓
Apollo Input 4
```

If the studio setup changes in October, the August session must remain historically accurate.

---

# 7. Configuration Snapshot

Recommended design:

```swift
SessionConfigurationSnapshot
- id: UUID
- sessionID: UUID
- createdAt: Date
- snapshotVersion: Int
```

The snapshot should include immutable copies or serialized representations of:

- Devices used
- Device positions
- Connections
- Connection labels
- Port mappings
- Gear added to the session
- Device-specific notes
- Optional settings

Possible implementation options:

### Preferred

Create dedicated snapshot entities:

```text
SessionConfigurationSnapshot
 ├── SnapshotDevices
 └── SnapshotConnections
```

This allows historical browsing and querying.

### Alternative

Serialize the complete configuration into Codable data:

```swift
snapshotData: Data
```

This is simpler initially but less queryable.

For long-term maintainability, dedicated snapshot entities are preferable.

---

# 8. Project

Projects group multiple sessions and songs.

Examples:

- Sarah Jones — New Album
- EP Production — The Red Cars
- Podcast Season 2
- Film Score — Project Orion

## Project Entity

```swift
Project
- id: UUID
- name: String
- artistName: String?
- clientName: String?
- projectType: ProjectType?
- status: ProjectStatus
- startDate: Date?
- endDate: Date?
- notes: String?
- createdAt: Date
- modifiedAt: Date
```

Relationships:

```text
Project
 ├── Sessions
 ├── Works
 ├── People
 ├── Files
 └── Notes
```

Projects should be optional.

A user must still be able to create a standalone Session without first creating a Project.

---

# 9. Person

Do not store participant names directly inside Sessions.

Create one reusable People directory.

## Person Entity

```swift
Person
- id: UUID
- firstName: String
- lastName: String
- displayName: String
- company: String?
- email: String?
- phone: String?
- website: String?
- notes: String?
- photoData: Data?
- createdAt: Date
- modifiedAt: Date
```

Optional additional properties:

```swift
- defaultRole: String?
- instruments: [String]
- socialLinks
```

---

# 10. Session Participant

A Person participates in a Session through a join entity.

## SessionParticipant

```swift
SessionParticipant
- id: UUID
- sessionID: UUID
- personID: UUID
- role: String
- notes: String?
- arrivalTime: Date?
- departureTime: Date?
```

Examples of session roles:

- Producer
- Recording Engineer
- Assistant Engineer
- Studio Technician
- Artist
- Musician
- Composer
- Photographer
- Guest

A person can have multiple roles.

---

# 11. Work / Song

Use a generic internal entity called **Work**, while the UI may normally use **Song**.

This allows future support for:

- Songs
- Instrumentals
- Compositions
- Podcast episodes
- Film cues
- Voiceover pieces

## Work Entity

```swift
Work
- id: UUID
- projectID: UUID?
- title: String
- versionName: String?
- artistName: String?
- bpm: Double?
- key: String?
- timeSignature: String?
- isrc: String?
- iswc: String?
- proWorkID: String?
- notes: String?
- createdAt: Date
- modifiedAt: Date
```

Relationships:

```text
Work
 ├── Sessions
 ├── Performances
 ├── Contributions
 └── Files
```

---

# 12. Session–Work Relationship

A Work may appear in many Sessions.

A Session may contain many Works.

Use an explicit join entity.

## SessionWork

```swift
SessionWork
- id: UUID
- sessionID: UUID
- workID: UUID
- notes: String?
- sequenceNumber: Int?
```

This makes it possible to answer:

- Which songs were worked on during this Session?
- Which Sessions contributed to this Song?

---

# 13. Performance Credits

A performance must connect:

- Session
- Work
- Person
- Instrument / performance role

## Performance Entity

```swift
Performance
- id: UUID
- sessionID: UUID
- workID: UUID
- personID: UUID
- instrument: String?
- performanceRole: String?
- notes: String?
```

Examples:

```text
Falling Away
- Sarah Jones — Lead Vocal
- Ian Miller — Electric Guitar
- Mike Adams — Drums
```

Another song from the same session may have different roles.

This is why instrument and role should not be stored only against the Person.

---

# 14. Creative Contributions

Creative credits should be separate from performance credits.

## Contribution Entity

```swift
Contribution
- id: UUID
- workID: UUID
- personID: UUID
- contributionType: ContributionType
- percentage: Double?
- notes: String?
```

Recommended enum:

```swift
enum ContributionType: String, Codable {
    case songwriter
    case composer
    case lyricist
    case arranger
    case producer
    case coProducer
    case other
}
```

This architecture can later support:

- Credits
- Split sheets
- Metadata exports
- Publishing data
- PRO information

---

# 15. Separate Three Types of Roles

The data model should deliberately distinguish:

## Session Roles

Examples:

- Producer
- Engineer
- Assistant Engineer
- Studio Technician

## Performance Roles

Examples:

- Guitar
- Bass
- Drums
- Piano
- Lead Vocal
- Backing Vocal
- Percussion

## Creative Contributions

Examples:

- Songwriter
- Composer
- Lyricist
- Arranger
- Producer

A single Person may appear in all three categories.

---

# 16. Session Equipment Usage

Studio Guru should record equipment actually used during a Session.

## SessionEquipment

```swift
SessionEquipment
- id: UUID
- sessionID: UUID
- equipmentID: UUID
- workID: UUID?
- personID: UUID?
- purpose: String?
- settings: String?
- notes: String?
```

This creates powerful historical queries such as:

> What microphone did we use on Sarah’s vocal last time?

or:

> What signal chain did we use on John’s guitar?

Example result:

```text
Sarah Jones — Lead Vocal
March 14

Neumann U67
→ Neve 1073
→ 1176
→ Apollo x8 Input 4

Notes:
1073 Gain: 45 dB
1176 Ratio: 4:1
```

This should become a major Studio Guru differentiator.

---

# 17. Session Creation Workflow

Recommended UX:

```text
New Session

Studio:
[Studio A]

Project:
[Sarah Jones — New Album]

Date:
[Today]

Session Type:
[Tracking]
```

Then:

```text
START FROM

○ Current Studio Setup
○ Studio Default
○ Previous Session
○ Session Template
○ Blank Setup
```

If the user chooses Previous Session:

```text
Previous Session:
Sarah Jones — Vocal Tracking — July 19
```

Studio Guru should copy:

- Device layout
- Connections
- Session gear
- Relevant setup notes

into the new Session.

The copy becomes independent historical data.

---

# 18. Session Templates

Create reusable templates for common workflows.

Examples:

- Full Band Tracking
- Drum Tracking
- Vocal Session
- Guitar Overdub
- Podcast
- Mixing Session
- Live Recording

## SessionTemplate

```swift
SessionTemplate
- id: UUID
- studioID: UUID?
- name: String
- sessionType: SessionType
- notes: String?
- createdAt: Date
```

Template contents may include:

- Default equipment
- Studio configuration
- Standard participant roles
- Checklist
- Default notes
- Connection layout

---

# 19. Recommended Navigation

Suggested main navigation structure:

```text
STUDIO GURU

Studios
Projects
Sessions
People
Gear
```

Optional future sections:

```text
Files
Reports
Templates
Approvals
```

---

# 20. Studio Screen

Each Studio should expose:

```text
Studio A

Overview
Current Setup
Gear Locker
Sessions
Documents
Photos
```

---

# 21. Session Screen

The Session screen should become the heart of Studio Guru 2.0.

Suggested layout:

```text
SARAH JONES — VOCAL SESSION

Studio A
August 11, 2026

Overview
People
Songs
Setup
Gear
Notes
Files
```

---

## Overview

Display:

- Session name
- Date/time
- Studio
- Project
- Artist/client
- Session type
- Status
- Summary notes

---

## People

Display:

- Everyone attending
- Session roles
- Contact information
- Notes

Example:

```text
Sarah Jones
Artist / Vocal

Ian Miller
Producer / Guitar

Mike Adams
Engineer
```

---

## Songs

Display Works associated with the Session.

Selecting a Work should show:

- Performers
- Instruments
- Writers
- Producers
- Creative contributions
- Split percentages
- Notes

---

## Setup

Display the Studio Guru signal-flow canvas for the Session snapshot.

This should be visually distinct from the Studio’s current live/default setup.

Suggested banner:

```text
SESSION SETUP
Snapshot saved August 11, 2026
```

---

## Gear

Show:

- Installed studio equipment used
- Gear Locker items pulled into the Session
- External/guest gear
- Equipment notes/settings

---

## Notes

Support:

- Session-level notes
- Song notes
- Person notes
- Equipment notes
- Engineering notes

---

## Files

Support attachments such as:

- Photos
- Lyrics
- Session sheets
- Cue sheets
- DAW notes
- Reference mixes
- PDFs
- Technical documents

---

# 22. Assets / Deliverables

Design the schema now for future integration with Approvl.

## Asset Entity

```swift
Asset
- id: UUID
- sessionID: UUID?
- projectID: UUID?
- workID: UUID?
- assetType: AssetType
- name: String
- version: String?
- fileURL: String?
- createdAt: Date
```

Possible asset types:

```swift
enum AssetType: String, Codable {
    case recording
    case mix
    case master
    case stem
    case reference
    case document
    case other
}
```

This creates a future workflow:

```text
Studio Guru Session
        ↓
Recording / Mix
        ↓
Asset
        ↓
Approvl Review
```

Studio Guru and Approvl therefore do not need to merge immediately.

They can share an Asset model later.

---

# 23. Suggested Overall Entity Graph

```text
Studio
 ├── Rooms
 ├── Devices
 ├── Connections
 ├── Gear
 └── Sessions
       ├── ConfigurationSnapshot
       ├── Participants
       ├── SessionWorks
       ├── Performances
       ├── SessionEquipment
       ├── Files
       └── Assets

Project
 ├── Sessions
 ├── Works
 ├── Files
 └── Assets

Person
 ├── SessionParticipants
 ├── Performances
 └── Contributions

Work
 ├── SessionWorks
 ├── Performances
 ├── Contributions
 ├── Files
 └── Assets
```

---

# 24. SwiftData Relationship Guidance

Avoid deeply nested ownership where possible.

For example, rather than:

```text
Studio owns Session
Session owns Person
```

prefer:

```text
Session.studioID
SessionParticipant.personID
SessionParticipant.sessionID
```

SwiftData object relationships can still be used for convenience, but IDs should remain stable and explicit where useful.

This makes:

- Sync
- Migration
- Export
- Import
- CloudKit
- Future Firestore integration

much easier.

---

# 25. Deletion Rules

Recommended behavior:

## Delete Studio

Do NOT automatically delete historical Sessions.

Options:

- Prevent Studio deletion while Sessions exist
- Allow archive instead of delete
- Preserve Sessions with historical Studio snapshot/name

Preferred approach:

**Archive Studios rather than permanently deleting them.**

---

## Delete Person

Do not destroy historical credits.

Instead:

- Archive Person
- Preserve references from old Sessions and Works

---

## Delete Project

Sessions should remain.

Set:

```text
session.projectID = nil
```

or archive the Project.

---

## Delete Work

Warn if:

- Performances exist
- Credits exist
- Sessions reference the Work

Prefer archive over destructive deletion.

---

# 26. Archive Strategy

Add:

```swift
isArchived: Bool
```

to major entities:

- Studio
- Project
- Person
- Work
- Equipment

This protects historical data.

Archived entities should not normally appear in selection lists but should remain accessible from historical Sessions.

---

# 27. Existing Studio Guru Migration

Existing Studio Guru data should migrate without requiring users to recreate anything.

Current Studio Guru objects should map approximately as follows:

```text
Existing Studio
    → Studio

Existing Device
    → Equipment / Device

Existing Connections
    → Connection

Existing Saved Session / Studio Design
    → Session Configuration Snapshot
```

Existing saved Studio Guru “sessions” may need classification.

If they currently represent only saved studio configurations, migrate them as:

```text
Session
- sessionType = other
- name = existing saved name
- configurationSnapshot = existing saved design
```

or:

```text
SavedSetupPreset
```

depending on their current semantics.

Do not discard the original saved configuration.

---

# 28. Existing Seshun Migration

Map Seshun data roughly as:

```text
Seshun Contact
    → Person

Seshun Session
    → Session

Seshun Musician Assignment
    → Performance

Seshun Writer Credit
    → Contribution

Seshun Song
    → Work

Seshun Project
    → Project
```

During migration:

- Preserve UUIDs where possible
- Avoid duplicate People
- Preserve dates
- Preserve notes
- Preserve existing relationships

---

# 29. Duplicate Person Handling

When importing Seshun People into Studio Guru, use soft duplicate detection.

Possible matching:

```text
same email
OR
same normalized full name + phone
```

Never automatically merge ambiguous records.

Offer:

```text
Possible duplicate found:
Ian Miller

[Merge]
[Keep Separate]
```

---

# 30. Sync Strategy

Studio Guru currently uses iCloud / CloudKit.

The integrated Studio Guru should ideally use one consistent persistence strategy.

Recommended:

```text
SwiftData
+
CloudKit synchronization
```

for:

- Studios
- Sessions
- Projects
- People
- Works
- Credits
- Equipment
- Historical setups

Approvl can continue using Firestore independently.

Future integration can occur through:

```text
Asset ID
Project ID
User ID
```

rather than requiring Studio Guru to adopt Firestore immediately.

---

# 31. Offline Behavior

Studio Guru should remain fully usable offline.

Users in studios may not always have reliable connectivity.

All creation/editing should work locally.

Cloud synchronization should happen when available.

---

# 32. Search

Global search will become increasingly important.

Search should support:

- Studio
- Project
- Artist
- Person
- Song
- Equipment
- Session
- Date

Examples:

```text
"Sarah"
"U67"
"Neve"
"Falling Away"
"Mike Adams"
```

---

# 33. Historical Queries

The architecture should eventually enable natural user workflows such as:

```text
Show Sarah Jones sessions
```

```text
When did Mike last play drums here?
```

```text
What mic did we use for Sarah’s vocal?
```

```text
Show every song Ian played guitar on
```

```text
How was Falling Away recorded?
```

```text
Which sessions used the U67?
```

This historical intelligence is one of the strongest reasons to integrate Seshun with Studio Guru.

---

# 34. Dashboard Ideas

Future home dashboard:

```text
TODAY
Sarah Jones — Vocal Tracking
Studio A — 2:00 PM

UPCOMING
Red Cars — Drum Tracking
Thursday

RECENT
Sarah Jones — Guitar Overdubs
Yesterday

PROJECTS
Sarah Jones — New Album
8 Sessions

GEAR
3 items currently assigned to active sessions
```

---

# 35. Recommended MVP Scope

For the first integrated release, focus on:

1. People
2. Projects
3. Sessions
4. Songs / Works
5. Session Participants
6. Performance Credits
7. Creative Credits
8. Session Gear
9. Session Setup Snapshot
10. Session Notes
11. Existing Studio integration
12. Migration from existing Seshun data

Avoid initially expanding into:

- Billing
- Contracts
- Payroll
- Full royalty accounting
- Advanced rights management
- Approvl workflow
- Client portals

These can follow later.

---

# 36. Phase 2 Features

Possible follow-on features:

- Session templates
- Recall previous session
- Gear usage history
- Equipment settings history
- Split sheets
- Credit exports
- Session reports
- Contact export
- Calendaring
- Session reminders
- PDF session sheets
- Track sheets
- QR gear labels
- Project dashboards

---

# 37. Phase 3 / Platform Direction

Future Studio Guru ecosystem:

```text
Studio Guru
Studio operations + session history

        ↓

Assets / Mixes

        ↓

Approvl
Review + feedback + approval
```

This provides a coherent platform without forcing all functionality into one monolithic application immediately.

---

# 38. Product Positioning

The enhanced Studio Guru becomes:

> A studio operations and session memory system.

Potential positioning statement:

> Studio Guru documents your studio, your sessions, your people, your gear, and exactly how every recording was made.

Alternative:

> Know your studio. Remember every session.

The key competitive advantage is the connection between:

**People + Songs + Sessions + Gear + Signal Flow**

Most systems handle only one or two of these areas.

Studio Guru can connect all of them.

---

# 39. Architectural Principle Summary

The implementation should follow these principles:

1. Session is a first-class entity.
2. Every Session references a Studio.
3. Projects are optional.
4. People are reusable master records.
5. Songs/Works are reusable master records.
6. Session roles, performance roles, and creative credits are separate.
7. Historical signal flow is stored as an immutable Session snapshot.
8. Equipment use is recorded per Session.
9. Historical records should be archived, not destroyed.
10. The model should allow future Approvl integration through shared Assets.
11. The entire core application should remain usable offline.
12. Existing Studio Guru and Seshun data should migrate rather than be discarded.

---

# 40. Recommended Next Development Sequence

Suggested implementation order:

```text
1. Introduce Person
2. Introduce Project
3. Upgrade Session entity
4. Introduce Work
5. Add SessionParticipant
6. Add SessionWork
7. Add Performance
8. Add Contribution
9. Add SessionEquipment
10. Add SessionConfigurationSnapshot
11. Build new Session UI
12. Add Seshun data migration
13. Add Studio Guru legacy session migration
14. Add global search
15. Add session duplication / recall
16. Add templates
```

This sequence reduces migration risk and allows the combined architecture to be introduced incrementally.

---

# 41. Key User Workflow

A target real-world workflow should be:

```text
Producer opens Studio Guru

→ Selects New Session

→ Chooses Studio A

→ Chooses Sarah Jones — New Album

→ Chooses Vocal Tracking

→ Selects:
   "Start from Sarah’s previous vocal session"

→ Studio Guru restores:
   - signal flow
   - devices
   - selected gear
   - microphone
   - signal-chain notes

→ Producer adds session participants

→ Selects songs being worked on

→ Records performances / credits

→ Makes session notes

→ Saves Session

→ Studio Guru permanently records:
   WHO
   WHAT
   WHERE
   WHEN
   and HOW
```

That should be the design objective for Studio Guru 2.0.

---

# 42. Working Product Definition

**Studio Guru 2.0 is a studio operations, session documentation, and creative-credit management application that records the studio environment, participants, songs, equipment, signal paths, and historical setup of every recording session.**

