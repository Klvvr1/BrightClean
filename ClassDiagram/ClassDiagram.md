# Laundry Platform — Class Diagram Documentation

> **Version:** 6.8 — Server-Backed Frontend Data Flow Updated
> **Last Updated:** June 2026
> **Diagram Type:** UML Class Diagram
> **Architecture Pattern:** Table Per Type (TPT) Inheritance + Rich Junction Entities
>
> **Changelog v6.4 (Phase 1 & Phase 2 Updates):**
> - Added `IsStoreClosed` state boolean to `LaundryAgent` domain entity
> - Password reset uses transient in-memory OTP storage (not persisted to User model) via thread-safe dictionary for temporary token/expiry pairs
> - Detailed `UserDocument` with specific image uploads for `CommercialRegistration` and `NationalID`, documenting `UserID_FK` relationship
> - Documented Frontend Architecture Providers (`OrderProvider`, `AdminProvider`, `AuthProvider`) and Repositories in a new dedicated section
>
> **Changelog v6.5 (Remediation Implementation Updates):**
> - Payment creation is now restricted to authenticated client-owned `Pending` bookings with a locked `FinalTotal`
> - Wallet payments debit `Client.WalletBalance` atomically inside the payment transaction
> - Cash and bank transfer payments are recorded as `Pending`; wallet and credit card payments are recorded as `Success`
> - Booking creation validates that the selected agent is approved, active, open, and subscribed to every requested service
> - Driver and agent registration submit required document images through multipart form data
> - Checkout frontend clears the cart and records the local order only after the payment API confirms success
> - API base URL is now environment/platform configurable instead of always using hardcoded `localhost`
>
> **Changelog v6.6 (Phase 4 Durable Workflow Updates):**
> - Added `DocumentReviewStatus` for durable document review state
> - Added document metadata fields: original file name, content type, file size, review status, reviewer, review timestamp, and notes
> - Added payment lifecycle fields: created timestamp, proof URL, status reason, reviewer, and review timestamp
> - Added `PendingReview` and `Collected` payment statuses without changing existing enum numeric values
> - Added admin payment review endpoints for pending payment listing, confirmation, and rejection
> - Added audit details and IP address fields for sensitive admin actions
>
> **Changelog v6.7 (Development Transport Stability):**
> - HTTPS redirection is disabled by default in Development to prevent Flutter `POST` requests to `http://localhost:5135` / `10.0.2.2:5135` from receiving `307 Temporary Redirect`
> - Flutter API client now reports HTTP 307/308 redirects with an explicit API URL/protocol configuration message
>
> **Changelog v6.8 (Phase 5 Server-Backed Data Updates):**
> - Added DTO-safe `GET /api/bookings/my` for customer order history; `Draft` bookings are excluded from order history
> - Added public agent details, ratings summary, recent review, and agent service ID data for frontend filtering
> - Added `GET /api/services/agents/{agentId}` to expose only active services supported by the selected available agent
> - Admin pending and approved staff APIs now include real document metadata/URLs and role-specific fields
> - Flutter order history now loads from backend bookings instead of debug/demo local orders
> - Flutter service selection no longer falls back to `serviceId = 1`; invalid catalog mappings are blocked before checkout
> - Agent selection and checkout filter agents by required backend service IDs
> - Added `GET /api/users/me` so role dashboards can load server-backed profile data instead of relying on `SharedPreferences`
> - Added `GET /api/bookings/agent/my` for laundry-agent order lists and wired the agent dashboard to server-backed bookings
> - Added agent order actions `POST /api/bookings/{bookingId}/reject` and `POST /api/bookings/{bookingId}/start`; existing accept/ready actions are now called from Flutter instead of simulated delays
> - Customer ratings are only cached locally after the backend rating API succeeds; default seeded local reviews are no longer shown for empty review history
> - Added authenticated `POST /api/auth/change-password`; the Flutter change-password screen no longer uses simulated success
> - `GET /api/users/agents` returns all approved/open agents with their supported `serviceIds` array; service compatibility filtering is performed client-side in `checkout_screen.dart` and `agent_selection_screen.dart` by matching requested serviceIds against each agent's returned serviceIds
> - Delivery task pool now returns the current driver's `Assigned` and `InProgress` tasks, not only newly assigned tasks
> - Agent registration now persists selected service categories into `AgentService` rows; admin approval activates those pending service subscriptions
> - Added admin service assignment endpoint `POST /api/admin/agents/{agentId}/services` for correcting or updating existing laundry-agent service subscriptions
> - Driver task cards now open the tracking/detail workflow with the selected `DeliveryTaskModel`; task completion is sent through `DriverProvider.completeTask()` instead of local-only state
> - Driver available tasks now use an `Manage Order` / `إدارة الطلب` flow: details first, then confirmed claim, then the task moves to the driver's current orders for staged status updates and completion
>
> **Changelog v6.2:**
> - `SystemStatus.Reason` removed — `Message` is the sole public-facing explanation shown on the login screen
> - `BookingRating` confirmed: `AgentComment` and `DeliveryComment` are the free-text note fields the client writes alongside their star ratings — no structural change required
>
> **Changelog v6.3:**
> - `Draft` added to `BookingStatus` — enables cart functionality without any new entities
> - `ExpiresAt` added to `Booking` — auto-cleanup of abandoned carts via background job
> - `FinalTotal` default changed to `NULL` in Draft state — locked only on submit
> - Cart business rules documented in Business Rules section
> - Booking Status State Machine updated to include Draft stage

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Schema Statistics](#2-schema-statistics)
3. [Architecture Decisions](#3-architecture-decisions)
4. [Enumerations](#4-enumerations)
5. [User Hierarchy](#5-user-hierarchy)
6. [Core Entities](#6-core-entities)
7. [Catalog & Subscription](#7-catalog--subscription)
8. [Booking System](#8-booking-system)
9. [Delivery System](#9-delivery-system)
10. [Payment System](#10-payment-system)
11. [Rating System](#11-rating-system)
12. [Administration & Audit](#12-administration--audit)
13. [Relationship Map](#13-relationship-map)
14. [Business Rules](#14-business-rules)
15. [Delivery Model Matrix](#15-delivery-model-matrix)
16. [Booking Status State Machine](#16-booking-status-state-machine)
17. [Registration Compatibility](#17-registration-compatibility)
18. [Frontend Architecture (Providers & Repositories)](#18-frontend-architecture-providers--repositories)

---

## 1. System Overview

This platform is a **multi-service on-demand marketplace** that connects clients with licensed service agents across four service categories. The platform manages the full lifecycle of every service request — from registration and booking, through logistics and payment, to completion and auditing.

### Platform Actors

| Actor | Role |
|---|---|
| **Client** | Browses agents, places bookings, makes payments |
| **LaundryAgent** | Licensed provider offering one or more service categories |
| **DeliveryStaff** | Driver who claims and executes two-stage delivery tasks |
| **Admin** | Sole platform supervisor managing catalog, offers, and users |

### Service Categories

| Category | Delivery Model | Examples |
|---|---|---|
| Laundry | Two-Stage | WashAndIron, DryClean, IronOnly |
| HomeWovens | Two-Stage | Curtains, Bedsheets, Blankets, Carpets |
| HomeServices | TechnicianDispatch | HomeCleaning, ACCleaning, WaterTankCleaning, SolarPanelCleaning |
| VehicleWash | TechnicianDispatch | CarWash, MotorcycleWash |

---

## 2. Schema Statistics

| Metric | Count |
|---|---|
| Total Classes | 18 |
| Total Enumerations | 17 |
| Total Relationships | 26 |
| Inheritance Relationships | 4 |
| One-to-One Relationships | 2 |
| One-to-Many Relationships | 22 |
| Composition Relationships | 1 |
| Many-to-Many (via Junction) | 1 |

### All Classes at a Glance

| # | Class | Type | Description |
|---|---|---|---|
| 1 | `User` | Abstract | Base identity for all actors |
| 2 | `Client` | Concrete | Customer who places bookings |
| 3 | `DeliveryStaff` | Concrete | Driver executing delivery tasks |
| 4 | `LaundryAgent` | Concrete | Licensed service provider |
| 5 | `Admin` | Concrete | Platform supervisor |
| 6 | `Address` | Entity | Physical location for clients and agents |
| 7 | `UserDocument` | Entity | Uploaded verification documents |
| 8 | `ServiceCatalogItem` | Entity | Platform-managed service catalog |
| 9 | `AgentService` | Junction | Agent-to-service subscription |
| 10 | `Offer` | Entity | Admin-created promotional discounts |
| 11 | `Booking` | Aggregate Root | Unified service request |
| 12 | `BookingItem` | Entity | Line items within a booking |
| 13 | `BookingRating` | Entity | Client star rating and comment per booking |
| 14 | `DeliveryTask` | Entity | Single leg of two-stage logistics |
| 15 | `Payment` | Entity | Full payment record per booking |
| 16 | `AuditLog` | Entity | Immutable admin action trail |
| 17 | `SystemStatus` | Entity | Platform login on/off control |

---

## 3. Architecture Decisions

### 3.1 Inheritance Strategy — Table Per Type (TPT)

Each user subtype (`Client`, `DeliveryStaff`, `LaundryAgent`, `Admin`) maps to its own table, joined to the base `User` table via shared primary key. This keeps the base table lean and subtypes clean.

```
User (UserID, Email, PasswordHash, PhoneNo, ...)
 ├── Client      (UserID FK, Gender, WalletBalance)
 ├── DeliveryStaff (UserID FK, VehicleType, PlateNumber, ...)
 ├── LaundryAgent  (UserID FK, BusinessName, CommercialRegister, ...)
 └── Admin         (UserID FK, LastLoginAt)
```

### 3.2 Unified Booking Aggregate

All service types — laundry, home services, vehicle wash — use a single `Booking` entity. The `DeliveryModel` field on each `ServiceCatalogItem` drives whether delivery tasks are created or a technician is dispatched. This avoids separate order tables per service type.

### 3.3 Admin as Sole Catalog and Offer Owner

The admin is the only actor who can create services and offers. Agents subscribe to catalog items but cannot create or price them. Prices are platform-fixed and uniform across all agents.

### 3.4 Open-Pool Delivery Assignment

Delivery tasks are created in `Unassigned` state. Drivers claim tasks from an open pool — no driver is pre-assigned at booking creation. Stage 2 only enters the pool after Stage 1 is `Completed`.

### 3.5 Price Snapshot on BookingItem

`UnitPriceAtTimeOfBooking` captures the service price at booking creation time. Future catalog price changes never affect historical booking records.

### 3.6 Derived Performance Ratings

Agent and driver average ratings are computed at query time from `BookingRating` records — never stored as fields. This eliminates stale data risk. Both `LaundryAgent` and `DeliveryStaff` expose `/averageRating()` and `/totalRatings()` as derived methods.

### 3.7 System Login Control

A single `SystemStatus` entity controls whether login is enabled platform-wide. Every state change appends a new row — history is preserved. The admin is always exempt from the login block to ensure the system can always be restored.

---

## 4. Enumerations

### 4.1 `UserRole`

Discriminator for the `User` inheritance hierarchy.

| Value | Description |
|---|---|
| `Client` | Customer placing bookings |
| `DeliveryStaff` | Driver executing delivery tasks |
| `LaundryAgent` | Licensed service provider |
| `Admin` | Platform supervisor |

**Used in:** `User.Role`

---

### 4.2 `AccountStatus`

Governs the full lifecycle of a user account from registration through verification to potential suspension.

| Value | Description | Triggered By |
|---|---|---|
| `PendingVerification` | Registered, awaiting admin review | Registration submission |
| `Active` | Admin approved — account fully operational | Admin action |
| `Suspended` | Temporarily disabled — cannot log in or operate | Admin action |
| `Deactivated` | Permanently closed | Admin action |

**Used in:** `User.AccountStatus`
**Logic:** While `AccountStatus = PendingVerification`, `AgentService.IsActive` is ignored — no services are visible to clients regardless of their value.

---

### 4.3 `Gender`

Client gender selection at registration.

| Value | Description |
|---|---|
| `Male` | Male |
| `Female` | Female |

**Used in:** `Client.Gender`

---

### 4.4 `VehicleType`

Type of vehicle operated by a delivery staff member. Affects task assignment eligibility.

| Value | Description |
|---|---|
| `Car` | Four-wheeled vehicle — suitable for large laundry loads |
| `Motorcycle` | Two-wheeled — suitable for small loads, faster urban delivery |
| `TukTuk` | Three-wheeled — medium capacity |

**Used in:** `DeliveryStaff.VehicleType`

---

### 4.5 `DocumentType`

Classifies uploaded verification documents per user role.

| Value | Required By | Description |
|---|---|---|
| `NationalID` | DeliveryStaff, LaundryAgent | Government-issued identity document |
| `DriverLicense` | DeliveryStaff | Valid driving license |
| `VehicleImage` | DeliveryStaff | Photo of registered vehicle |
| `CommercialRegistration` | LaundryAgent | Business license document |

**Used in:** `UserDocument.Type`

---

### 4.6 `DocumentReviewStatus`

Durable review status for each uploaded verification document. Account approval is still holistic, but each document now records its own review metadata for auditability.

| Value | Description |
|---|---|
| `Pending` | Uploaded and awaiting admin review |
| `Approved` | Accepted by an admin during account approval |
| `Rejected` | Rejected by an admin with optional review notes |

**Used in:** `UserDocument.ReviewStatus`

---

### 4.7 `ServiceCategory`

High-level grouping of all platform services. Used for UI filtering and agent profile classification.

| Value | Description |
|---|---|
| `Laundry` | Clothing-related washing and ironing |
| `HomeWovens` | Large fabric items — curtains, carpets, bedding |
| `HomeServices` | On-site home maintenance services |
| `VehicleWash` | On-site car and motorcycle washing |

**Used in:** `ServiceCatalogItem.Category`

---

### 4.8 `ServiceType`

Specific service type within its category. Every catalog item maps to exactly one type.

| Value | Category | Description |
|---|---|---|
| `WashAndIron` | Laundry | Full wash and press of clothing |
| `DryClean` | Laundry | Chemical cleaning for delicate fabrics |
| `IronOnly` | Laundry | Ironing service without washing |
| `Curtains` | HomeWovens | Curtain washing and finishing |
| `Bedsheets` | HomeWovens | Bed linen washing |
| `Blankets` | HomeWovens | Blanket and duvet cleaning |
| `Carpets` | HomeWovens | Carpet deep cleaning |
| `HomeCleaning` | HomeServices | General residential cleaning |
| `ACCleaning` | HomeServices | Air conditioner deep service |
| `WaterTankCleaning` | HomeServices | Underground and overhead tank cleaning |
| `SolarPanelCleaning` | HomeServices | Solar panel surface cleaning |
| `CarWash` | VehicleWash | Full car wash at client location |
| `MotorcycleWash` | VehicleWash | Motorcycle wash at client location |

**Used in:** `ServiceCatalogItem.Type`

---

### 4.9 `PricingModel`

Determines how `BookingItem.subTotal()` is computed.

| Value | Formula | Example |
|---|---|---|
| `PerItem` | `Quantity × UnitPriceAtTimeOfBooking` | 3 shirts × 2.500 KWD |
| `FlatFee` | `UnitPriceAtTimeOfBooking` (quantity irrelevant) | AC cleaning = 15.000 KWD flat |

**Used in:** `ServiceCatalogItem.PricingModel`

---

### 4.10 `DeliveryModel`

The most operationally significant enum. Determines logistics behavior for each service type and drives whether `DeliveryTask` records are created.

| Value | Tasks Created | Who Goes Where |
|---|---|---|
| `TwoStage` | 2 tasks | Driver collects items from client → agent processes → driver returns to client |
| `TechnicianDispatch` | 0 tasks | Agent dispatches staff to client location; service performed on-site |

**Used in:** `ServiceCatalogItem.DeliveryModel`

---

### 4.11 `BookingStatus`

State machine governing the full lifecycle of every booking. Transitions are strictly sequential.

| Value | Description | Triggered By |
|---|---|---|
| `Draft` | Cart state — services being added, not yet confirmed | Client (on cart open) |
| `Pending` | Submitted and confirmed — awaiting agent acceptance | Client (on submit) |
| `Accepted` | Agent confirmed — delivery tasks created if applicable | LaundryAgent |
| `InProgress` | Work begun or technician dispatched | Agent / System |
| `Ready` | Processing complete — items ready for Stage 2 | LaundryAgent |
| `Completed` | Fully delivered or service performed | System |
| `Cancelled` | Terminated before completion | Client or Admin |

**Used in:** `Booking.Status`

**Cart Rules — `Draft` state:**

| Operation | Allowed in Draft? |
|---|---|
| Add / remove `BookingItem` | ✅ Yes |
| Apply `Offer` | ❌ No — `FinalTotal` not yet locked |
| `Payment` | ❌ No — no confirmed order yet |
| `DeliveryTask` creation | ❌ No — agent hasn't accepted |
| Transition to `Pending` | ✅ On client submit — `FinalTotal` is locked |

---

### 4.12 `TaskType`

Identifies which stage of the two-stage delivery a task represents.

| Value | Stage | Route |
|---|---|---|
| `PickupFromClient` | 1 | Client Address → Agent Business Address |
| `DeliveryToClient` | 2 | Agent Business Address → Client Address |

**Used in:** `DeliveryTask.Type`

---

### 4.13 `DeliveryTaskStatus`

Tracks the independent lifecycle of each delivery leg.

| Value | `AssignedAt` | `DeliveryStaffID` | Description |
|---|---|---|---|
| `Unassigned` | null | null | In pool, no driver claimed yet |
| `Assigned` | Populated | Populated | Driver claimed the task |
| `InProgress` | Populated | Populated | Driver actively en route |
| `Completed` | Populated | Populated | Leg finished successfully |

**Used in:** `DeliveryTask.Status`
**Rule:** Stage 2 cannot leave `Unassigned` until Stage 1 reaches `Completed`.

---

### 4.14 `PaymentMethod`

Payment channel used by the client.

| Value | Pre-condition | Notes |
|---|---|---|
| `CreditCard` | `TransactionRef` must be populated | Processed via payment gateway |
| `Cash` | None | Physical cash to agent or driver |
| `Wallet` | `Client.WalletBalance >= Amount` | Deducted from platform wallet |
| `BankTransfer` | Transfer reference/proof expected by business workflow | Recorded for later confirmation/review |

**Used in:** `Payment.Method`

---

### 4.15 `PaymentStatus`

Outcome states of the single payment per booking.

| Value | Terminal | Description |
|---|---|---|
| `Pending` | No | Payment initiated, awaiting confirmation |
| `Success` | Yes | Payment confirmed and processed |
| `Failed` | Yes | Payment attempt rejected |
| `Refunded` | Yes | Successful payment reversed on cancellation |
| `PendingReview` | No | Bank transfer or proof-based payment awaiting admin review |
| `Collected` | Yes | Cash payment collected and confirmed by admin |

**Used in:** `Payment.Status`

---

### 4.16 `OfferType`

Discount calculation method.

| Value | Formula |
|---|---|
| `Percentage` | `FinalTotal × (DiscountValue / 100)` |
| `FixedAmount` | `FinalTotal - DiscountValue` |

**Used in:** `Offer.Type`

---

### 4.17 `OfferScope`

Controls which bookings an offer can be applied to.

| Value | `LaundryAgentID` FK | Description |
|---|---|---|
| `AllAgents` | `NULL` | Platform-wide — any booking qualifies |
| `SpecificAgent` | Populated | Only bookings handled by the named agent |

**Used in:** `Offer.Scope`

---

## 5. User Hierarchy

### 5.1 `User` (Abstract)

Root identity table shared across all actors. No concrete `User` record exists independently — every user belongs to exactly one subtype.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `UserID_PK` | int | PK, Auto-increment | Unique identifier across all subtypes |
| `FirstName` | string | NOT NULL | Legal first name |
| `LastName` | string | NOT NULL | Legal last (family) name |
| `Email` | string | NOT NULL, UNIQUE | Login identifier |
| `PasswordHash` | string | NOT NULL | bcrypt/argon2 hash — never plaintext |
| `PhoneNo` | string | NOT NULL, 9 digits | Contact number (validated to exactly 9 digits for Yemeni phone numbers) |
| `DateOfBirth` | date | NOT NULL | Used for age verification |
| `ProfilePhotoURL` | string? | NULLABLE | CDN URL of profile photo |
| `TermsAccepted` | boolean | NOT NULL, DEFAULT false | T&C acceptance at registration |
| `AccountStatus` | AccountStatus | NOT NULL, DEFAULT PendingVerification | Account lifecycle state |
| `Role` | UserRole | NOT NULL | Inheritance discriminator |
| `VerifiedAt` | datetime? | NULLABLE | Stamped when admin approves account |
| `CreatedAt` | datetime | NOT NULL, DEFAULT NOW() | Registration timestamp |

### 5.1.1 Forgot Password Flow State (Transient / In-Memory)

Authentication operations manage password recovery state **in-memory only** (not persisted to database) via a thread-safe `ConcurrentDictionary` that associates user emails with verification OTP tokens. These entries are temporary and do not appear in the User model or API schema.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `Token` | string | 6-character OTP | Temporary random numeric string (cryptographically generated) sent to user's email |
| `Expires` | datetime | NOT NULL | Token expiration deadline (15 minutes from generation) |

**Note:** OTPs are never persisted to the database. They exist only in the application's memory and are automatically cleared upon successful password reset or expiration.

**Password Policy (enforced pre-hash at application layer):**
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 numeric digit

---

### 5.2 `Client`

The customer actor. Owns addresses, places bookings, and holds a platform wallet.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `UserID_PK` (FK) | int | PK, FK → User | Shared key under TPT |
| `Gender` | Gender | NOT NULL | Required at registration |
| `WalletBalance` | decimal | NOT NULL, DEFAULT 0, CHECK >= 0 | Platform wallet — used for Wallet payment method |

**Relationships:**
- `Client "1" --> "0..*" Address` — owns delivery/service addresses
- `Client "1" --> "0..*" Booking` — places service bookings

---

### 5.3 `DeliveryStaff`

The logistics executor. Claims and completes delivery tasks from an open pool.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `UserID_PK` (FK) | int | PK, FK → User | Shared key |
| `FatherName` | string | NOT NULL | Four-part Arabic name |
| `GrandfatherName` | string | NOT NULL | Four-part Arabic name |
| `NationalIDNumber` | string | NOT NULL, UNIQUE | Government ID number |
| `VehicleType` | VehicleType | NOT NULL | Car, Motorcycle, or TukTuk |
| `VehicleMake` | string | NOT NULL | Vehicle manufacturer (e.g. Toyota) |
| `VehicleModel` | string | NOT NULL | Vehicle model (e.g. Corolla) |
| `PlateNumber` | string | NOT NULL, UNIQUE | Vehicle registration plate |
| `BankAcc` | string | NOT NULL | Bank account for delivery fee payouts |
| `/averageRating()` | decimal | Derived | Computed from `BookingRating.DeliveryRating` |
| `/totalRatings()` | int | Derived | Count of non-null `DeliveryRating` records |

**Required Documents:** `NationalID`, `DriverLicense`, `VehicleImage`

**Relationships:**
- `DeliveryStaff "1" --> "0..*" DeliveryTask` — claims and executes tasks
- `User "1" --> "0..*" UserDocument` — uploads verification documents

---

### 5.4 `LaundryAgent`

The central service provider. Offers a platform-admin-approved subset of the service catalog across any combination of categories.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `UserID_PK` (FK) | int | PK, FK → User | Shared key |
| `FatherName` | string | NOT NULL | Four-part Arabic name |
| `GrandfatherName` | string | NOT NULL | Four-part Arabic name |
| `NationalIDNumber` | string | NOT NULL, UNIQUE | Government ID number |
| `BusinessName` | string | NOT NULL | Trading name of the business |
| `CommercialRegister` | string | NOT NULL, UNIQUE | Government business license number |
| `BankAcc` | string | NOT NULL | Bank account for service revenue |
| `IsStoreClosed` | boolean | NOT NULL, DEFAULT false | Toggle status of the agent's storefront (true = closed, false = open) |
| `/averageRating()` | decimal | Derived | Computed from `BookingRating.AgentRating` |
| `/totalRatings()` | int | Derived | Count of non-null `AgentRating` records |

**Required Documents:** `NationalID`, `CommercialRegistration`

**Relationships:**
- `LaundryAgent "1" --> "1" Address` — mandatory business location with GPS coordinates
- `LaundryAgent "1" --> "0..*" AgentService` — service subscriptions
- `Booking "0..*" --> "1" LaundryAgent` — receives bookings
- `Offer "0..*" --> "0..1" LaundryAgent` — may be the target of scoped offers

---

### 5.5 `Admin`

The sole platform supervisor. One instance. Manages all catalog, offers, users, and generates the audit trail.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `UserID_PK` (FK) | int | PK, FK → User | Shared key |
| `LastLoginAt` | datetime | NULLABLE | Security monitoring timestamp |

**Capabilities:**
- Create, update, and deactivate `ServiceCatalogItem` records
- Create and scope `Offer` records
- Approve or reject user registrations via `AccountStatus`
- Activate or deactivate agent service subscriptions via `AgentService.IsActive`
- Review all `AuditLog` entries

---

## 6. Core Entities

### 6.1 `Address`

Physical location entity. Used for client delivery addresses, agent business premises, and delivery task routing.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `AddressID_PK` | int | PK, Auto-increment | Unique identifier |
| `Area` | string | NOT NULL | Neighborhood or district |
| `Street` | string | NOT NULL | Street name and number |
| `Latitude` | decimal | NOT NULL | GPS latitude — from map picker |
| `Longitude` | decimal | NOT NULL | GPS longitude — from map picker |
| `IsArchived` | boolean | NOT NULL, DEFAULT false | Soft delete — hides address without deleting |

**Relationships:**
- `Client "1" --> "0..*" Address` — client delivery addresses
- `LaundryAgent "1" --> "1" Address` — mandatory agent business location
- `Booking "0..*" --> "1" Address` — service or delivery location
- `DeliveryTask "0..*" --> "1" Address : pickup from`
- `DeliveryTask "0..*" --> "1" Address : dropoff to`

**Constraints:**
- Archived addresses cannot be selected for new bookings
- Cannot be hard-deleted if referenced by any existing booking or delivery task
- `Latitude` range: −90.0 to 90.0
- `Longitude` range: −180.0 to 180.0

---

### 6.2 `UserDocument`

Stores uploaded verification document references for `DeliveryStaff` and `LaundryAgent`. Documents are reviewed holistically as part of the full registration review — not individually.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `DocumentID_PK` | int | PK, Auto-increment | Unique identifier |
| `UserID_FK` | int | FK → User, NOT NULL | Foreign key referencing the parent `User` who uploaded the document |
| `Type` | DocumentType | NOT NULL | NationalID, DriverLicense, VehicleImage, CommercialRegistration |
| `FileURL` | string | NOT NULL | Relative URL/path of the uploaded file on the server's local file storage (`wwwroot/uploads`) |
| `OriginalFileName` | string? | NULLABLE, max 260 | Original client-side filename for admin review and audit context |
| `ContentType` | string? | NULLABLE, max 120 | Uploaded file MIME type reported by the request |
| `FileSizeBytes` | long? | NULLABLE | Uploaded file size in bytes |
| `UploadedAt` | datetime | NOT NULL, DEFAULT NOW() | Document upload timestamp |
| `ReviewStatus` | DocumentReviewStatus | NOT NULL, DEFAULT Pending | Durable per-document review status |
| `ReviewedAt` | datetime? | NULLABLE | Timestamp when admin reviewed the document |
| `ReviewedByAdminID` | int? | NULLABLE, FK → Admin | Admin who reviewed the document |
| `ReviewNotes` | string? | NULLABLE | Optional admin note, usually used for rejection or clarification |

**Verification Document Types & Images:**

* **Commercial Register Image**: Represented by a `UserDocument` record where the `Type` field equals `DocumentType.CommercialRegistration` and the `FileURL` field holds the file path. Sent from frontend via `commercialRegisterImage` multipart form data.
* **National ID Image**: Represented by a `UserDocument` record where the `Type` field equals `DocumentType.NationalID` and the `FileURL` field holds the file path. Sent from frontend via `nationalIdImage` multipart form data.
* **Driver License Image**: Represented by a `UserDocument` record where the `Type` field equals `DocumentType.DriverLicense` and the `FileURL` field holds the file path. Sent from frontend via `driverLicenseImage` multipart form data.
* **Vehicle Image**: Represented by a `UserDocument` record where the `Type` field equals `DocumentType.VehicleImage` and the `FileURL` field holds the file path. Sent from frontend via `vehicleImage` multipart form data.

**Key Relationship:**
- **Foreign Key constraint**: The `UserID_FK` database column establishes a **Many-to-One** relationship linking each document back to a unique record in the `User` table, representing the document's owner.

**Document Requirements by Role:**

| Role | Required Documents |
|---|---|
| `DeliveryStaff` | NationalID, DriverLicense, VehicleImage |
| `LaundryAgent` | NationalID, CommercialRegistration |

**Note:** Document approval is determined by the overall `User.AccountStatus` transition — the admin reviews all documents together and approves or rejects the entire registration.

**Serving Rule:** Uploaded files under `wwwroot/uploads` are exposed by the backend static file middleware. Any future move to protected document downloads must preserve the same `UserDocument.FileURL` relationship or introduce a deliberate document access endpoint.

---

## 7. Catalog & Subscription

### 7.1 `ServiceCatalogItem`

The platform-wide service catalog. Every service across all categories exists as a row here. Admin-managed. Prices are fixed and uniform — no agent-level pricing.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `ServiceID_PK` | int | PK, Auto-increment | Unique identifier |
| `ServiceName` | string | NOT NULL | Display name (e.g. "Air Conditioner Deep Clean") |
| `Category` | ServiceCategory | NOT NULL | Laundry, HomeWovens, HomeServices, VehicleWash |
| `Type` | ServiceType | NOT NULL | Specific service type |
| `Price` | decimal | NOT NULL, CHECK > 0 | Platform-fixed price — same for all agents |
| `PricingModel` | PricingModel | NOT NULL | PerItem or FlatFee |
| `DeliveryModel` | DeliveryModel | NOT NULL | TwoStage or TechnicianDispatch |
| `IsAvailable` | boolean | NOT NULL, DEFAULT true | Admin can disable platform-wide |

**Relationships:**
- `Admin "1" --> "0..*" ServiceCatalogItem` — admin is sole owner
- `ServiceCatalogItem "1" --> "0..*" AgentService` — subscribed to by agents
- `BookingItem "0..*" --> "1" ServiceCatalogItem` — referenced by booking line items

---

### 7.2 `AgentService` (Junction)

Resolves the many-to-many relationship between `LaundryAgent` and `ServiceCatalogItem`. Enables flexible agent profiles — each agent activates only the services they are approved to offer.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `AgentServiceID_PK` | int | PK, Auto-increment | Unique identifier |
| `LaundryAgentID` (FK) | int | FK → LaundryAgent, NOT NULL | The subscribing agent |
| `ServiceID` (FK) | int | FK → ServiceCatalogItem, NOT NULL | The catalog service |
| `IsActive` | boolean | NOT NULL, DEFAULT false | false = pending/suspended, true = live |
| `ActivatedAt` | datetime | NULLABLE | Stamped when admin sets IsActive = true |
| `Notes` | string? | NULLABLE | Optional scope notes (e.g. "Residential only") |

**Unique Constraint:** `(LaundryAgentID, ServiceID)` — an agent cannot subscribe to the same service twice.

**State Logic:**

| `User.AccountStatus` | `AgentService.IsActive` | Client Visibility |
|---|---|---|
| `PendingVerification` | `false` | Not visible |
| `Active` | `true` | Visible and bookable |
| `Active` | `false` | Not visible |
| `Suspended` | Any | Not visible |

**Agent Profile Examples:**

| Agent Type | Active AgentService Records |
|---|---|
| Laundry Only | WashAndIron, DryClean, IronOnly |
| Full Service | WashAndIron + HomeCleaning + ACCleaning + ... |
| Vehicle Specialist | CarWash, MotorcycleWash |

---

## 8. Booking System

### 8.1 `Offer`

Admin-created promotional discounts. Validity is fully derived — no manual activation needed.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `OfferID_PK` | int | PK, Auto-increment | Unique identifier |
| `OfferCode` | string | NOT NULL, UNIQUE | Alphanumeric code entered by client |
| `Type` | OfferType | NOT NULL | Percentage or FixedAmount |
| `Scope` | OfferScope | NOT NULL | AllAgents or SpecificAgent |
| `DiscountValue` | decimal | NOT NULL, CHECK > 0 | Magnitude of discount |
| `StartDate` | datetime | NOT NULL | Offer becomes valid from this moment |
| `EndDate` | datetime | NOT NULL | Offer expires after this moment |
| `MinOrderValue` | decimal? | NULLABLE, CHECK > 0 | Minimum booking total required |
| `MaxUsageCount` | int? | NULLABLE, CHECK > 0 | Usage cap — null means unlimited |
| `UsageCount` | int | NOT NULL, DEFAULT 0 | Running counter — incremented atomically |
| `LaundryAgentID` (FK) | int? | NULLABLE, FK → LaundryAgent | Null when Scope = AllAgents |
| `/isValid()` | bool | Derived | `now >= StartDate AND now <= EndDate AND (MaxUsageCount IS NULL OR UsageCount < MaxUsageCount)` |

**Constraints:**
- `DiscountValue` must be between 1–100 when `Type = Percentage`
- A `SpecificAgent` offer cannot be applied to a booking handled by a different agent
- `UsageCount` incremented atomically to prevent race conditions

---

### 8.2 `Booking`

The aggregate root of the platform. Every service request — regardless of category — is a `Booking`. Connects all transactional entities.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `BookingID_PK` | int | PK, Auto-increment | Unique identifier |
| `ClientID` (FK) | int | FK → Client, NOT NULL | The placing client |
| `LaundryAgentID` (FK) | int | FK → LaundryAgent, NOT NULL | The handling agent |
| `AddressID` (FK) | int | FK → Address, NOT NULL | Service or delivery location |
| `OfferID` (FK) | int? | NULLABLE, FK → Offer | Applied discount if any |
| `Status` | BookingStatus | NOT NULL, DEFAULT Draft | Lifecycle state — starts as cart |
| `FinalTotal` | decimal? | NULLABLE, CHECK >= 0 | NULL during Draft — locked on submit to Pending |
| `CreatedAt` | datetime | NOT NULL, DEFAULT NOW() | Booking creation timestamp |
| `ExpiresAt` | datetime? | NULLABLE | Auto-cleanup deadline for abandoned Draft bookings |
| `ScheduledAt` | datetime? | NULLABLE | Required when DeliveryModel = TechnicianDispatch |
| `SpecialInstructions` | string? | NULLABLE | Access codes, notes for agent staff |

**Constraints:**
- `FinalTotal` is NULL during `Draft` — computed and locked when client submits (transition to `Pending`)
- `FinalTotal` is immune to future price changes once locked
- `ExpiresAt` is set at Draft creation — a background job deletes expired Draft bookings automatically
- Booking creation is restricted to authenticated clients
- The selected `LaundryAgent` must be approved, active, and not store-closed at booking creation time
- Every requested `BookingItem.ServiceID` must exist in the selected agent's active `AgentService` subscriptions
- `ScheduledAt` is mandatory for all `TechnicianDispatch` service bookings
- Status transitions are strictly sequential — no skipping or reversal except to `Cancelled`
- Cancellation must reverse `Offer.UsageCount` if an offer was applied
- No `Payment`, `DeliveryTask`, or `Offer` can be attached while `Status = Draft`

---

### 8.3 `BookingItem`

Individual line items within a booking. Cannot exist without their parent booking (composition).

| Field | Type | Constraints | Description |
|---|---|---|---|
| `BookingItemID_PK` | int | PK, Auto-increment | Unique identifier |
| `BookingID` (FK) | int | FK → Booking, NOT NULL | Parent booking (composition) |
| `ServiceID` (FK) | int | FK → ServiceCatalogItem, NOT NULL | Referenced catalog service |
| `Quantity` | int | NOT NULL, CHECK >= 1 | Units requested |
| `UnitPriceAtTimeOfBooking` | decimal | NOT NULL, CHECK > 0 | Price snapshot — never updated |
| `/subTotal()` | decimal | Derived | `PerItem: Quantity × UnitPrice` / `FlatFee: UnitPrice` |

**Constraints:**
- `UnitPriceAtTimeOfBooking` copied from `ServiceCatalogItem.Price` at booking creation — never modified
- `subTotal()` is always computed, never stored
- All items must reference services in the agent's active `AgentService` subscriptions

---

## 9. Delivery System

### 9.1 `DeliveryTask`

Represents one leg of the two-stage physical logistics chain. Only created for bookings containing `TwoStage` services. Exactly two tasks per qualifying booking — Stage 1 and Stage 2.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `TaskID_PK` | int | PK, Auto-increment | Unique identifier |
| `BookingID` (FK) | int | FK → Booking, NOT NULL | Parent booking |
| `DeliveryStaffID` (FK) | int? | NULLABLE, FK → DeliveryStaff | Null until driver claims task |
| `PickupAddressID` (FK) | int | FK → Address, NOT NULL | Origin of this leg |
| `DropoffAddressID` (FK) | int | FK → Address, NOT NULL | Destination of this leg |
| `StageNumber` | int | NOT NULL, CHECK IN (1, 2) | 1 = Pickup, 2 = Delivery |
| `Type` | TaskType | NOT NULL | PickupFromClient or DeliveryToClient |
| `Status` | DeliveryTaskStatus | NOT NULL, DEFAULT Unassigned | Task lifecycle state |
| `DeliveryFee` | decimal | NOT NULL, CHECK >= 0 | Fee paid to driver for this leg |
| `AssignedAt` | datetime? | NULLABLE | Stamped when driver claims task |
| `CompletedAt` | datetime? | NULLABLE | Stamped when driver marks complete |

**Address Mapping per Stage:**

| Stage | `PickupAddressID` | `DropoffAddressID` |
|---|---|---|
| Stage 1 — `PickupFromClient` | Client `Address` | Agent `BusinessAddress` |
| Stage 2 — `DeliveryToClient` | Agent `BusinessAddress` | Client `Address` |

**Constraints:**
- Stage 2 `Status` cannot leave `Unassigned` until Stage 1 `Status = Completed`
- `DeliveryStaffID` is null at creation — set atomically when driver claims from pool
- Driver task pool queries expose unassigned eligible tasks plus tasks already assigned to the authenticated driver only
- One driver can only have one `InProgress` task at a time (application-layer enforcement)

---

## 10. Payment System

### 10.1 `Payment`

Records the single full payment for a booking. The `UNIQUE` constraint on `BookingID` enforces the one-payment-per-booking policy at the database level.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `PaymentID_PK` | int | PK, Auto-increment | Unique identifier |
| `BookingID` (FK) | int | FK → Booking, NOT NULL, UNIQUE | Enforces one payment per booking |
| `Amount` | decimal | NOT NULL, CHECK > 0 | Must equal `Booking.FinalTotal` |
| `Method` | PaymentMethod | NOT NULL | CreditCard, Cash, Wallet, or BankTransfer |
| `Status` | PaymentStatus | NOT NULL, DEFAULT Pending | Payment outcome state |
| `TransactionRef` | string | NULLABLE | Gateway reference — mandatory for CreditCard |
| `PaymentProofURL` | string? | NULLABLE | Optional bank transfer proof or external payment document URL |
| `StatusReason` | string? | NULLABLE | Human-readable explanation for current payment status |
| `CreatedAt` | datetime | NOT NULL, DEFAULT GETUTCDATE() | Payment record creation timestamp |
| `PaidAt` | datetime | NULLABLE | Stamped when payment reaches `Success` or `Collected` |
| `ReviewedAt` | datetime? | NULLABLE | Timestamp when admin reviewed pending payment |
| `ReviewedByAdminID` | int? | NULLABLE, FK → Admin | Admin who confirmed or rejected pending payment |

**Business Rules:**
- Full payment only — no installments or partial payments
- Payment can be created only by the authenticated client who owns the booking
- Payment is accepted only when `Booking.Status = Pending` and `Booking.FinalTotal` is not null
- `Amount` is validated against the server-authoritative `Booking.FinalTotal` before record creation
- `Wallet` payment requires `Client.WalletBalance >= Amount` and debits the wallet inside the same database transaction as the payment insert
- `Cash` starts as `Pending`, `BankTransfer` starts as `PendingReview`, and `Wallet` / `CreditCard` start as `Success`
- Admin confirmation moves cash payments to `Collected` and bank transfer payments to `Success`
- Admin rejection moves pending payments to `Failed` and records `StatusReason`, `ReviewedAt`, and `ReviewedByAdminID`
- `Refunded` is a terminal state — no further transitions permitted
- Duplicate payment creation is rejected by both controller validation and the unique `BookingID` constraint

---

## 11. Rating System

### 11.1 `BookingRating`

Records the client's star rating and optional written note for a completed booking. Covers both the agent's service quality and the driver's delivery experience independently. Each star rating can be accompanied by a free-text note written by the client.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `RatingID_PK` | int | PK, Auto-increment | Unique identifier |
| `BookingID` (FK) | int | FK → Booking, NOT NULL, UNIQUE | One rating per booking |
| `AgentRating` | int? | NULLABLE, CHECK 1–5 | Star rating for the agent's service quality |
| `AgentComment` | string? | NULLABLE | Free-text note the client writes about the agent — submitted alongside `AgentRating` |
| `DeliveryRating` | int? | NULLABLE, CHECK 1–5 | Star rating for the driver's delivery experience |
| `DeliveryComment` | string? | NULLABLE | Free-text note the client writes about the driver — submitted alongside `DeliveryRating` |
| `RatedAt` | datetime | NOT NULL, DEFAULT NOW() | Submission timestamp |

> `AgentComment` and `DeliveryComment` are the note fields. The client writes them alongside their star ratings — they are optional free-text companions to each rating, not separate submissions. No additional entity or field is needed to support rating notes.

**Relationships:**
- `Booking "1" --> "0..1" BookingRating` — one rating per booking maximum

**Constraints:**
- Rating only submittable when `Booking.Status = Completed`
- `UNIQUE` on `BookingID` — one rating per booking enforced at DB level
- `DeliveryRating` and `DeliveryComment` must be null for `TechnicianDispatch` bookings — no driver to rate
- Both `AgentRating` and `DeliveryRating` are independently nullable — client can rate one without the other
- A comment without its corresponding star rating is not permitted — `AgentComment` requires `AgentRating`, `DeliveryComment` requires `DeliveryRating`

### 11.2 Derived Performance Fields

Agent and driver ratings are never stored as fields — always computed live from `BookingRating`:

**On `LaundryAgent`:**

| Derived Method | Formula |
|---|---|
| `/averageRating()` | `AVG(BookingRating.AgentRating)` for all completed bookings of this agent |
| `/totalRatings()` | `COUNT(BookingRating.AgentRating)` where not null |

**On `DeliveryStaff`:**

| Derived Method | Formula |
|---|---|
| `/averageRating()` | `AVG(BookingRating.DeliveryRating)` for all tasks handled by this driver |
| `/totalRatings()` | `COUNT(BookingRating.DeliveryRating)` where not null |

**Why computed and not stored:** Storing an average risks it becoming stale if a rating is updated or deleted. Computing it at query time guarantees it is always accurate.

---

## 12. Administration & Audit

### 12.1 `AuditLog`

Immutable record of every privileged admin action. Append-only — no UPDATE or DELETE operations permitted on this table.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `LogID_PK` | int | PK, Auto-increment | Unique identifier |
| `AdminID` (FK) | int | FK → Admin, NOT NULL | Performing admin |
| `Action` | string | NOT NULL | Action key (e.g. `ACTIVATE_AGENT`, `CREATE_OFFER`) |
| `TargetEntity` | string | NOT NULL | Affected table (e.g. `User`, `Offer`) |
| `TargetID` | int | NOT NULL | PK of the affected record |
| `Details` | string? | NULLABLE | Optional structured/plain text context for sensitive state transitions |
| `IpAddress` | string? | NULLABLE, max 64 | Remote IP address captured for admin action traceability |
| `PerformedAt` | datetime | NOT NULL, DEFAULT NOW() | Server-side timestamp — not application clock |

**Constraints:**
- No UPDATE or DELETE on this table — insert only
- `PerformedAt` set by database server clock — not application layer
- `TargetEntity + TargetID` form a soft polymorphic reference — no hard FK

### 12.2 `SystemStatus`

Controls whether login is enabled across the entire platform. Used by the admin to pause the system during maintenance or to address critical issues. Every state change appends a new row — full history is preserved.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `StatusID_PK` | int | PK, Auto-increment | Unique identifier — new row on every change |
| `LoginEnabled` | boolean | NOT NULL | `true` = login open, `false` = all logins blocked |
| `Message` | string? | NULLABLE | Public-facing message shown to users on the login screen — explains the purpose of the pause (e.g. "النظام في صيانة مؤقتة، نعود قريباً 🛠️") |
| `ChangedAt` | datetime | NOT NULL, DEFAULT NOW() | When the admin triggered the change |

> `Reason` was removed. `Message` is the sole field — it serves both as the internal record and the public-facing explanation shown directly to users on the login screen. No separate internal note is needed.

**Relationships:**
- `Admin "1" --> "0..*" SystemStatus` — admin controls all system status entries

**How the current state is read:**
```sql
SELECT * FROM SystemStatus
ORDER BY ChangedAt DESC
LIMIT 1
```

**Constraints:**
- Append-only — no UPDATE or DELETE on existing rows
- `ChangedAt` set by DB server clock
- Admin is always exempt from `LoginEnabled = false` — the admin must always be able to log in to restore the system
- `Message` is the sole user-facing explanation shown on the login screen during a pause (e.g. "النظام في صيانة مؤقتة، نعود قريباً 🛠️")

**Behavior:**

| `LoginEnabled` | Effect |
|---|---|
| `true` | Platform running normally — all users can log in |
| `false` | All user logins blocked — only admin can log in |

---

## 13. Relationship Map

| # | From | Cardinality | To | Label | Type |
|---|---|---|---|---|---|
| 1 | `User` | 1 ◄── | `Client` | is-a | Inheritance |
| 2 | `User` | 1 ◄── | `DeliveryStaff` | is-a | Inheritance |
| 3 | `User` | 1 ◄── | `LaundryAgent` | is-a | Inheritance |
| 4 | `User` | 1 ◄── | `Admin` | is-a | Inheritance |
| 5 | `User` | 1 ──► 0..* | `UserDocument` | uploads | One-to-Many |
| 6 | `Client` | 1 ──► 0..* | `Address` | has | One-to-Many |
| 7 | `Client` | 1 ──► 0..* | `Booking` | places | One-to-Many |
| 8 | `LaundryAgent` | 1 ──► 1 | `Address` | located at | One-to-One |
| 9 | `LaundryAgent` | 1 ──► 0..* | `AgentService` | subscribes to | One-to-Many |
| 10 | `ServiceCatalogItem` | 1 ──► 0..* | `AgentService` | offered by | One-to-Many |
| 11 | `Admin` | 1 ──► 0..* | `ServiceCatalogItem` | manages | One-to-Many |
| 12 | `Admin` | 1 ──► 0..* | `Offer` | creates | One-to-Many |
| 13 | `Admin` | 1 ──► 0..* | `AuditLog` | generates | One-to-Many |
| 14 | `Offer` | 0..* ──► 0..1 | `LaundryAgent` | scoped to | One-to-Many |
| 15 | `Booking` | 0..* ──► 1 | `LaundryAgent` | handled by | One-to-Many |
| 16 | `Booking` | 0..* ──► 1 | `Address` | located at | One-to-Many |
| 17 | `Booking` | 1 ──►◆ 1..* | `BookingItem` | contains | Composition |
| 18 | `Booking` | 0..* ──► 0..1 | `Offer` | applies | One-to-Many |
| 19 | `Booking` | 1 ──► 0..1 | `Payment` | paid by | One-to-One |
| 20 | `Booking` | 1 ──► 0..2 | `DeliveryTask` | may require | One-to-Many |
| 21 | `BookingItem` | 0..* ──► 1 | `ServiceCatalogItem` | references | One-to-Many |
| 22 | `DeliveryStaff` | 1 ──► 0..* | `DeliveryTask` | assigned to | One-to-Many |
| 23 | `DeliveryTask` | 0..* ──► 1 | `Address` | pickup from | One-to-Many |
| 24 | `DeliveryTask` | 0..* ──► 1 | `Address` | dropoff to | One-to-Many |
| 25 | `Admin` | 1 ──► 0..* | `Payment` | reviews | One-to-Many |
| 26 | `Admin` | 1 ──► 0..* | `UserDocument` | reviews | One-to-Many |

---

## 14. Business Rules

### Cart Rules
- A `Draft` booking is created automatically when the client opens the cart — no explicit action needed
- `BookingItem` records can be freely added or removed while `Status = Draft`
- `FinalTotal` is `NULL` during `Draft` — computed and locked only when the client submits the order
- No `Payment`, `Offer`, or `DeliveryTask` can be attached while `Status = Draft`
- `ExpiresAt` is set at Draft creation — a background job hard-deletes expired Draft bookings and their items automatically
- Transition from `Draft` → `Pending` locks `FinalTotal` and opens the order for agent acceptance

### Agent Booking Operation Rules
- Laundry agents can reject only their own `Pending` bookings; rejected bookings move to `Cancelled`
- Laundry agents can move only their own `Accepted` bookings to `InProgress`
- Flutter agent dashboards must load orders through `GET /api/bookings/agent/my`; local mock order state is not authoritative

### Payment Rules
- One payment per booking — enforced by `UNIQUE` constraint on `Payment.BookingID`
- Full payment only — no installments or partial amounts
- Payment can be created only by the booking owner while the booking is `Pending`
- `Booking.FinalTotal` must be locked before payment record creation
- `Amount` must equal the server-side `Booking.FinalTotal` before payment record is created
- Wallet payment requires sufficient `Client.WalletBalance` and debits the wallet atomically with payment creation
- Cash payments remain `Pending` until collection is confirmed
- Bank transfer payments use `PendingReview` and require admin confirmation or rejection through the payment review API
- Cash payment confirmation moves the payment to `Collected`
- Local frontend order persistence and cart clearing occur only after the payment API confirms the payment workflow response

### Delivery Rules
- `TwoStage` bookings generate exactly 2 `DeliveryTask` records at `Booking.Status = Accepted`
- `TechnicianDispatch` bookings generate 0 `DeliveryTask` records
- Stage 2 remains `Unassigned` until Stage 1 is `Completed`
- Different drivers may handle Stage 1 and Stage 2 of the same booking
- The driver pool returns eligible unassigned tasks plus the current driver's own `Assigned` and `InProgress` tasks; tasks assigned to other drivers are hidden

### Pricing Rules
- All prices are set by the admin — agents have no pricing authority
- Prices are uniform across all agents for the same service
- `UnitPriceAtTimeOfBooking` is locked at creation — immune to catalog updates

### Offer Rules
- Only the admin can create offers
- `SpecificAgent` offers apply only to bookings handled by the named agent
- `isValid()` is always derived — never a stored field
- `UsageCount` is incremented atomically on successful application

### Registration Rules
- All new accounts start as `AccountStatus = PendingVerification`
- Admin reviews all submitted documents holistically before approving
- `AgentService.IsActive` is ignored while account is `PendingVerification`
- `TermsAccepted` must be `true` before registration can be submitted
- Laundry agent registration is multipart and must include `commercialRegisterImage` and `nationalIdImage`
- Driver registration is multipart and must include `nationalIdImage`, `driverLicenseImage`, and `vehicleImage`
- Each uploaded document stores metadata and starts with `ReviewStatus = Pending`
- Account approval marks attached documents as `Approved` and records the reviewing admin and timestamp

### Agent Service Rules
- Only admin can activate or deactivate `AgentService` records
- Clients only see services where both `AccountStatus = Active` and `AgentService.IsActive = true`
- Booking creation rejects agents that are unapproved, inactive, store-closed, or missing any requested active service subscription
- All `BookingItem` records must reference services in the selected agent's active subscriptions
- Frontend cart and direct checkout must use real backend `ServiceID` values from the catalog; placeholder/fallback IDs are rejected before checkout

### Rating Rules
- Rating only submittable when `Booking.Status = Completed`
- One rating per booking — enforced by `UNIQUE` on `BookingRating.BookingID`
- `AgentComment` and `DeliveryComment` are optional free-text notes written alongside their respective star ratings
- A comment cannot be submitted without its corresponding star rating
- `DeliveryRating` and `DeliveryComment` must be null for `TechnicianDispatch` bookings — no driver was involved
- Average ratings for agents and drivers are always computed at query time — never stored

### System Status Rules
- Only the admin can change `SystemStatus`
- Every change appends a new row — history is never overwritten
- `LoginEnabled = false` blocks all user logins — admin is always exempt
- `Message` is the only explanation field — shown directly to users on the login screen during a pause

---

## 15. Delivery Model Matrix

| Service | Category | DeliveryModel | Tasks | ScheduledAt | Agent Action |
|---|---|---|---|---|---|
| WashAndIron | Laundry | TwoStage | 2 | Not required | Process clothes |
| DryClean | Laundry | TwoStage | 2 | Not required | Process clothes |
| IronOnly | Laundry | TwoStage | 2 | Not required | Iron clothes |
| Curtains | HomeWovens | TwoStage | 2 | Not required | Wash curtains |
| Bedsheets | HomeWovens | TwoStage | 2 | Not required | Wash bedding |
| Blankets | HomeWovens | TwoStage | 2 | Not required | Wash blankets |
| Carpets | HomeWovens | TwoStage | 2 | Not required | Clean carpets |
| HomeCleaning | HomeServices | TechnicianDispatch | 0 | **Required** | Dispatch cleaner |
| ACCleaning | HomeServices | TechnicianDispatch | 0 | **Required** | Dispatch technician |
| WaterTankCleaning | HomeServices | TechnicianDispatch | 0 | **Required** | Dispatch technician |
| SolarPanelCleaning | HomeServices | TechnicianDispatch | 0 | **Required** | Dispatch technician |
| CarWash | VehicleWash | TechnicianDispatch | 0 | **Required** | Dispatch washer |
| MotorcycleWash | VehicleWash | TechnicianDispatch | 0 | **Required** | Dispatch washer |

---

## 16. Booking Status State Machine

```
                   ┌───────┐
                   │ Draft │  ◄── Client opens cart — Booking created
                   └───┬───┘     FinalTotal = NULL
                       │         ExpiresAt set for auto-cleanup
                       │ Client submits order
                       │ FinalTotal locked
                       ▼
                   ┌─────────┐
                   │ Pending │  ◄── Awaiting agent acceptance
                   └────┬────┘
                        │ Agent accepts
                        ▼
                   ┌──────────┐
                   │ Accepted │  ◄── DeliveryTasks created (if TwoStage)
                   └────┬─────┘
                        │ Work begins
                        ▼
                  ┌────────────┐
                  │ InProgress │  ◄── Washing started / Technician on-site
                  └─────┬──────┘
                        │ Processing complete
                        ▼
                   ┌─────────┐
                   │  Ready  │  ◄── Stage 2 task enters driver pool (TwoStage)
                   └────┬────┘
                        │ Delivered / Service complete
                        ▼
                  ┌───────────┐
                  │ Completed │  ◄── Terminal success state
                  └───────────┘

    Cancelled ◄── Available from Pending, Accepted, InProgress, Ready
    Draft ──── Auto-deleted when ExpiresAt is reached (abandoned cart)
```

---

## 17. Registration Compatibility

### Compatibility Score: 95 / 100

### Field Coverage by Role

| Field | Client | DeliveryStaff | LaundryAgent |
|---|---|---|---|
| First Name | ✅ `User.FirstName` | ✅ `User.FirstName` | ✅ `User.FirstName` |
| Last Name | ✅ `User.LastName` | ✅ `User.LastName` | ✅ `User.LastName` |
| Father Name | — | ✅ `DeliveryStaff.FatherName` | ✅ `LaundryAgent.FatherName` |
| Grandfather Name | — | ✅ `DeliveryStaff.GrandfatherName` | ✅ `LaundryAgent.GrandfatherName` |
| Email | ✅ `User.Email` | ✅ `User.Email` | ✅ `User.Email` |
| Phone | ✅ `User.PhoneNo` | ✅ `User.PhoneNo` | ✅ `User.PhoneNo` |
| Password | ✅ `User.PasswordHash` | ✅ `User.PasswordHash` | ✅ `User.PasswordHash` |
| Date of Birth | ✅ `User.DateOfBirth` | ✅ `User.DateOfBirth` | ✅ `User.DateOfBirth` |
| Gender | ✅ `Client.Gender` | — | — |
| GPS Location | ✅ `Address.Latitude/Longitude` | — | ✅ `Address.Latitude/Longitude` |
| Address String | ✅ `Address.Area + Street` | — | ✅ `Address.Area + Street` |
| Terms Accepted | ✅ `User.TermsAccepted` | ✅ `User.TermsAccepted` | ✅ `User.TermsAccepted` |
| Vehicle Type | — | ✅ `DeliveryStaff.VehicleType` | — |
| Plate Number | — | ✅ `DeliveryStaff.PlateNumber` | — |
| National ID Number | — | ✅ `DeliveryStaff.NationalIDNumber` | ✅ `LaundryAgent.NationalIDNumber` |
| ID Image | — | ✅ `UserDocument (NationalID)` | ✅ `UserDocument (NationalID)` |
| License Image | — | ✅ `UserDocument (DriverLicense)` | — |
| Vehicle Image | — | ✅ `UserDocument (VehicleImage)` | — |
| Business Name | — | — | ✅ `LaundryAgent.BusinessName` |
| Commercial Register | — | — | ✅ `LaundryAgent.CommercialRegister` |
| Reg. Document Image | — | — | ✅ `UserDocument (CommercialRegistration)` |
| Service Selection | — | — | ✅ `AgentService` junction |


---

## 18. Frontend Architecture (Providers & Repositories)

This section documents the structure and key methods of the state providers and repositories in the Flutter frontend, capturing the changes made during Phase 1, Phase 2, and the checkout integrity remediation.

### 18.1 State Providers & Repositories

State providers manage application state and coordinate data flow between the user interface and domain layers.

| Provider | Purpose / Scope | Key Method | Description |
|---|---|---|---|
| `OrderProvider` | Manages cart state, active bookings, and checkout transactions | `createBooking(int laundryAgentID, List<Map<String, int>> items, DateTime? scheduledAt, String? specialInstructions)` | Contacts the checkout API to create a booking draft, including optional scheduling metadata, and stores the resulting booking ID in local state. |
| | | `fetchMyOrders()` | Loads customer order history from `GET /api/bookings/my`, maps server bookings into `Order`, and refreshes the local cache. |
| | | `submitOrder(..., DateTime? scheduledAt, String? specialInstructions)` | Submits the booking to lock the server-side total, but does not clear cart or save the local order before payment succeeds. |
| | | `completeCheckoutAfterPayment(Order localOrder)` | Saves the local order and clears the cart only after the payment API returns a successful workflow response. |
| `AdminProvider` | Handles administrative tasks such as pending users and active staff oversight | `fetchApprovedStaff()` | Retrieves the list of all approved laundry agents and drivers from the administrative staff API. |
| `AuthProvider` | Coordinates login session persistence, user profiles, registration, and password recovery | `updateProfile(String name, String phone)` | Splits the full name into first/last components, updates user info via the profile API, and refreshes local SharedPreferences. |
| | | `registerAgent(RegisterAgentModel, commercialRegisterImagePath, nationalIdImagePath)` | Sends agent registration data and required document images through multipart form data. |
| | | `forgotPassword(String email)` | Triggers the forgot password flow, generating an OTP sent to the user's email. |
| | | `resetPassword(String email, String token, String newPassword)` | Validates the OTP token and updates the user's password on the backend. |
| `BaseApiClient` | Centralizes HTTP communication and authentication headers | `defaultBaseUrl` | Resolves the API host from `BRIGHTCLEAN_API_BASE_URL`, then platform defaults: Android emulator uses `10.0.2.2`, desktop/web defaults to `localhost`. Development backend accepts HTTP to avoid 307 redirects during mobile/debug checkout. |

### 18.2 Repositories

Repositories serve as the data access layer, abstracting direct API communication with the backend.

* **Order / Booking Repository**:
  * `BookingRepository.getMyBookings()`: Calls `GET /api/bookings/my` to load server-backed customer order history.
  * `BookingRepository.createBooking(int laundryAgentID, List<Map<String, int>> items, DateTime? scheduledAt, String? specialInstructions)`: Submits items and optional scheduling fields to the booking creation API.
  * `BookingRepository.submitBooking(int bookingId, DateTime? scheduledAt, String? specialInstructions)`: Locks the draft booking total and moves it to `Pending` without modifying frontend cart state.
  * `BookingRepository.getPendingBookings()`: Parses both raw list responses and wrapped list responses defensively for backward compatibility.
* **Agent / Service Catalog APIs**:
  * `GET /api/users/agents`: Returns approved, active, open agents with address, rating summary, recent reviews, and supported `serviceIds`. The endpoint does NOT parse or apply serviceIds query parameters for filtering; all approved/open agents are returned. Client-side filtering by service compatibility is performed in `checkout_screen.dart` and `agent_selection_screen.dart` by matching requested serviceIds against each agent's returned serviceIds array.
  * `GET /api/users/agents/{agentId}`: Returns public agent details, services, and recent reviews.
  * `GET /api/users/agents/{agentId}/ratings-summary`: Returns rating distribution and average rating for the agent.
  * `GET /api/services/agents/{agentId}`: Returns only active catalog services that the selected available agent provides.
* **Agent Booking Repository**:
  * `AgentBookingRepository.getMyBookings()`: Calls `GET /api/bookings/agent/my` to load the authenticated laundry agent's real bookings.
  * `AgentBookingRepository.acceptBooking(int bookingId)`: Calls `POST /api/bookings/{bookingId}/accept` and relies on backend task creation rules.
  * `AgentBookingRepository.rejectBooking(int bookingId, String reason)`: Calls `POST /api/bookings/{bookingId}/reject` to cancel a pending booking with a rejection reason.
  * `AgentBookingRepository.startBooking(int bookingId)`: Calls `POST /api/bookings/{bookingId}/start` to move an accepted booking to `InProgress`.
  * `AgentBookingRepository.markReady(int bookingId)`: Calls `POST /api/bookings/{bookingId}/ready` when processing is complete.
  * `AgentBookingRepository.toggleStoreStatus()`: Calls `POST /api/bookings/toggle-store-status` and treats the returned server state as authoritative.
* **Current User API**:
  * `GET /api/users/me`: Returns authenticated profile data plus role-specific agent or driver details for dashboards and profile screens.
* **Admin Repository**:
  * `AdminRepository.getPendingApprovals()`: Fetches pending agent/driver approvals with real `UserDocument` metadata and file URLs.
  * `AdminRepository.getApprovedStaff()`: Fetches approved drivers and agents with real role-specific fields, rating, and document data from `/api/admin/staff`.
  * `POST /api/admin/agents/{agentId}/services`: Replaces the active service subscriptions for an existing laundry agent with validated available catalog services.
* **Auth Repository**:
  * `AuthRepository.registerAgent(...)`: Calls `POST /api/auth/register/agent` using multipart form data and the file keys `commercialRegisterImage` and `nationalIdImage`.
  * Agent registration sends `selectedServiceCategories` as comma-separated `ServiceCategory` numeric values. The backend creates pending `AgentService` subscriptions for all available catalog services in those categories.
  * `AuthRepository.updateProfile(String firstName, String lastName, String phone)`: Calls `PUT /api/users/profile` to update user account info.
  * `POST /api/auth/change-password`: Authenticated password change endpoint; verifies the current password before writing a new BCrypt hash.
  * `AuthRepository.forgotPassword(String email)`: Calls `POST /api/auth/forgot-password` to initiate recovery.
  * `AuthRepository.resetPassword(String email, String token, String newPassword)`: Calls `POST /api/auth/reset-password` to update credentials.
* **Driver Registration Screen**:
  * Calls `POST /api/auth/register/driver` using multipart form data and the file keys `nationalIdImage`, `driverLicenseImage`, and `vehicleImage`.
* **API Client**:
  * `BaseApiClient.defaultBaseUrl`: Uses `BRIGHTCLEAN_API_BASE_URL` when supplied; otherwise resolves emulator/desktop defaults to avoid hardcoded production assumptions.

### 18.3 Core Methods List

* **OrderProvider**:
  * `createBooking`: Sends a request to the backend with selected service items and laundry agent ID, creating a new `Draft` booking and saving the `BookingID` in local state.
  * `fetchMyOrders`: Refreshes order history from the backend and updates the local cache as a secondary store.
  * `submitOrder`: Submits the current draft booking and locks the server total; it intentionally preserves the cart until payment succeeds.
  * `completeCheckoutAfterPayment`: Saves the local order, persists it locally, clears the cart, and resets the current booking ID after the payment response confirms success.

* **AdminProvider**:
  * `fetchApprovedStaff`: Calls the admin repository to retrieve all approved laundry agents and delivery staff, caching the results in local state for dashboard views.

* **AuthProvider**:
  * `registerAgent`: Submits registration fields and required agent document images via multipart form data.
  * `updateProfile`: Updates the logged-in user's first name, last name, and phone number on the server, and updates the local storage cache (`user_name` and `user_phone`).
  * `forgotPassword`: Submits the user's email to request a temporary OTP code for password reset.
  * `resetPassword`: Submits the verified OTP code alongside the new password to complete the password reset flow.
