# Customer Use Cases Specification

**System:** Laundry Service Management System (Bright Clean)  
**Actor:** Customer (Client)  
**Description:** The Customer is the end-user of the platform. They are responsible for initiating transactions by requesting services, managing their personal profiles, tracking the progress of their orders, and completing payments.

## Use Case Index

### 1. Authentication & Onboarding

- **Register:** Allows a new customer to create an account.
  - `«include»` **Add Personal Information:** Mandatory step to collect name, phone number, and initial delivery address.
  - `«extend»` **Show Error Message:** Triggered on invalid input (e.g., weak password, duplicate email).
- **Login:** Access the customer application.
  - `«include»` **Verify Account:** Ensures the account is verified (e.g., via OTP) before granting access.
  - `«extend»` **Show Error Message:** Triggered on incorrect credentials.
- **Logout:** Securely end the active session on the device.

### 2. Account Management

- **Update Profile:** Allows the customer to modify personal details, default addresses, or view their `WalletBalance`.

### 3. Order Management (Core Operations)

- **Place Order:** The primary transaction. Allows the customer to select services (e.g., Wash & Iron), specify quantities (OrderItems), and set pickup/drop-off locations.
- **Track Order:** Allows the customer to view the real-time status of an active order (e.g., Pending, InWashing, Ready) and track the Delivery Staff en route.
- **Cancel Order:**
  - `«extend»` **Apply Cancellation Fee:** Triggered only if the order is canceled after a certain status (e.g., after a driver has been dispatched).
- **View Orders:**
  - `«extend»` **View Current Orders:** Displays active, uncompleted orders.
  - `«extend»` **View Previous Orders:** Displays the history of completed or canceled orders.

### 4. Financial Operations

- **Make Payment:** The process of paying for the `FinalTotal` of an order.
  - `«include»` **Select Payment Method:** The user must choose a method (Credit Card, Cash, or Wallet).
  - `«extend»` **Apply Offer/Coupon:** An optional flow where the user inputs a promotional code to reduce the total cost before final payment.
