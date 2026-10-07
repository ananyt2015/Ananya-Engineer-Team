# Commenting guide

Every engineer on the team writes comments so that the next developer, opening this code with no access to the spec, the ticket discussion, or this conversation, understands what the code does and why it is written this way.

## Style comes from the project

Use the comment and docstring format in `.dev-team/STANDARDS.md` (Comments and documentation). If it doesn't specify one, match the code around your change; in a new codebase use the language default: Google-style docstrings for Python, TSDoc/JSDoc for JavaScript and TypeScript.

## What to comment

**New files and modules.** A short header saying what the module is responsible for and how it fits in, when the file name alone doesn't make that obvious.

**Public functions, classes, and components.** A docstring that says what it does, its inputs, what it returns, the errors it raises, and any side effects (writes to the database, sends email, calls an external API, mutates shared state).

**Non-obvious logic: the why.** Comment wherever a capable developer would otherwise stop and ask "why is it like this?":
- Business rules, with the requirement ID (`FR-12`) or ticket key (`PROJ-142`) they come from
- Edge cases handled deliberately, and what happens if they weren't
- Ordering that matters, locking, transactions, idempotency
- Workarounds for library bugs or external API quirks, with a link to the issue
- Security checks, so nobody "simplifies" them away
- Performance choices that make the code less obvious than the naive version
- Magic numbers and limits: where they come from and what breaks if they change
- AI code: what a prompt is designed to make the model do, and why a model or parameter was chosen

**Configuration and migrations.** What a setting controls and safe values; what a migration changes and whether it's reversible.

## What not to write

- **Comments that restate the code.** `# increment counter` above `counter += 1` adds nothing.
- **Change history.** No "added by…", "changed for ticket…", "fixed bug where…", "updated to use…". Comments describe the code as it is now; the history of what was done goes in the commit message and PR description.
- **References to `.dev-team/`** or other local-only files. Other developers don't have them. Cite requirement IDs, ticket keys, or committed docs instead.
- **Commented-out code.** Delete it; git keeps it.
- **Bare TODOs.** Every TODO names a ticket or a follow-up the user agreed to: `# TODO(PROJ-201): paginate once the API supports cursors`.

## Keep comments true

When you change code, update or delete the comments it makes wrong, including comments near your change that you didn't write. A wrong comment is worse than none.

## Examples

```python
def reserve_stock(order_id: str, items: list[LineItem]) -> Reservation:
    """Reserve inventory for every line in an order, all or nothing.

    Args:
        order_id: The order the reservation belongs to; used as the idempotency key.
        items: Lines to reserve. Quantities must be positive.

    Returns:
        The reservation, including its expiry time.

    Raises:
        OutOfStockError: If any line can't be fully reserved. Nothing is reserved in that case.
    """
    # Lock rows in SKU order so two concurrent orders for the same SKUs can't deadlock.
    skus = sorted(item.sku for item in items)
    ...
    # FR-21: unpaid reservations expire after 15 minutes so abandoned carts release stock.
    expires_at = now() + timedelta(minutes=15)
```

```ts
/**
 * Debounced search box for the product catalogue.
 *
 * Waits 300 ms after the last keystroke before querying, because the search
 * endpoint is rate-limited per user (PROJ-88). Shows the previous results
 * while a new query is in flight to avoid layout jumps.
 */
export function CatalogueSearch({ onSelect }: CatalogueSearchProps) {
```
