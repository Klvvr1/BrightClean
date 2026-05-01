# Admin Use Cases Specification

**System:** Laundry Service Admin System (Bright Clean)  
**Actor:** Admin  
**Description:** The Admin represents the central operational authority of the platform, responsible for maintaining system configurations, overseeing orders, managing financial promotions, and onboarding new staff or service providers.

## Use Case Index

### 1. Admin Login

- **Description:** Allows the administrator to securely access the system dashboard.
- **Relationships:**
  - `«include»` **Validate Credentials:** The system must strictly validate the input against the database before granting access.
  - `«extend»` **Display Error Message:** If validation fails, the system presents an appropriate error message to the user.

### 2. Manage System Settings

- **Description:** Enables the admin to configure global platform parameters (e.g., service areas, global pricing rules, or commission rates).

### 3. Manage Promotions & Coupons

- **Description:** Allows the admin to create, edit, or disable financial incentives (Offers/Coupons) that apply to client orders.

### 4. Manage Orders

- **Description:** Provides a centralized view of all transactions, allowing the admin to monitor order statuses, intervene in disputes, or override delivery assignments if necessary.

### 5. Review Job Application

- **Description:** The process for evaluating onboarding requests from prospective Laundry Managers (Vendors) or Delivery Staff.
- **Relationships:**
  - `«extend»` **Accept:** Triggered if the application meets all criteria.
  - `«extend»` **Reject:** Triggered if the application fails to meet standards or is incomplete.

### 6. System Maintenance

- **Description:** Allows the admin to perform critical backend tasks, such as triggering database backups or enabling "maintenance mode" during updates.
