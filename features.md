# Coffee Stock App — Feature Matrix

Snapshot of the current Coffee Stock implementation. Each feature is marked as **Done**, **In progress**, or **Planned** so the team can see what still needs work.

---

## Table of contents

1. [Overview](#overview)
2. [Roles](#roles)
3. [Customer (User) Features](#customer-user-features)
4. [Employee Features](#employee-features)
5. [Admin Features](#admin-features)
6. [Core Technical Architecture](#core-technical-architecture)
7. [Firebase / Database Structure](#firebase--database-structure)
8. [Bonus / Advanced Ideas](#bonus--advanced-ideas)
9. [Milestones & To-do](#milestones--to-do)

---

## Overview

The Coffee Stock product focuses on three pillars:

- ✅ **Menu & ordering (cart)**
- ✅ **Inventory / stock management**
- ✅ **Feedback & ratings**

The app is built with Flutter + Firebase, using Provider for state management, Firestore for realtime data, Firebase Auth for authentication, and Firebase Storage for media. This document tracks feature coverage and gaps against the original spec.

---

## Roles

- ✅ **Admin** — full access; menu, stock, analytics, user management
- ✅ **Employee** — handles live orders, can view stock and history
- ✅ **Customer** — browses menu, orders, leaves feedback

---

## Customer (User) Features

| Feature | Status | Notes |
| --- | --- | --- |
| Menu categories & listing | ✅ Done | Menu screen with realtime stream and availability flag |
| Menu search | ✅ Done | Client-side filtering in `MenuScreen` |
| Product details (image, description, price) | ✅ Done | Includes average rating display |
| Product size options | ✅ Done | Small/Medium/Large selection stored in cart |
| Real-time availability indicator | ✅ Done | Unavailable items hidden; admin toggle |
| Cart totals & quantity management | ✅ Done | Cart provider aggregates total in TND |
| Promo codes | 🔜 Planned | Not implemented |
| Order type (Dine-in / Takeaway) | ✅ Done | Selection in checkout |
| Order placement & confirmation | ✅ Done | Creates order + redirects to status |
| Real-time order status tracking | ✅ Done | `OrderStatusScreen` listens to document |
| Payments (cash) | ✅ Done | Flow assumes in-person payment |
| Payments (Stripe/PayPal) | 🔜 Planned | Online payments not integrated |
| Feedback submission | ✅ Done | Ratings and comments stored; average recalculated |
| Customer profile editing | 🔜 Planned | Profile screen scaffolding exists |
| Order history & reordering | 🔜 Planned | `getMyOrders()` ready; UI pending |

---

## Employee Features

| Feature | Status | Notes |
| --- | --- | --- |
| Orders dashboard | ✅ Done | Live stream + status updates |
| Customer notifications | 🔜 Planned | Push notifications pending backend |
| Print / ticket view | 🔜 Planned | No printing integration |
| Stock overview | ✅ Done | Shared stock screen via drawer |
| Low-stock alerts | ✅ Done | Threshold indicator and badges |
| Shortage reporting | ✅ Done | Dialog creates Firestore report |
| Stock usage logging | ✅ Done | History entries created automatically |

---

## Admin Features

| Feature | Status | Notes |
| --- | --- | --- |
| Dashboard analytics UI | 🔜 Planned | Data service exists; UI in progress |
| Menu management CRUD | ✅ Done | Add/edit/delete/availability toggle |
| Menu images upload | 🔜 Planned | Admin form currently accepts URLs only |
| Recipe linkage | ✅ Done | Recipes stored per menu item |
| Inventory CRUD | ✅ Done | Existing module retained |
| Low-stock thresholds | ✅ Done | Threshold field + alerts |
| Auto stock decrement on completed orders | ✅ Done | Triggered when status becomes Completed |
| Stock export (CSV/PDF) | ✅ Done | Admin menu export action |
| User list & role updates | ✅ Done | Admin can change roles/delete users |
| Feedback moderation | 🔜 Planned | Feedback data accessible; UI pending |
| Audit trail | ✅ Partial | Stock history captures inventory changes |

---

## Core Technical Architecture

| Layer | Status | Notes |
| --- | --- | --- |
| Firebase Auth (email/password) | ✅ Done | Includes password reset; Google sign-in planned |
| Roles (`admin`, `employee`, `customer`) | ✅ Done | Role-aware routing & drawer |
| Firestore (realtime) | ✅ Done | Collections: users, menuItems, orders, feedbacks, stock, history, shortageReports, orderForecasts |
| Firebase Storage | ✅ Partial | Used for stock images; menu images pending |
| Cloud Functions / Edge Functions | 🔜 Planned | Consider for stock decrement & notifications |
| Push notifications (FCM) | 🔜 Planned | Not integrated |
| Payments (Stripe/PayPal) | 🔜 Planned | Listed as enhancement |
| Analytics dashboard | 🔜 Planned | Service scaffolded; UI pending |

---

## Firebase / Database Structure

Collections currently deployed:

- `users`: uid, email, username, role, createdAt
- `menuItems`: name, description, price (TND), category, images[], available, rating, recipe[]
- `stock`: quantity, unite, shortageThreshold, misAJourLe
- `orders`: customerId, items[{menuItemId, quantity, options}], totalPrice, status, orderType, createdAt, updatedAt
- `feedbacks`: userId, menuItemId?, rating, comment, createdAt
- `history`: inventory history entries with delta, userId, email, timestamps
- `shortageReports`: productId, comment, resolved flag
- `orderForecasts`: admin planning entries

---

## Bonus / Advanced Ideas

- Loyalty / rewards program
- QR code menu for quick ordering in-store
- AI-driven stock prediction / auto reorder suggestions
- Sales forecasting dashboard
- Offline-first caching & sync
- Google Sign-In and social auth
- Push notifications & email receipts

---

## Milestones & To-do

- ✅ Define detailed product data model (recipes, ratings, options)
- ✅ Implement authentication & role-based routing
- ✅ Implement menu browsing and product pages
- ✅ Implement cart and order flow (customer)
- ✅ Implement orders dashboard (employee)
- ✅ Implement inventory linkage to menu recipes (auto stock decrement)
- ✅ Implement feedback & rating system
- ✅ Export / reporting (stock CSV/PDF)
- 🔜 Google Sign-In + social auth
- 🔜 Customer order history UI & profile editing
- 🔜 Push notifications & Cloud Functions (order & shortage alerts)
- 🔜 Online payments integration (Stripe/PayPal)
- 🔜 Admin analytics dashboard UI

---

*Document last updated: {{DATE}}*
# Coffee Shop App — Full Feature Set

> Adjustable markdown file. Edit the sections below to suit your project.

---

## Table of contents

1. [Overview](#overview)
2. [Roles](#roles)
3. [Customer (User) Features](#customer-user-features)
4. [Employee (Barista / Waiter) Features](#employee-features)
5. [Admin (Manager / Owner) Features](#admin-features)
6. [Core Technical Architecture](#core-technical-architecture)
7. [Firebase / Database Structure (Suggested)](#firebase--database-structure-suggested)
8. [Bonus / Advanced Ideas](#bonus--advanced-ideas)
9. [Milestones & To-do](#milestones--to-do)

---

## Overview

This document describes a complete coffee shop application combining:

* **Menu & ordering (cart)**
* **Inventory / stock management**
* **Feedback & ratings**

Use it as the spec for a Flutter + Firebase (or Supabase) implementation. Update sections marked `TODO` and use the checkboxes to track progress.

---

## Roles

* **Admin** — manager / owner (full access)
* **Employee** — barista / waiter (order handling, stock reporting)
* **Customer** — app user who places orders and leaves feedback

---

## Customer (User) Features

* **Home / Menu**

  * Browse menu by category (Coffee, Drinks, Snacks, Pastries, etc.)
  * Search items
  * Product details: image, description, price, ingredients, size options, availability
  * Real-time availability indicator (e.g., "Out of stock")

* **Cart & Ordering**

  * Add items with options and quantities
  * Cart summary and total price
  * Promo code support (optional)
  * Choose order type: Dine-in / Takeaway
  * Place order and receive order confirmation
  * Real-time order status updates (Pending → Preparing → Ready → Completed)

* **Payments**

  * Cash on delivery / in-store
  * Optional: integrate Stripe / PayPal for online payments

* **Feedback & Ratings**

  * Rate the café or a specific product (1–5 stars)
  * Leave comments
  * Display average rating on product pages

* **Profile & History**

  * Edit profile (name, photo, email)
  * View order history and receipts
  * Reorder previous items

---

## Employee Features

* **Orders Dashboard**

  * View new orders in real time
  * Update order status (Preparing → Ready → Completed)
  * Notify customers when orders are ready
  * Print / view order tickets

* **Stock Overview & Reporting**

  * View current ingredient stock levels
  * Receive low-stock alerts
  * Report shortages to admin with comments
  * Log stock usage per shift or per order

---

## Admin Features

* **Global Dashboard**

  * Overview cards: total sales, best-selling items, low-stock alerts, recent updates
  * Analytics: daily/weekly revenue, product popularity, inventory trends

* **Menu Management**

  * Add / edit / delete menu items2
  * Link menu items to ingredient recipes (e.g., Cappuccino → 200ml milk + 20g coffee)
  * Mark items available / unavailable
  * Upload product images

* **Inventory Management**

  * Add / edit / delete stock items (ingredients)
  * Track ingredient quantities and units
  * Set low-stock thresholds and receive alerts
  * Auto-decrement ingredient stock when orders are completed
  * Export stock reports (CSV / PDF)

* **User & Role Management**

  * Add / remove employees
  * Assign roles and permissions
  * Audit actions by user (who updated what and when)

* **Feedback & Support**

  * View and filter customer feedback
  * Respond to feedback (optional)
  * Generate satisfaction / feedback reports

---

## Core Technical Architecture

* **Authentication**: Firebase Auth or Supabase Auth

  * Roles: `admin`, `employee`, `customer`
* **Realtime DB**: Firestore (or Supabase Realtime)
* **Storage**: Cloud Storage for images
* **Serverless functions** (Cloud Functions / Edge Functions) for:

  * Updating ingredient stock on order completion
  * Sending push notifications (order status, low-stock alerts)
  * Generating daily reports
* **Push notifications**: Firebase Cloud Messaging (FCM)
* **Optional**: Payment integration (Stripe), analytics, and email receipts

---

## Firebase / Database Structure (Suggested)

> Adapt this structure to your needs. Use subcollections where helpful.

**Collections:**

* `users` (document per user)

  * `id` (uid)
  * `name`
  * `email`
  * `role` (admin | employee | customer)
  * `photoUrl`
  * `createdAt`

* `menuItems` (document per product)

  * `id`
  * `name`
  * `description`
  * `price`
  * `images` (array)
  * `category`
  * `available` (bool)
  * `rating` (avg)
  * `recipe` (array of {ingredientId, qtyNeeded, unit})

* `ingredients` (document per stock item)

  * `id`
  * `name`
  * `quantity` (current amount)
  * `unit` (ml, g, pcs)
  * `threshold` (low-stock warning)
  * `lastUpdated`

* `orders` (document per order)

  * `id`
  * `customerId`
  * `items` (array of {menuItemId, quantity, options})
  * `totalPrice`
  * `status` (Pending, Preparing, Ready, Completed, Cancelled)
  * `orderType` (Dine-in, Takeaway)
  * `createdAt`
  * `updatedAt`

* `feedbacks` (document per feedback)

  * `id`
  * `userId`
  * `menuItemId` (nullable)
  * `rating` (1-5)
  * `comment`
  * `createdAt`

* `auditLogs` (optional)

  * `action`
  * `userId`
  * `itemId`
  * `timestamp`
  * `meta`

---

## Bonus / Advanced Ideas

* Loyalty / rewards program (points per order)
* QR code menu for quick ordering in-store
* AI-based stock prediction (when to reorder)
* Sales forecasting dashboard
* Offline mode (cache menu & orders locally, sync later)

---

## Milestones & To-do

* [ ] Define detailed product data model (images, options, recipes)
* [ ] Implement authentication & role-based routing
* [ ] Implement menu browsing and product pages
* [ ] Implement cart and order flow (customer)
* [ ] Implement orders dashboard (employee)
* [ ] Implement inventory linkage to menu recipes
* [ ] Implement push notifications and serverless functions
* [ ] Implement feedback & rating system
* [ ] Export / reporting features

---

## Next steps

1. Update the **Firebase structure** section if you prefer different naming or nesting.
2. Decide which features are *MVP* vs *nice-to-have* and tick the Milestones.
3. If you want, I can generate:

   * A ready-to-use **Firestore rules** skeleton,
   * The **Flutter UI component list** and wireframes, or
   * The **API contract** (endpoints / requests / responses) for your backend.

---

*Document created: Coffee Shop App — Full Feature Set*
