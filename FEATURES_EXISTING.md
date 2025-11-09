# Coffee Stock — Existing Features

> Snapshot of what is implemented and functional in the current app.

---

## Roles & Access
- Admin: Full access, menu and inventory management, user roles
- Employee: Orders dashboard to process orders and update status
- Customer: Browse menu, add to cart, place orders, track order status
- Role-based navigation on login (admin → dashboard, employee → orders, customer → menu)

---

## Customer Features
- Menu & Product
  - Browse available menu items (realtime)
  - Search by name/description
  - Product details: image, description, price, rating display
  - Basic product options: size (Small/Medium/Large)
- Cart & Ordering
  - Add to cart (persists selected size)
  - Cart summary and total
  - Select order type: Dine-in / Takeaway
  - Place order and redirect to order-status screen
- Order Status
  - Realtime status updates (Pending → Preparing → Ready → Completed/Cancelled)
- Feedback
  - Submit rating (1–5) and optional comment per product
  - Display product feedback list
  - Average rating aggregated to product on submit

---

## Employee Features
- Orders Dashboard
  - Realtime stream of active orders
  - Update order status (Pending/Preparing/Ready/Completed/Cancelled)
  - Tap to view the specific order status screen

---

## Admin Features
- Menu Management
  - List all menu items
  - Add / edit / delete menu items
  - Toggle availability
- Inventory Management
  - Stock items: add/edit/delete (existing module)
  - Shortage threshold on items
  - Stock history recorded on inventory changes
  - Auto stock decrement on Order Completed based on menu item recipes
- Users & Roles
  - List users (existing module)
  - Update user role, delete user
- Exports
  - Export stock to CSV / PDF from admin menu (quick access action)

---

## Technical Architecture
- Flutter + Firebase
  - Firebase Auth: email/password (with reset from login), role-based routing
  - Firestore: `menuItems`, `orders`, `feedbacks`, `users`, `stock`, `history`, `shortageReports`, `orderForecasts`
  - Storage service integrated (image picker/upload used by stock module; menu form currently uses image URLs)
- State management: Provider
- Realtime streams for menu, orders, history, shortage reports
- Theming: Light/Dark themes

---

## Not Yet Implemented / Optional
- Google Sign-In (planned)
- Push notifications (FCM) for order updates and low-stock alerts
- Cloud Functions for secure, atomic stock decrement and notifications (currently client-side)
- Payments integration (Stripe/PayPal)
- Customer order history screen (using existing `getMyOrders()` service)
- Admin analytics UI (service exists; surface in dashboard)
- Feedback moderation/filter UI for admin

---

## Key Screens & Routes
- Customer: `/user/menu`, `/user/product`, `/user/cart`, `/user/order-status`
- Employee: `/employee/orders`
- Admin: `/admin/dashboard`, `/admin/menu`, `/admin/menu/edit`, stock & user management screens
- Auth: `/login`, `/signup`, profile screen

---

Last updated: Auto-generated features snapshot

