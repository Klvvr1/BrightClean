# Delivery Staff Use Cases Specification

**System:** Delivery Management System (Bright Clean)  
**Actor:** Delivery Staff  
**Description:** The Delivery Staff represents the logistical personnel responsible for executing pickup and drop-off tasks between the client and the service provider.

## Use Case Index

### 1. Authentication & Onboarding

- **Register:** Allows a new driver to apply for the platform.
  - `«include»` **Add Personal Information:** Mandatory step to collect vehicle and contact data.
  - `«extend»` **Show Error Message:** Triggered if data validation fails.
  - `«extend»` **Rejected:** Triggered if the admin denies the registration application.
- **Login:** Access the driver application.
  - `«include»` **Verify Account:** Ensures only approved, active drivers can access the system.
  - `«extend»` **Show Error Message:** Triggered on invalid credentials.
- **Logout:** Securely end the active session.

### 2. Update Profile

- **Description:** Allows the driver to modify personal details, banking information, or vehicle status.

### 3. View Orders

- **Description:** The primary interface for the driver to manage their logistical queue.
- **Relationships:**
  - `«extend»` **View Current Orders:** Filters the view to show active, assigned tasks.
  - `«extend»` **View Previous Orders:** Filters the view to show completed historical tasks.

### 4. Update Delivery Status

- **Description:** The core operational task for a driver to log the physical movement of an order.
- **Specific Sub-Tasks (Generalization):**
  - **Mark as Under Preparation:** _(Note: Architecturally, this task should belong to the Laundry Manager, not the driver. Consider revising to "Confirm Pickup")._
  - **Mark as In Progress:** Indicates the driver is en route with the items.
  - **Mark as In Delivery:** Indicates the driver has reached the destination and is handing over the items.
