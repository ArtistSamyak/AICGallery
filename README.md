# AICGallery: Art Institute of Chicago

This application is a sample iOS project demonstrating modern app development practices. It leverages **SwiftUI**, **Swift Concurrency**, and **SwiftData** within a **Clean Architecture + MVVM** design pattern, ensuring a robust, maintainable, and scalable codebase.

---

### Highlights

* **Modern UI:(like Pinterest)** Features a responsive lazy multi-column grid, smooth scrolling, subtle image fade-in effects, and a detailed image view.
* **Caching:** Implements per-page caching in **SwiftData** with a **5-minute TTL (Time-to-Live)**. If the cache is fresh, no network call is made.
* **Resilience:** The app is designed to handle network interruptions gracefully:
    * Displays a clear offline banner.
    * Any page fetch attempted while offline is added to a **"parked requests" queue**.
    * On reconnect, the queue is drained and the UI is automatically updated.
    * Provides user-friendly error messages.
* **Efficient Pagination:** Uses a "load as you scroll" (Pinterest-style) approach to fetch only the **current and next pages**, avoiding over-fetching.
* **Accessibility:** Supports **Dynamic Type**, **VoiceOver labels**, and **light/dark mode**.
* **Testing:** Includes a focused **Swift Testing** suite with unit tests for the `Store`, `Repository` (TTL/offline/parking), `ViewModel` (errors & events), and API URL building.

---

### Screenshots

<img width="200" alt="Simulator Screenshot - iPhone 16 Pro - 2025-09-08 at 01 23 31" src="https://github.com/user-attachments/assets/aca3931c-f905-48b2-8526-4fc8637779bc" />
<img width="580" alt="Simulator Screenshot - iPad Pro 13-inch (M4) - 2025-09-08 at 01 25 35" src="https://github.com/user-attachments/assets/14d1fd71-fc8b-4444-af00-7287fdd7bfb3" />




---

### Architecture

The codebase follows **Clean Architecture + MVVM** to provide a clear separation of concerns, making the app easier to manage, test, and extend.
<pre><code>
+-------------------+        +--------------------------+
|   SwiftUI Views   |  --->  |   GalleryViewModel       |
| (Grid / Detail)   |        |  (UI state + intents)    |
+---------+---------+        +-----------+--------------+
          |                               |
          v                               v
    +-----------+                  +--------------+
    | Use Cases |                  |  Event Bus   |
    | (Domain)  |                  | ArtworkEvent |
    +-----+-----+                  +--------------+
          |                                 ^
          v                                 |
   +-------------+     persists/reads   +---+-------------------+
   | Repository  +---------------------> | SwiftData Store      |
   | (TTL logic, |                       | (ArtworkRecord,      |
   | parking)    | <------------------+  |  PageRecord)         |
   +------+------+   page updates     |  +----------------------+
          |                            |
          v                            |
     +---------+                       |
     |  API    |  (Art Institute)      |
     +---------+                       |
          ^                            |
          | connectivity               |
     +----+----------------------------+
     | NetworkMonitor (NWPathMonitor)  |
     +---------------------------------+
</code></pre>

#### Layers & Responsibilities
* **Presentation (SwiftUI + MVVM)**
GalleryView, ArtworkDetailView, ArtworkGrid → declarative UI only.
GalleryViewModel → orchestrates loading current/next page, handles offline banner & errors.
*	**Domain (Use Cases + Entities + Policies)**
GetArtworksPageUseCase, RefreshParkedRequestsUseCase, Artwork, Page<T>, CachePolicy, DomainError.
* **Data (Repository + Store + API + Infra)**
ArtworkRepository (TTL guard, online path, offline “park & serve cache”),
ArtworkStore (SwiftData read/write, per-page refreshedAt),
ArtAPIClient (search endpoint + IIIF URL builders),
ParkedRequestQueue (actor), ArtworkEventBus (actor), NetworkMonitor (NWPathMonitor wrapper).

---

#### Caching & TTL
*	Per-page TTL is 5 minutes (CachePolicy(pageTTL: 300)).
*	TTL is enforced in the repository using PageRecord.refreshedAt.
*	If TTL is fresh, repo returns cache and skips network.
*	If TTL is stale:
  *	Online: fetch → upsert → emit .pageUpdated.
  *	Offline: park the page request and serve cache (or throw .offlineNoCache).
*   Bumped up URLCache size for image cache used by AsyncImage.

---

#### UI / UX Details (Pinterest)
*	Lazy grid (ArtworkGrid) with dynamic columns based on available width.
*	Each cell shows a thumbnail (IIIF) and a multi-line title below it.
*	Subtle fade-in for loaded images and clean placeholders while loading.
*	Detail view uses a larger IIIF URL

---

#### Tests (Swift Testing)
*	Store: round-trip upsert → fetch → meta → TTL timestamp.
*	Repository:
	*	TTL prevents network call when fresh.
	*	Offline + no cache → .offlineNoCache.
	*	Parked requests drain on reconnect and emit .pageUpdated.
*	ViewModel: error flow (offline banner, clearError), event-triggered reload.
*	API Client: IIIF URL builder sanity.

---

#### Choose a different artist

Edit AICGalleryApp.swift:
<code><pre>
artistID: 34946, // ← change this to any ArtIC artist_id
</code></pre>

---

#### What I’d do next (nice-to-haves)
* Byte-level image cache with explicit 5-minute expiry (URLCache configuration or SDWebImageSwiftUI) for more deterministic thumbnail reuse.
* Allow users to select any artist to see their entire collection.
* Minor refactoring








