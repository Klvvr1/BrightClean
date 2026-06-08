# BrightClean Project Map

## Current Surgical Remediation Notes

### Phase 1
- Agent registration service binding now parses `RegisterAgentDto.SelectedServiceIds` as a comma-separated form field through `ParseSelectedServiceIds`.
- `DeliveryStaff.IsAvailable` stores driver work mode in SQL Server.
- `GET /api/deliverytasks/availability` returns the current driver's work mode.
- `PATCH /api/deliverytasks/availability` persists the current driver's work mode.
- `GET /api/deliverytasks/my` returns tasks assigned to the current driver, including completed tasks.
- Flutter `DriverProvider` merges delivery pool tasks with the driver's own task history so completed tasks remain visible.

### Phase 2
- `GET /api/addresses` returns the authenticated client's active saved addresses.
- `POST /api/addresses` rejects empty addresses and invalid `0,0` coordinates.
- `DELETE /api/addresses/{addressId}` archives the authenticated client's address without deleting historical booking references.
- Flutter customer address screens load, add, and delete addresses through the backend instead of `SharedPreferences`.
- Cart and checkout require a valid backend-backed `addressID` before booking/payment flow can proceed.

### Phase 3
- `GET /api/admin/recent-orders` returns real recent non-draft bookings for the admin dashboard.
- Flutter admin dashboard displays real recent orders or a clean empty state.
- Driver dashboard task statistics are derived from real delivery task data instead of static earnings.
- Customer home reviews/testimonials carousel was removed from the visible home screen to avoid showing local-only SQLite reviews as real system reviews.
