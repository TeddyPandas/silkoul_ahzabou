# Core Features of AhzabTidiani Application

This document outlines the core features of the AhzabTidiani application, derived from the "agents" described in `agents.md` and the observed project architecture. The application primarily focuses on managing spiritual practices, particularly "zikr" campaigns, and fostering a community around them.

## 1. User Authentication and Profile Management

*   **Authentication:** Secure user login (e.g., via Gmail as mentioned in `agents.md`).
    *   **Workflow:** User initiates login -> Application redirects to authentication provider (e.g., Google) -> User authenticates -> Authentication provider redirects back to app with token -> App verifies token and logs in user.
*   **Profile Management:** Users can manage their personal information (name, email, username, initiatic chain).
    *   **Workflow:** User navigates to profile screen -> User edits fields -> App validates input -> App updates user data in the database.
*   **Dashboard:** A personalized dashboard displaying joined and created campaigns, personal task progress, and achievements.
    *   **Workflow:** User logs in -> App fetches user-specific campaign and task data from the database -> App displays aggregated information and progress on the dashboard.
*   **Statistics & Milestones:** Visual representation of user progress, streaks, and spiritual accomplishments.
    *   **Workflow:** App analyzes user's historical task completion and campaign participation data -> App generates visual statistics and identifies milestones -> App displays these on the dashboard or a dedicated statistics screen.

## 2. Campaign Management

This is the central feature of the application, enabling users to create, join, and participate in spiritual campaigns.

*   **Campaign Creation:**
    *   **Workflow:** User navigates to "Create Campaign" screen -> User fills out campaign details (name, description, dates, tasks, category, public/private status, access code if private, weekly/one-time) -> App validates input -> App sends campaign data to the `CampaignService` -> `CampaignService` stores the new campaign in the database.
*   **Campaign Discovery:** Users can browse and discover public campaigns.
    *   **Workflow:** User navigates to "Discover Campaigns" screen -> App fetches public campaigns from the `CampaignService` -> App displays a list of campaigns, potentially with filtering and sorting options.
*   **Campaign Participation:**
    *   **Workflow:** User selects a campaign -> User views campaign details -> User chooses to join -> If private, user enters access code -> App sends join request to `UserCampaignService` -> `UserCampaignService` records user's participation in the database.
    *   **Task Assignment:** User can assign themselves a portion of a task (e.g., "I'll do 1000").
        *   **Workflow:** During campaign joining or from campaign details, user selects tasks and specifies quantities -> App validates quantities against remaining task numbers -> App updates `UserCampaignTaskService` and `CampaignService` to reflect assigned quantities and reduced remaining numbers.
    *   **Real-time Tracking:** Real-time tracking of collective progress for tasks within a campaign.
        *   **Workflow:** As users contribute to tasks, the `CampaignService` updates the remaining numbers -> UI components listening to campaign data (via providers) automatically refresh to show updated progress.
*   **Campaign Updates:** Campaigns can be updated (e.g., editing details, tasks).
    *   **Workflow:** Campaign creator navigates to "Edit Campaign" screen -> Creator modifies campaign details or tasks -> App validates input -> App sends updated campaign data to `CampaignService` -> `CampaignService` updates the campaign in the database.
*   **Task Contribution:** Users can contribute to tasks within joined campaigns, marking their progress.
    *   **Workflow:** User selects a task within a joined campaign -> User enters the amount contributed -> App validates input (e.g., not exceeding remaining) -> App sends contribution to `UserCampaignTaskService` -> `UserCampaignTaskService` updates user's completed quantity and `CampaignService` updates the global remaining number for the task.

## 3. Task Management

Tasks are integral to campaigns, representing specific spiritual practices.

*   **Task Definition:** Tasks have a name, total target number, remaining number, and a daily goal.
    *   **Workflow:** Defined during campaign creation or editing.
*   **Personal Task Tracking:** Users track their individual progress on tasks within campaigns.
    *   **Workflow:** User views their dashboard or campaign details -> App fetches `UserCampaignTask` data -> App displays user's subscribed quantity, completed quantity, and remaining for each task.
*   **Bulk Task Management:** Tools for efficiently adding or managing multiple tasks for a campaign.
    *   **Workflow:** During campaign creation/editing, user accesses a bulk task management interface -> User adds, edits, or removes multiple tasks simultaneously -> App updates the campaign's task list.

## 4. Geolocation Features (Wazifa Places)

Connecting the digital experience with physical locations for spiritual practice.

*   **Place Database:** A database of spiritual practice locations (mosques, centers).
    *   **Workflow:** App fetches place data from `WazifaPlaceProvider` (which interacts with a service/database).
*   **Location Search:** Users can search for nearby places.
    *   **Workflow:** User grants location permission -> App uses device's geolocation to get current location -> App queries `WazifaPlaceProvider` for nearby places -> App displays results on a map or list.
*   **User Contributions:** Users can add and describe new spiritual locations.
    *   **Workflow:** User navigates to "Add Wazifa Place" screen -> User enters place details (name, address, description) -> App validates input -> App sends new place data to `WazifaPlaceProvider` -> `WazifaPlaceProvider` stores the new place in the database.
*   **Event Directory:** A directory of local religious events, filterable by location.
    *   **Workflow:** User accesses event directory -> App fetches event data (potentially linked to places) -> User can filter by location -> App displays relevant events.

## 5. Content and Enrichment

Providing spiritual resources and personalization.

*   **Zikr/Doua Library:** A library of supplications and remembrances with texts, translations, and sources.
    *   **Workflow:** User navigates to content library -> App fetches Zikr/Doua data from `ContentAgent` (conceptual) -> App displays content, allowing search and filtering.
*   **Guided Audio Sessions:** Offering guided audio sessions (e.g., Hadara, Wazifa).
    *   **Workflow:** User selects an audio session -> App streams or plays audio content.
*   **Intention (Niyyah) Functionality:** Allowing users to personalize their spiritual intentions.
    *   **Workflow:** User sets a personal intention, which might be linked to a campaign or task -> App stores and displays this intention.

## 6. Silsila Management

Managing spiritual lineages and connections.

*   **Silsila Display:** View and explore different spiritual lineages.
    *   **Workflow:** User navigates to the Silsila screen -> App fetches Silsila data from `SilsilaProvider` -> App displays the lineage in a clear, hierarchical or graphical format.
*   **Silsila Details:** Access detailed information about each individual in a Silsila.
    *   **Workflow:** User selects an individual in a Silsila -> App displays biographical information, teachings, and associated practices.

## 7. Notifications and Reminders

Keeping users engaged and informed.

*   **Push Notifications:** Reminders for campaign deadlines, social interactions, and personalized alerts.
    *   **Workflow:** Backend service or `NotificationService` triggers a push notification based on predefined rules or user settings -> Device receives and displays notification.
*   **Campaign Reminders:** Specific reminders related to campaign tasks and progress.
    *   **Workflow:** User sets a reminder for a campaign or task -> `CampaignReminderService` schedules a local or push notification for the specified time/event.

## 8. Social Interaction (Limited Implementation)

While `agents.md` describes a "Social Agent," the current code shows limited direct implementation of social features beyond sharing.

*   **Sharing:** Ability to share campaign details (e.g., via QR code).
    *   **Workflow:** User on campaign details screen taps share icon -> `SharingService` generates shareable content (e.g., QR code, link) -> Device's native share sheet appears, allowing user to choose sharing method.
*   *(Potential future features based on `agents.md`):* Follow system, group creation, in-campaign comments, leaderboards, social media sharing of accomplishments.

## 9. Technical Integrations

Underlying technical services supporting the application.

*   **Database Persistence:** Storage and management of all user and application data (likely Supabase, given project structure).
    *   **Workflow:** All service layers (`CampaignService`, `UserCampaignService`, etc.) interact with the underlying database (e.g., Supabase client) for CRUD operations.
*   **API Integrations:** Connection to external services (e.g., for prayer times, though not explicitly implemented yet).
    *   **Workflow:** A dedicated service (e.g., `PrayerTimeService`) would make HTTP requests to an external API, parse the response, and provide data to the app.
*   **Offline Mode:** Data synchronization when connectivity is restored.
    *   **Workflow:** App stores critical data locally when offline -> When online, app synchronizes local changes with the remote database and fetches updates.
*   **Security & Moderation:** Policies and mechanisms for a safe environment.
    *   **Workflow:** Implemented at various layers: authentication, data validation, access control rules in the database, and potentially backend moderation tools.
 

@MarkazTijani
