# Laundry Manager Use Cases Specification

**System:** Laundry Management System (Bright Clean)  
**Actor:** Laundry Manager (Service Provider / Vendor)  
**Description:** The Laundry Manager represents the commercial entity (Vendor) that receives the physical items, performs the required cleaning/washing services, and prepares them for dispatch.

## Use Case Index

### 1. Authentication & Onboarding

- **Register:** Allows a new vendor to apply to join the platform.
  - `«include»` **Add Personal Information:** Mandatory step to collect business registration and banking data.
  - `«extend»` **Show Error Message:** Triggered on invalid form submission.
  - `«extend»` **Rejected:** Triggered if the business application is denied by the Admin.
- **Login:** Access the vendor dashboard.
  - `«include»` **Verify Account:** Ensures the business account is active and approved.
  - `«extend»` **Show Error Message:** Triggered on invalid credentials.
- **Logout:** Securely end the session.

### 2. Update Profile

- **Description:** Allows the vendor to update business hours, location details, or contact information.

### 3. View Orders

- **Description:** The operational queue where the vendor monitors incoming service requests.
- **Relationships:**
  - `«extend»` **View Current Orders:** Displays orders that are pending, accepted, or currently being processed.
  - `«extend»` **View Previous Orders:** Displays the history of completed and dispatched orders.

### 4. Update Laundry Status

- **Description:** The core responsibility of the vendor to track the internal progress of the service.
- **Specific Sub-Tasks (Generalization):**
  - **Mark as Under Preparation:** Indicates the items have been received and the service (e.g., washing, dry cleaning) has begun.
  - **Mark as Completed:** Indicates the service is finished and the items are packaged and ready for the Delivery Staff to collect.
