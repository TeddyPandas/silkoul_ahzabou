# Silkoul Ahzabou Tidiani

A multi-platform application designed for the Tijaniyya community to facilitate collective Zikr practice through shared campaigns and progress tracking.

## Architecture

The project consists of a Flutter-based mobile application and a Supabase-powered backend environment, ensuring real-time synchronization and secure data management.

### Technical Stack

- **Mobile**: Flutter (Dart)
- **State Management**: Provider
- **Backend**: Supabase (PostgreSQL, Authentication, Real-time)
- **Authentication**: Email/Password, Google OAuth, Phone
- **Logic**: Node.js (Backend services)

## Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Node.js & npm (for backend operations)
- Supabase account and configured project

## Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd silkoul_ahzabou
   ```

2. **Backend Configuration:**
   - Create a project on Supabase.
   - Execute the initialization scripts found in `supabase/migrations/`.
   - Update your project credentials in `lib/config/supabase_config.dart`.

3. **Frontend Setup:**
   - Install dependencies:
     ```bash
     flutter pub get
     ```
   - Build and run:
     ```bash
     flutter run
     ```

## Core Features

- **Auth Management**: Secure login via multiple providers and Guest Mode support.
- **Zikr Campaigns**: Create and manage collective spiritual objectives with granular task definitions.
- **Participation Flow**: Scalable system for subscribing to campaigns and committing to specific goals.
- **Progress Tracking**: Real-time reporting of individual and collective progress.
- **Engagement System**: Leveling and points based on participation frequency and accuracy.

## Project Structure

```text
silkoul_ahzabou/
├── lib/
│   ├── config/     # Environment and app configuration
│   ├── models/     # Data transfer objects
│   ├── providers/  # Business logic and state management
│   ├── services/   # Infrastructure and API integration
│   ├── screens/    # Presentation layer
│   └── widgets/    # Component library
├── backend/        # Node.js services and infrastructure
├── supabase/       # SQL migrations and security policies
└── assets/         # Static resources
```

## Security

The application implements Row Level Security (RLS) on all database tables. Sensitive operations are executed via verified RPC functions to ensure data integrity and restricted access.

## License

This project is licensed under the MIT License.
