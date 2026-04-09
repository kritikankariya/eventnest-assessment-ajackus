# Code Review: Top 7 Issues

### 1. Mass Assignment Vulnerability (Security) - SEVERITY: Critical
**File/Line:** `app/controllers/api/v1/auth_controller.rb:36`
**Description:** The `register_params` method permits the `:role` parameter to be passed directly by the user. A malicious user can register themselves as an "admin" or "organizer" by simply including `"role": "admin"` in their JSON payload, bypassing role restrictions entirely.
**Recommended Fix:** Remove `:role` from the permitted parameters. Rely on the database default ("attendee") or handle role assignments securely on the backend.

### 2. Broken Access Control / IDOR (Security) - SEVERITY: Critical
**File/Line:** `app/controllers/api/v1/events_controller.rb` (Lines 66 & 75)
**Description:** The `update` and `destroy` methods find the event globally using `Event.find(params[:id])`. There is no check to ensure the `current_user` actually owns the event. Any authenticated user (even an attendee) can modify or delete any event on the platform.
**Recommended Fix:** Scope the query to the current user: `@event = current_user.events.find(params[:id])`.

### 3. SQL Injection (Security) - SEVERITY: Critical
**File/Line:** `app/controllers/api/v1/events_controller.rb:8`
**Description:** The search functionality directly interpolates user input into a SQL query string (`"title LIKE '%#{params[:search]}%'"`). A malicious user can pass a crafted SQL payload to expose database data or manipulate queries.
**Recommended Fix:** Use ActiveRecord's parameterized queries: `events.where("title ILIKE :search OR description ILIKE :search", search: "%#{params[:search]}%")`.

### 4. Race Condition in Ticket Reservation (Data Integrity) - SEVERITY: High
**File/Line:** `app/models/ticket_tier.rb:14`
**Description:** The `reserve_tickets!` method reads the available quantity and then updates it. If two users check out simultaneously for the last remaining ticket, both will pass the `if available_quantity >= count` check, leading to overselling.
**Recommended Fix:** Use database-level locking (optimistic or pessimistic) or an atomic update query like `TicketTier.update_counters`.

### 5. N+1 Query in Events Index (Performance) - SEVERITY: High
**File/Line:** `app/controllers/api/v1/events_controller.rb:21`
**Description:** When rendering the list of events, the code loops through each event and calls `event.user.name` and `event.ticket_tiers.map`. This triggers a new database query for the user and ticket tiers for *every single event* in the list.
**Recommended Fix:** Eager load the associations in the index query: `events = Event.published.upcoming.includes(:user, :ticket_tiers)`.

### 6. Blocking Thread with Sleep in Callback (Architecture) - SEVERITY: High
**File/Line:** `app/models/event.rb:23`
**Description:** The `geocode_venue` method uses `sleep(0.1)` inside a `before_save` callback to simulate an external API call. This blocks the main web thread for 100ms per save, severely limiting application throughput and making the web request slow.
**Recommended Fix:** Move geocoding and external API calls to an asynchronous Sidekiq background job rather than keeping them in an active record callback.

### 7. Missing Authorization for Event Creation (Architecture/Security) - SEVERITY: High
**File/Line:** `app/controllers/api/v1/events_controller.rb:56`
**Description:** Any authenticated user can hit the `POST /api/v1/events` endpoint to create an event. There is no check verifying that the user is actually an "organizer".
**Recommended Fix:** Add a `before_action :authorize_organizer!, only: [:create, :update, :destroy]` to the controller.

---

### Proofs of Vulnerability (Task 1)

**Proof 1: Mass Assignment (Creating an admin user)**
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Hacker","email":"hacker@hacker.com","password":"password123","role":"admin"}'

# Output proves I got the admin role:
# {"token":"ey...","user":{"id":6,"name":"Hacker","email":"hacker@hacker.com","role":"admin"}}
```

**Proof 2: SQL Injection (Triggering a database error)**
```bash
curl "http://localhost:3000/api/v1/events?search=test%27%20OR%201=1--"

# Output proves the payload reached the database unescaped:
# {"status":500,"error":"Internal Server Error","exception":"#<ActiveRecord::StatementInvalid: PG::SyntaxError: ERROR:  syntax error at or near \"1\"..."}
```
### **Task 2: Fix the #1 Critical Issue (IDOR/Access Control)**

To fix Issue #2, we will update the `EventsController` so users can only update or delete events they own.

**1. Update `app/controllers/api/v1/events_controller.rb`**