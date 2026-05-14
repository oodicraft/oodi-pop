# Project Name
Oodi Pop

# Project Conventions

- Frontend: SwiftUI
- Backend: Swift
- SQLite/json

# UX Principles

- Offline-first

## Motion Rules

Motion is part of the core UX, not decoration.

Default to using subtle SwiftUI animations for:
- state changes
- view transitions
- loading updates
- button interactions
- list updates

Prefer:
- withAnimation
- spring animations
- matchedGeometryEffect
- contentTransition

Avoid:
- abrupt UI changes
- overly slow or flashy animations

Animations should make the interface feel responsive, natural, and alive.