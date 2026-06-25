# Reliability Test Checklist

Use this short checklist before final submission or demos.

## Menu

- Add, edit, delete, and restart the app to confirm menu changes persist.
- Toggle an item unavailable and confirm it disappears from New Order selection.
- Confirm unavailable/deleted items still appear in old orders through snapshots.
- In release mode, confirm the debug-only sample menu button is not visible.

## Orders

- Create a new order with multiple items and confirm it appears as Pending.
- Try creating a second active order for the same table and confirm it is blocked.
- Move a Pending order to another available table.
- Try moving a Pending order to an occupied table and confirm it is blocked.
- Edit item quantities in a Pending order and confirm totals update.
- Remove all items from a Pending edit and confirm update is blocked.
- Cancel a Pending order and confirm the order disappears from Orders.

## Status lifecycle

- Advance an order through Pending, Preparing, Served, and Paid.
- Confirm Preparing, Served, and Paid orders cannot be edited or cancelled.
- Confirm Paid orders do not block table reuse.
- Open the same Pending order on two screens, advance it on one, then try editing/cancelling on the stale screen.

## Failure and persistence

- Disable network and try create, edit, cancel, and status update; confirm data remains on screen after failure.
- Restart the app after create/edit/cancel/status changes and confirm Firestore data is still consistent.
- Confirm old order item names/prices stay unchanged after editing the Menu item price/name.
