# Laundry Platform — Class Diagram Documentation

> **Version:** 5.0 — Final (Registration Complete)
> **Last Updated:** May 2026
> **Diagram Type:** UML Class Diagram
> **Architecture Pattern:** Table Per Type (TPT) Inheritance + Rich Junction Entities

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
11. [Administration & Audit](#11-administration--audit)
12. [Relationship Map](#12-relationship-map)
13. [Business Rules](#13-business-rules)
14. [Delivery Model Matrix](#14-delivery-model-matrix)
15. [Booking Status State Machine](#15-booking-status-state-machine)
16. [Registration Compatibility](#16-registration-compatibility)

---

## 1. System Overview

This platform is a **multi-service on-demand marketplace** that connects clients with licensed service agents across four service categories. The platform manages the full lifecycle of every service request — from registration and booking, through logistics and payment, to completion and auditing.

### Platform Actors

| Actor             | Role                                                         |
| ----------------- | ------------------------------------------------------------ |
| **Client**        | Browses agents, places bookings, makes payments              |
| **LaundryAgent**  | Licensed provider offering one or more service categories    |
| **DeliveryStaff** | Driver who claims and executes two-stage delivery tasks      |
| **Admin**         | Sole platform supervisor managing catalog, offers, and users |

### Service Categories

| Category     | Delivery Model     | Examples                                                        |
| ------------ | ------------------ | --------------------------------------------------------------- |
| Laundry      | Two-Stage          | WashAndIron, DryClean, IronOnly                                 |
| HomeWovens   | Two-Stage          | Curtains, Bedsheets, Blankets, Carpets                          |
| HomeServices | TechnicianDispatch | HomeCleaning, ACCleaning, WaterTankCleaning, SolarPanelCleaning |
| VehicleWash  | TechnicianDispatch | CarWash, MotorcycleWash                                         |

---

## 2. Schema Statistics

| Metric                      | Count |
| --------------------------- | ----- |
| Total Classes               | 15    |
| Total Enumerations          | 16    |
| Total Relationships         | 24    |
| Inheritance Relationships   | 4     |
| One-to-One Relationships    | 1     |
| One-to-Many Relationships   | 17    |
| Composition Relationships   | 1     |
| Many-to-Many (via Junction) | 1     |

### All Classes at a Glance

| #   | Class                | Type           | Description                              |
| --- | -------------------- | -------------- | ---------------------------------------- |
| 1   | `User`               | Abstract       | Base identity for all actors             |
| 2   | `Client`             | Concrete       | Customer who places bookings             |
| 3   | `DeliveryStaff`      | Concrete       | Driver executing delivery tasks          |
| 4   | `LaundryAgent`       | Concrete       | Licensed service provider                |
| 5   | `Admin`              | Concrete       | Platform supervisor                      |
| 6   | `Address`            | Entity         | Physical location for clients and agents |
| 7   | `UserDocument`       | Entity         | Uploaded verification documents          |
| 8   | `ServiceCatalogItem` | Entity         | Platform-managed service catalog         |
| 9   | `AgentService`       | Junction       | Agent-to-service subscription            |
| 10  | `Offer`              | Entity         | Admin-created promotional discounts      |
| 11  | `Booking`            | Aggregate Root | Unified service request                  |
| 12  | `BookingItem`        | Entity         | Line items within a booking              |
| 13  | `DeliveryTask`       | Entity         | Single leg of two-stage logistics        |
| 14  | `Payment`            | Entity         | Full payment record per booking          |
| 15  | `AuditLog`           | Entity         | Immutable admin action trail             |

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

---

## 4. Enumerations

### 4.1 `UserRole`

Discriminator for the `User` inheritance hierarchy.

| Value           | Description                     |
| --------------- | ------------------------------- |
| `Client`        | Customer placing bookings       |
| `DeliveryStaff` | Driver executing delivery tasks |
| `LaundryAgent`  | Licensed service provider       |
| `Admin`         | Platform supervisor             |

**Used in:** `User.Role`

---

### 4.2 `AccountStatus`

Governs the full lifecycle of a user account from registration through verification to potential suspension.

| Value                 | Description                                     | Triggered By            |
| --------------------- | ----------------------------------------------- | ----------------------- |
| `PendingVerification` | Registered, awaiting admin review               | Registration submission |
| `Active`              | Admin approved — account fully operational      | Admin action            |
| `Suspended`           | Temporarily disabled — cannot log in or operate | Admin action            |
| `Deactivated`         | Permanently closed                              | Admin action            |

**Used in:** `User.AccountStatus`
**Logic:** While `AccountStatus = PendingVerification`, `AgentService.IsActive` is ignored — no services are visible to clients regardless of their value.

---

### 4.3 `Gender`

Client gender selection at registration.

| Value    | Description |
| -------- | ----------- |
| `Male`   | Male        |
| `Female` | Female      |

**Used in:** `Client.Gender`

---

### 4.4 `VehicleType`

Type of vehicle operated by a delivery staff member. Affects task assignment eligibility.

| Value        | Description                                                   |
| ------------ | ------------------------------------------------------------- |
| `Car`        | Four-wheeled vehicle — suitable for large laundry loads       |
| `Motorcycle` | Two-wheeled — suitable for small loads, faster urban delivery |
| `TukTuk`     | Three-wheeled — medium capacity                               |

**Used in:** `DeliveryStaff.VehicleType`

---

### 4.5 `DocumentType`

Classifies uploaded verification documents per user role.

| Value                    | Required By                 | Description                         |
| ------------------------ | --------------------------- | ----------------------------------- |
| `NationalID`             | DeliveryStaff, LaundryAgent | Government-issued identity document |
| `DriverLicense`          | DeliveryStaff               | Valid driving license               |
| `VehicleImage`           | DeliveryStaff               | Photo of registered vehicle         |
| `CommercialRegistration` | LaundryAgent                | Business license document           |

**Used in:** `UserDocument.Type`

---

### 4.6 `ServiceCategory`

High-level grouping of all platform services. Used for UI filtering and agent profile classification.

| Value          | Description                                     |
| -------------- | ----------------------------------------------- |
| `Laundry`      | Clothing-related washing and ironing            |
| `HomeWovens`   | Large fabric items — curtains, carpets, bedding |
| `HomeServices` | On-site home maintenance services               |
| `VehicleWash`  | On-site car and motorcycle washing              |

**Used in:** `ServiceCatalogItem.Category`

---

### 4.7 `ServiceType`

Specific service type within its category. Every catalog item maps to exactly one type.

| Value                | Category     | Description                            |
| -------------------- | ------------ | -------------------------------------- |
| `WashAndIron`        | Laundry      | Full wash and press of clothing        |
| `DryClean`           | Laundry      | Chemical cleaning for delicate fabrics |
| `IronOnly`           | Laundry      | Ironing service without washing        |
| `Curtains`           | HomeWovens   | Curtain washing and finishing          |
| `Bedsheets`          | HomeWovens   | Bed linen washing                      |
| `Blankets`           | HomeWovens   | Blanket and duvet cleaning             |
| `Carpets`            | HomeWovens   | Carpet deep cleaning                   |
| `HomeCleaning`       | HomeServices | General residential cleaning           |
| `ACCleaning`         | HomeServices | Air conditioner deep service           |
| `WaterTankCleaning`  | HomeServices | Underground and overhead tank cleaning |
| `SolarPanelCleaning` | HomeServices | Solar panel surface cleaning           |
| `CarWash`            | VehicleWash  | Full car wash at client location       |
| `MotorcycleWash`     | VehicleWash  | Motorcycle wash at client location     |

**Used in:** `ServiceCatalogItem.Type`

---

### 4.8 `PricingModel`

Determines how `BookingItem.subTotal()` is computed.

| Value     | Formula                                          | Example                       |
| --------- | ------------------------------------------------ | ----------------------------- |
| `PerItem` | `Quantity × UnitPriceAtTimeOfBooking`            | 3 shirts × 2.500 KWD          |
| `FlatFee` | `UnitPriceAtTimeOfBooking` (quantity irrelevant) | AC cleaning = 15.000 KWD flat |

**Used in:** `ServiceCatalogItem.PricingModel`

---

### 4.9 `DeliveryModel`

The most operationally significant enum. Determines logistics behavior for each service type and drives whether `DeliveryTask` records are created.

| Value                | Tasks Created | Who Goes Where                                                                 |
| -------------------- | ------------- | ------------------------------------------------------------------------------ |
| `TwoStage`           | 2 tasks       | Driver collects items from client → agent processes → driver returns to client |
| `TechnicianDispatch` | 0 tasks       | Agent dispatches staff to client location; service performed on-site           |

**Used in:** `ServiceCatalogItem.DeliveryModel`

---

### 4.10 `BookingStatus`

State machine governing the full lifecycle of every booking. Transitions are strictly sequential.

| Value        | Description                                            | Triggered By    |
| ------------ | ------------------------------------------------------ | --------------- |
| `Pending`    | Submitted, awaiting agent acceptance                   | Client          |
| `Accepted`   | Agent confirmed — delivery tasks created if applicable | LaundryAgent    |
| `InProgress` | Work begun or technician dispatched                    | Agent / System  |
| `Ready`      | Processing complete — items ready for Stage 2          | LaundryAgent    |
| `Completed`  | Fully delivered or service performed                   | System          |
| `Cancelled`  | Terminated before completion                           | Client or Admin |

**Used in:** `Booking.Status`

---

### 4.11 `TaskType`

Identifies which stage of the two-stage delivery a task represents.

| Value              | Stage | Route                                   |
| ------------------ | ----- | --------------------------------------- |
| `PickupFromClient` | 1     | Client Address → Agent Business Address |
| `DeliveryToClient` | 2     | Agent Business Address → Client Address |

**Used in:** `DeliveryTask.Type`

---

### 4.12 `DeliveryTaskStatus`

Tracks the independent lifecycle of each delivery leg.

| Value        | `AssignedAt` | `DeliveryStaffID` | Description                    |
| ------------ | ------------ | ----------------- | ------------------------------ |
| `Unassigned` | null         | null              | In pool, no driver claimed yet |
| `Assigned`   | Populated    | Populated         | Driver claimed the task        |
| `InProgress` | Populated    | Populated         | Driver actively en route       |
| `Completed`  | Populated    | Populated         | Leg finished successfully      |

**Used in:** `DeliveryTask.Status`
**Rule:** Stage 2 cannot leave `Unassigned` until Stage 1 reaches `Completed`.

---

### 4.13 `PaymentMethod`

Payment channel used by the client.

| Value        | Pre-condition                      | Notes                            |
| ------------ | ---------------------------------- | -------------------------------- |
| `CreditCard` | `TransactionRef` must be populated | Processed via payment gateway    |
| `Cash`       | None                               | Physical cash to agent or driver |
| `Wallet`     | `Client.WalletBalance >= Amount`   | Deducted from platform wallet    |

**Used in:** `Payment.Method`

---

### 4.14 `PaymentStatus`

Outcome states of the single payment per booking.

| Value      | Terminal | Description                                 |
| ---------- | -------- | ------------------------------------------- |
| `Pending`  | No       | Payment initiated, awaiting confirmation    |
| `Success`  | Yes      | Payment confirmed and processed             |
| `Failed`   | Yes      | Payment attempt rejected                    |
| `Refunded` | Yes      | Successful payment reversed on cancellation |

**Used in:** `Payment.Status`

---

### 4.15 `OfferType`

Discount calculation method.

| Value         | Formula                              |
| ------------- | ------------------------------------ |
| `Percentage`  | `FinalTotal × (DiscountValue / 100)` |
| `FixedAmount` | `FinalTotal - DiscountValue`         |

**Used in:** `Offer.Type`

---

### 4.16 `OfferScope`

Controls which bookings an offer can be applied to.

| Value           | `LaundryAgentID` FK | Description                              |
| --------------- | ------------------- | ---------------------------------------- |
| `AllAgents`     | `NULL`              | Platform-wide — any booking qualifies    |
| `SpecificAgent` | Populated           | Only bookings handled by the named agent |

**Used in:** `Offer.Scope`

---

## 5. User Hierarchy

### 5.1 `User` (Abstract)

Root identity table shared across all actors. No concrete `User` record exists independently — every user belongs to exactly one subtype.

| Field             | Type          | Constraints                           | Description                           |
| ----------------- | ------------- | ------------------------------------- | ------------------------------------- |
| `UserID_PK`       | int           | PK, Auto-increment                    | Unique identifier across all subtypes |
| `FirstName`       | string        | NOT NULL                              | Legal first name                      |
| `LastName`        | string        | NOT NULL                              | Legal last (family) name              |
| `Email`           | string        | NOT NULL, UNIQUE                      | Login identifier                      |
| `PasswordHash`    | string        | NOT NULL                              | bcrypt/argon2 hash — never plaintext  |
| `PhoneNo`         | string        | NOT NULL, 9–10 digits                 | Contact number                        |
| `DateOfBirth`     | date          | NOT NULL                              | Used for age verification             |
| `ProfilePhotoURL` | string?       | NULLABLE                              | CDN URL of profile photo              |
| `TermsAccepted`   | boolean       | NOT NULL, DEFAULT false               | T&C acceptance at registration        |
| `AccountStatus`   | AccountStatus | NOT NULL, DEFAULT PendingVerification | Account lifecycle state               |
| `Role`            | UserRole      | NOT NULL                              | Inheritance discriminator             |
| `VerifiedAt`      | datetime?     | NULLABLE                              | Stamped when admin approves account   |
| `CreatedAt`       | datetime      | NOT NULL, DEFAULT NOW()               | Registration timestamp                |

**Password Policy (enforced pre-hash at application layer):**

- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 numeric digit

---

### 5.2 `Client`

The customer actor. Owns addresses, places bookings, and holds a platform wallet.

| Field            | Type    | Constraints                     | Description                                      |
| ---------------- | ------- | ------------------------------- | ------------------------------------------------ |
| `UserID_PK` (FK) | int     | PK, FK → User                   | Shared key under TPT                             |
| `Gender`         | Gender  | NOT NULL                        | Required at registration                         |
| `WalletBalance`  | decimal | NOT NULL, DEFAULT 0, CHECK >= 0 | Platform wallet — used for Wallet payment method |

**Relationships:**

- `Client "1" --> "0..*" Address` — owns delivery/service addresses
- `Client "1" --> "0..*" Booking` — places service bookings

---

### 5.3 `DeliveryStaff`

The logistics executor. Claims and completes delivery tasks from an open pool.

| Field              | Type        | Constraints      | Description                           |
| ------------------ | ----------- | ---------------- | ------------------------------------- |
| `UserID_PK` (FK)   | int         | PK, FK → User    | Shared key                            |
| `FatherName`       | string      | NOT NULL         | Four-part Arabic name                 |
| `GrandfatherName`  | string      | NOT NULL         | Four-part Arabic name                 |
| `NationalIDNumber` | string      | NOT NULL, UNIQUE | Government ID number                  |
| `VehicleType`      | VehicleType | NOT NULL         | Car, Motorcycle, or TukTuk            |
| `VehicleMake`      | string      | NOT NULL         | Vehicle manufacturer (e.g. Toyota)    |
| `VehicleModel`     | string      | NOT NULL         | Vehicle model (e.g. Corolla)          |
| `PlateNumber`      | string      | NOT NULL, UNIQUE | Vehicle registration plate            |
| `BankAcc`          | string      | NOT NULL         | Bank account for delivery fee payouts |

**Required Documents:** `NationalID`, `DriverLicense`, `VehicleImage`

**Relationships:**

- `DeliveryStaff "1" --> "0..*" DeliveryTask` — claims and executes tasks
- `User "1" --> "0..*" UserDocument` — uploads verification documents

---

### 5.4 `LaundryAgent`

The central service provider. Offers a platform-admin-approved subset of the service catalog across any combination of categories.

| Field                | Type   | Constraints      | Description                        |
| -------------------- | ------ | ---------------- | ---------------------------------- |
| `UserID_PK` (FK)     | int    | PK, FK → User    | Shared key                         |
| `FatherName`         | string | NOT NULL         | Four-part Arabic name              |
| `GrandfatherName`    | string | NOT NULL         | Four-part Arabic name              |
| `NationalIDNumber`   | string | NOT NULL, UNIQUE | Government ID number               |
| `BusinessName`       | string | NOT NULL         | Trading name of the business       |
| `CommercialRegister` | string | NOT NULL, UNIQUE | Government business license number |
| `BankAcc`            | string | NOT NULL         | Bank account for service revenue   |

**Required Documents:** `NationalID`, `CommercialRegistration`

**Relationships:**

- `LaundryAgent "1" --> "1" Address` — mandatory business location with GPS coordinates
- `LaundryAgent "1" --> "0..*" AgentService` — service subscriptions
- `Booking "0..*" --> "1" LaundryAgent` — receives bookings
- `Offer "0..*" --> "0..1" LaundryAgent` — may be the target of scoped offers

---

### 5.5 `Admin`

The sole platform supervisor. One instance. Manages all catalog, offers, users, and generates the audit trail.

| Field            | Type     | Constraints   | Description                   |
| ---------------- | -------- | ------------- | ----------------------------- |
| `UserID_PK` (FK) | int      | PK, FK → User | Shared key                    |
| `LastLoginAt`    | datetime | NULLABLE      | Security monitoring timestamp |

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

| Field          | Type    | Constraints             | Description                                  |
| -------------- | ------- | ----------------------- | -------------------------------------------- |
| `AddressID_PK` | int     | PK, Auto-increment      | Unique identifier                            |
| `Area`         | string  | NOT NULL                | Neighborhood or district                     |
| `Street`       | string  | NOT NULL                | Street name and number                       |
| `Latitude`     | decimal | NOT NULL                | GPS latitude — from map picker               |
| `Longitude`    | decimal | NOT NULL                | GPS longitude — from map picker              |
| `IsArchived`   | boolean | NOT NULL, DEFAULT false | Soft delete — hides address without deleting |

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

| Field           | Type         | Constraints             | Description                                                     |
| --------------- | ------------ | ----------------------- | --------------------------------------------------------------- |
| `DocumentID_PK` | int          | PK, Auto-increment      | Unique identifier                                               |
| `UserID_FK`     | int          | FK → User, NOT NULL     | Document owner                                                  |
| `Type`          | DocumentType | NOT NULL                | NationalID, DriverLicense, VehicleImage, CommercialRegistration |
| `FileURL`       | string       | NOT NULL                | CDN or storage URL of the uploaded file                         |
| `UploadedAt`    | datetime     | NOT NULL, DEFAULT NOW() | Upload timestamp                                                |

**Relationships:**

- `User "1" --> "0..*" UserDocument` — one user can have multiple documents

**Document Requirements by Role:**

| Role            | Required Documents                      |
| --------------- | --------------------------------------- |
| `DeliveryStaff` | NationalID, DriverLicense, VehicleImage |
| `LaundryAgent`  | NationalID, CommercialRegistration      |

**Note:** Document approval is determined by the overall `User.AccountStatus` transition — the admin reviews all documents together and approves or rejects the entire registration.

---

## 7. Catalog & Subscription

### 7.1 `ServiceCatalogItem`

The platform-wide service catalog. Every service across all categories exists as a row here. Admin-managed. Prices are fixed and uniform — no agent-level pricing.

| Field           | Type            | Constraints            | Description                                      |
| --------------- | --------------- | ---------------------- | ------------------------------------------------ |
| `ServiceID_PK`  | int             | PK, Auto-increment     | Unique identifier                                |
| `ServiceName`   | string          | NOT NULL               | Display name (e.g. "Air Conditioner Deep Clean") |
| `Category`      | ServiceCategory | NOT NULL               | Laundry, HomeWovens, HomeServices, VehicleWash   |
| `Type`          | ServiceType     | NOT NULL               | Specific service type                            |
| `Price`         | decimal         | NOT NULL, CHECK > 0    | Platform-fixed price — same for all agents       |
| `PricingModel`  | PricingModel    | NOT NULL               | PerItem or FlatFee                               |
| `DeliveryModel` | DeliveryModel   | NOT NULL               | TwoStage or TechnicianDispatch                   |
| `IsAvailable`   | boolean         | NOT NULL, DEFAULT true | Admin can disable platform-wide                  |

**Relationships:**

- `Admin "1" --> "0..*" ServiceCatalogItem` — admin is sole owner
- `ServiceCatalogItem "1" --> "0..*" AgentService` — subscribed to by agents
- `BookingItem "0..*" --> "1" ServiceCatalogItem` — referenced by booking line items

---

### 7.2 `AgentService` (Junction)

Resolves the many-to-many relationship between `LaundryAgent` and `ServiceCatalogItem`. Enables flexible agent profiles — each agent activates only the services they are approved to offer.

| Field                 | Type     | Constraints                       | Description                                    |
| --------------------- | -------- | --------------------------------- | ---------------------------------------------- |
| `AgentServiceID_PK`   | int      | PK, Auto-increment                | Unique identifier                              |
| `LaundryAgentID` (FK) | int      | FK → LaundryAgent, NOT NULL       | The subscribing agent                          |
| `ServiceID` (FK)      | int      | FK → ServiceCatalogItem, NOT NULL | The catalog service                            |
| `IsActive`            | boolean  | NOT NULL, DEFAULT false           | false = pending/suspended, true = live         |
| `ActivatedAt`         | datetime | NULLABLE                          | Stamped when admin sets IsActive = true        |
| `Notes`               | string?  | NULLABLE                          | Optional scope notes (e.g. "Residential only") |

**Unique Constraint:** `(LaundryAgentID, ServiceID)` — an agent cannot subscribe to the same service twice.

**State Logic:**

| `User.AccountStatus`  | `AgentService.IsActive` | Client Visibility    |
| --------------------- | ----------------------- | -------------------- |
| `PendingVerification` | `false`                 | Not visible          |
| `Active`              | `true`                  | Visible and bookable |
| `Active`              | `false`                 | Not visible          |
| `Suspended`           | Any                     | Not visible          |

**Agent Profile Examples:**

| Agent Type         | Active AgentService Records                   |
| ------------------ | --------------------------------------------- |
| Laundry Only       | WashAndIron, DryClean, IronOnly               |
| Full Service       | WashAndIron + HomeCleaning + ACCleaning + ... |
| Vehicle Specialist | CarWash, MotorcycleWash                       |

---

## 8. Booking System

### 8.1 `Offer`

Admin-created promotional discounts. Validity is fully derived — no manual activation needed.

| Field                 | Type       | Constraints                 | Description                                                                                     |
| --------------------- | ---------- | --------------------------- | ----------------------------------------------------------------------------------------------- |
| `OfferID_PK`          | int        | PK, Auto-increment          | Unique identifier                                                                               |
| `OfferCode`           | string     | NOT NULL, UNIQUE            | Alphanumeric code entered by client                                                             |
| `Type`                | OfferType  | NOT NULL                    | Percentage or FixedAmount                                                                       |
| `Scope`               | OfferScope | NOT NULL                    | AllAgents or SpecificAgent                                                                      |
| `DiscountValue`       | decimal    | NOT NULL, CHECK > 0         | Magnitude of discount                                                                           |
| `StartDate`           | datetime   | NOT NULL                    | Offer becomes valid from this moment                                                            |
| `EndDate`             | datetime   | NOT NULL                    | Offer expires after this moment                                                                 |
| `MinOrderValue`       | decimal?   | NULLABLE, CHECK > 0         | Minimum booking total required                                                                  |
| `MaxUsageCount`       | int?       | NULLABLE, CHECK > 0         | Usage cap — null means unlimited                                                                |
| `UsageCount`          | int        | NOT NULL, DEFAULT 0         | Running counter — incremented atomically                                                        |
| `LaundryAgentID` (FK) | int?       | NULLABLE, FK → LaundryAgent | Null when Scope = AllAgents                                                                     |
| `/isValid()`          | bool       | Derived                     | `now >= StartDate AND now <= EndDate AND (MaxUsageCount IS NULL OR UsageCount < MaxUsageCount)` |

**Constraints:**

- `DiscountValue` must be between 1–100 when `Type = Percentage`
- A `SpecificAgent` offer cannot be applied to a booking handled by a different agent
- `UsageCount` incremented atomically to prevent race conditions

---

### 8.2 `Booking`

The aggregate root of the platform. Every service request — regardless of category — is a `Booking`. Connects all transactional entities.

| Field                 | Type          | Constraints                 | Description                                      |
| --------------------- | ------------- | --------------------------- | ------------------------------------------------ |
| `BookingID_PK`        | int           | PK, Auto-increment          | Unique identifier                                |
| `ClientID` (FK)       | int           | FK → Client, NOT NULL       | The placing client                               |
| `LaundryAgentID` (FK) | int           | FK → LaundryAgent, NOT NULL | The handling agent                               |
| `AddressID` (FK)      | int           | FK → Address, NOT NULL      | Service or delivery location                     |
| `OfferID` (FK)        | int?          | NULLABLE, FK → Offer        | Applied discount if any                          |
| `Status`              | BookingStatus | NOT NULL, DEFAULT Pending   | Lifecycle state                                  |
| `FinalTotal`          | decimal       | NOT NULL, CHECK >= 0        | Locked at creation — never recalculated          |
| `CreatedAt`           | datetime      | NOT NULL, DEFAULT NOW()     | Booking creation timestamp                       |
| `ScheduledAt`         | datetime?     | NULLABLE                    | Required when DeliveryModel = TechnicianDispatch |
| `SpecialInstructions` | string?       | NULLABLE                    | Access codes, notes for agent staff              |

**Constraints:**

- `FinalTotal` is computed and locked at creation — immune to future price changes
- `ScheduledAt` is mandatory for all `TechnicianDispatch` service bookings
- Status transitions are strictly sequential — no skipping or reversal except to `Cancelled`
- Cancellation must reverse `Offer.UsageCount` if an offer was applied

---

### 8.3 `BookingItem`

Individual line items within a booking. Cannot exist without their parent booking (composition).

| Field                      | Type    | Constraints                       | Description                                            |
| -------------------------- | ------- | --------------------------------- | ------------------------------------------------------ |
| `BookingItemID_PK`         | int     | PK, Auto-increment                | Unique identifier                                      |
| `BookingID` (FK)           | int     | FK → Booking, NOT NULL            | Parent booking (composition)                           |
| `ServiceID` (FK)           | int     | FK → ServiceCatalogItem, NOT NULL | Referenced catalog service                             |
| `Quantity`                 | int     | NOT NULL, CHECK >= 1              | Units requested                                        |
| `UnitPriceAtTimeOfBooking` | decimal | NOT NULL, CHECK > 0               | Price snapshot — never updated                         |
| `/subTotal()`              | decimal | Derived                           | `PerItem: Quantity × UnitPrice` / `FlatFee: UnitPrice` |

**Constraints:**

- `UnitPriceAtTimeOfBooking` copied from `ServiceCatalogItem.Price` at booking creation — never modified
- `subTotal()` is always computed, never stored
- All items must reference services in the agent's active `AgentService` subscriptions

---

## 9. Delivery System

### 9.1 `DeliveryTask`

Represents one leg of the two-stage physical logistics chain. Only created for bookings containing `TwoStage` services. Exactly two tasks per qualifying booking — Stage 1 and Stage 2.

| Field                   | Type               | Constraints                  | Description                          |
| ----------------------- | ------------------ | ---------------------------- | ------------------------------------ |
| `TaskID_PK`             | int                | PK, Auto-increment           | Unique identifier                    |
| `BookingID` (FK)        | int                | FK → Booking, NOT NULL       | Parent booking                       |
| `DeliveryStaffID` (FK)  | int?               | NULLABLE, FK → DeliveryStaff | Null until driver claims task        |
| `PickupAddressID` (FK)  | int                | FK → Address, NOT NULL       | Origin of this leg                   |
| `DropoffAddressID` (FK) | int                | FK → Address, NOT NULL       | Destination of this leg              |
| `StageNumber`           | int                | NOT NULL, CHECK IN (1, 2)    | 1 = Pickup, 2 = Delivery             |
| `Type`                  | TaskType           | NOT NULL                     | PickupFromClient or DeliveryToClient |
| `Status`                | DeliveryTaskStatus | NOT NULL, DEFAULT Unassigned | Task lifecycle state                 |
| `DeliveryFee`           | decimal            | NOT NULL, CHECK >= 0         | Fee paid to driver for this leg      |
| `AssignedAt`            | datetime?          | NULLABLE                     | Stamped when driver claims task      |
| `CompletedAt`           | datetime?          | NULLABLE                     | Stamped when driver marks complete   |

**Address Mapping per Stage:**

| Stage                        | `PickupAddressID`       | `DropoffAddressID`      |
| ---------------------------- | ----------------------- | ----------------------- |
| Stage 1 — `PickupFromClient` | Client `Address`        | Agent `BusinessAddress` |
| Stage 2 — `DeliveryToClient` | Agent `BusinessAddress` | Client `Address`        |

**Constraints:**

- Stage 2 `Status` cannot leave `Unassigned` until Stage 1 `Status = Completed`
- `DeliveryStaffID` is null at creation — set atomically when driver claims from pool
- One driver can only have one `InProgress` task at a time (application-layer enforcement)

---

## 10. Payment System

### 10.1 `Payment`

Records the single full payment for a booking. The `UNIQUE` constraint on `BookingID` enforces the one-payment-per-booking policy at the database level.

| Field            | Type          | Constraints                    | Description                                  |
| ---------------- | ------------- | ------------------------------ | -------------------------------------------- |
| `PaymentID_PK`   | int           | PK, Auto-increment             | Unique identifier                            |
| `BookingID` (FK) | int           | FK → Booking, NOT NULL, UNIQUE | Enforces one payment per booking             |
| `Amount`         | decimal       | NOT NULL, CHECK > 0            | Must equal `Booking.FinalTotal`              |
| `Method`         | PaymentMethod | NOT NULL                       | CreditCard, Cash, or Wallet                  |
| `Status`         | PaymentStatus | NOT NULL, DEFAULT Pending      | Payment outcome state                        |
| `TransactionRef` | string        | NULLABLE                       | Gateway reference — mandatory for CreditCard |
| `PaidAt`         | datetime      | NULLABLE                       | Stamped on Status = Success                  |

**Business Rules:**

- Full payment only — no installments or partial payments
- `Amount` validated against `Booking.FinalTotal` before record creation
- `Wallet` payment requires `Client.WalletBalance >= Amount`
- `Refunded` is a terminal state — no further transitions permitted
- A `Failed` payment allows retry — a new `Payment` record is created only if no `Success` record exists

---

## 11. Administration & Audit

### 11.1 `AuditLog`

Immutable record of every privileged admin action. Append-only — no UPDATE or DELETE operations permitted on this table.

| Field          | Type     | Constraints             | Description                                        |
| -------------- | -------- | ----------------------- | -------------------------------------------------- |
| `LogID_PK`     | int      | PK, Auto-increment      | Unique identifier                                  |
| `AdminID` (FK) | int      | FK → Admin, NOT NULL    | Performing admin                                   |
| `Action`       | string   | NOT NULL                | Action key (e.g. `ACTIVATE_AGENT`, `CREATE_OFFER`) |
| `TargetEntity` | string   | NOT NULL                | Affected table (e.g. `User`, `Offer`)              |
| `TargetID`     | int      | NOT NULL                | PK of the affected record                          |
| `PerformedAt`  | datetime | NOT NULL, DEFAULT NOW() | Server-side timestamp — not application clock      |

**Constraints:**

- No UPDATE or DELETE on this table — insert only
- `PerformedAt` set by database server clock — not application layer
- `TargetEntity + TargetID` form a soft polymorphic reference — no hard FK

---

## 12. Relationship Map

| #   | From                 | Cardinality    | To                   | Label         | Type        |
| --- | -------------------- | -------------- | -------------------- | ------------- | ----------- |
| 1   | `User`               | 1 ◄──          | `Client`             | is-a          | Inheritance |
| 2   | `User`               | 1 ◄──          | `DeliveryStaff`      | is-a          | Inheritance |
| 3   | `User`               | 1 ◄──          | `LaundryAgent`       | is-a          | Inheritance |
| 4   | `User`               | 1 ◄──          | `Admin`              | is-a          | Inheritance |
| 5   | `User`               | 1 ──► 0..\*    | `UserDocument`       | uploads       | One-to-Many |
| 6   | `Client`             | 1 ──► 0..\*    | `Address`            | has           | One-to-Many |
| 7   | `Client`             | 1 ──► 0..\*    | `Booking`            | places        | One-to-Many |
| 8   | `LaundryAgent`       | 1 ──► 1        | `Address`            | located at    | One-to-One  |
| 9   | `LaundryAgent`       | 1 ──► 0..\*    | `AgentService`       | subscribes to | One-to-Many |
| 10  | `ServiceCatalogItem` | 1 ──► 0..\*    | `AgentService`       | offered by    | One-to-Many |
| 11  | `Admin`              | 1 ──► 0..\*    | `ServiceCatalogItem` | manages       | One-to-Many |
| 12  | `Admin`              | 1 ──► 0..\*    | `Offer`              | creates       | One-to-Many |
| 13  | `Admin`              | 1 ──► 0..\*    | `AuditLog`           | generates     | One-to-Many |
| 14  | `Offer`              | 0..\* ──► 0..1 | `LaundryAgent`       | scoped to     | One-to-Many |
| 15  | `Booking`            | 0..\* ──► 1    | `LaundryAgent`       | handled by    | One-to-Many |
| 16  | `Booking`            | 0..\* ──► 1    | `Address`            | located at    | One-to-Many |
| 17  | `Booking`            | 1 ──►◆ 1..\*   | `BookingItem`        | contains      | Composition |
| 18  | `Booking`            | 0..\* ──► 0..1 | `Offer`              | applies       | One-to-Many |
| 19  | `Booking`            | 1 ──► 0..1     | `Payment`            | paid by       | One-to-One  |
| 20  | `Booking`            | 1 ──► 0..2     | `DeliveryTask`       | may require   | One-to-Many |
| 21  | `BookingItem`        | 0..\* ──► 1    | `ServiceCatalogItem` | references    | One-to-Many |
| 22  | `DeliveryStaff`      | 1 ──► 0..\*    | `DeliveryTask`       | assigned to   | One-to-Many |
| 23  | `DeliveryTask`       | 0..\* ──► 1    | `Address`            | pickup from   | One-to-Many |
| 24  | `DeliveryTask`       | 0..\* ──► 1    | `Address`            | dropoff to    | One-to-Many |

---

## 13. Business Rules

### Payment Rules

- One payment per booking — enforced by `UNIQUE` constraint on `Payment.BookingID`
- Full payment only — no installments or partial amounts
- `Amount` must equal `Booking.FinalTotal` before payment record is created
- Wallet payment requires sufficient `Client.WalletBalance`

### Delivery Rules

- `TwoStage` bookings generate exactly 2 `DeliveryTask` records at `Booking.Status = Accepted`
- `TechnicianDispatch` bookings generate 0 `DeliveryTask` records
- Stage 2 remains `Unassigned` until Stage 1 is `Completed`
- Different drivers may handle Stage 1 and Stage 2 of the same booking

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

### Agent Service Rules

- Only admin can activate or deactivate `AgentService` records
- Clients only see services where both `AccountStatus = Active` and `AgentService.IsActive = true`
- All `BookingItem` records must reference services in the agent's active subscriptions

---

## 14. Delivery Model Matrix

| Service            | Category     | DeliveryModel      | Tasks | ScheduledAt  | Agent Action        |
| ------------------ | ------------ | ------------------ | ----- | ------------ | ------------------- |
| WashAndIron        | Laundry      | TwoStage           | 2     | Not required | Process clothes     |
| DryClean           | Laundry      | TwoStage           | 2     | Not required | Process clothes     |
| IronOnly           | Laundry      | TwoStage           | 2     | Not required | Iron clothes        |
| Curtains           | HomeWovens   | TwoStage           | 2     | Not required | Wash curtains       |
| Bedsheets          | HomeWovens   | TwoStage           | 2     | Not required | Wash bedding        |
| Blankets           | HomeWovens   | TwoStage           | 2     | Not required | Wash blankets       |
| Carpets            | HomeWovens   | TwoStage           | 2     | Not required | Clean carpets       |
| HomeCleaning       | HomeServices | TechnicianDispatch | 0     | **Required** | Dispatch cleaner    |
| ACCleaning         | HomeServices | TechnicianDispatch | 0     | **Required** | Dispatch technician |
| WaterTankCleaning  | HomeServices | TechnicianDispatch | 0     | **Required** | Dispatch technician |
| SolarPanelCleaning | HomeServices | TechnicianDispatch | 0     | **Required** | Dispatch technician |
| CarWash            | VehicleWash  | TechnicianDispatch | 0     | **Required** | Dispatch washer     |
| MotorcycleWash     | VehicleWash  | TechnicianDispatch | 0     | **Required** | Dispatch washer     |

---

## 15. Booking Status State Machine

```
                    ┌─────────┐
                    │ Pending │  ◄── Client places booking
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

         ──────── Cancelled ◄── Available from any non-terminal state
```

---

## 16. Registration Compatibility

### Compatibility Score: 95 / 100

### Field Coverage by Role

| Field               | Client                          | DeliveryStaff                       | LaundryAgent                               |
| ------------------- | ------------------------------- | ----------------------------------- | ------------------------------------------ |
| First Name          | ✅ `User.FirstName`             | ✅ `User.FirstName`                 | ✅ `User.FirstName`                        |
| Last Name           | ✅ `User.LastName`              | ✅ `User.LastName`                  | ✅ `User.LastName`                         |
| Father Name         | —                               | ✅ `DeliveryStaff.FatherName`       | ✅ `LaundryAgent.FatherName`               |
| Grandfather Name    | —                               | ✅ `DeliveryStaff.GrandfatherName`  | ✅ `LaundryAgent.GrandfatherName`          |
| Email               | ✅ `User.Email`                 | ✅ `User.Email`                     | ✅ `User.Email`                            |
| Phone               | ✅ `User.PhoneNo`               | ✅ `User.PhoneNo`                   | ✅ `User.PhoneNo`                          |
| Password            | ✅ `User.PasswordHash`          | ✅ `User.PasswordHash`              | ✅ `User.PasswordHash`                     |
| Date of Birth       | ✅ `User.DateOfBirth`           | ✅ `User.DateOfBirth`               | ✅ `User.DateOfBirth`                      |
| Gender              | ✅ `Client.Gender`              | —                                   | —                                          |
| GPS Location        | ✅ `Address.Latitude/Longitude` | —                                   | ✅ `Address.Latitude/Longitude`            |
| Address String      | ✅ `Address.Area + Street`      | —                                   | ✅ `Address.Area + Street`                 |
| Terms Accepted      | ✅ `User.TermsAccepted`         | ✅ `User.TermsAccepted`             | ✅ `User.TermsAccepted`                    |
| Vehicle Type        | —                               | ✅ `DeliveryStaff.VehicleType`      | —                                          |
| Plate Number        | —                               | ✅ `DeliveryStaff.PlateNumber`      | —                                          |
| National ID Number  | —                               | ✅ `DeliveryStaff.NationalIDNumber` | ✅ `LaundryAgent.NationalIDNumber`         |
| ID Image            | —                               | ✅ `UserDocument (NationalID)`      | ✅ `UserDocument (NationalID)`             |
| License Image       | —                               | ✅ `UserDocument (DriverLicense)`   | —                                          |
| Vehicle Image       | —                               | ✅ `UserDocument (VehicleImage)`    | —                                          |
| Business Name       | —                               | —                                   | ✅ `LaundryAgent.BusinessName`             |
| Commercial Register | —                               | —                                   | ✅ `LaundryAgent.CommercialRegister`       |
| Reg. Document Image | —                               | —                                   | ✅ `UserDocument (CommercialRegistration)` |
| Service Selection   | —                               | —                                   | ✅ `AgentService` junction                 |
