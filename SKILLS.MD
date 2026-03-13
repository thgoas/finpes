# Technical Skills Matrix

During the development of this API, the following skills, tools, and architectural concepts were applied:

## Language & Framework
* **Elixir:** Applied functional programming concepts, pattern matching, pipeline operators (`|>`), and basic concurrency.
* **Phoenix Framework:** Designed API architecture, routing (pipelines and scopes), Controllers, and JSON response rendering.
* **Plugs:** Built custom HTTP middleware to intercept and authorize incoming requests (`init/1` and `call/2`).

## Database & ORM (Ecto)
* **Migrations:** Created and altered database schemas in PostgreSQL utilizing `binary_id` (UUIDs).
* **Schemas & Changesets:** Implemented data validation, unique constraints (`unique_constraint`), and virtual fields (`virtual: true`).
* **Data Manipulation:** Manipulated data safely within the Ecto pipeline using functions like `put_change/3` before database insertion.
* **SaaS Database Architecture:** Designed extensible schemas prepared for monetization, handling roles (`plan_role`) and third-party payment gateway integrations (`payment_gateway_id`).
* **Error Handling & Traversal:** Utilized `Ecto.Changeset.traverse_errors/2` to format complex internal database validation errors into readable, user-friendly JSON responses for frontend consumption.
* **Data Lifecycle (Cast vs. Validate):** Deep understanding of Ecto's validation pipeline, correctly handling early rejection of invalid data types during the `cast/3` phase before reaching custom validations.
* **Financial Data Modeling:** Applied the "Integer-Cent Pattern" to handle currency, avoiding floating-point precision issues inherent in monetary calculations.
* **Tenant Isolation:** Enforced strict multi-tenant data boundaries at the Context layer, ensuring queries are strictly scoped to the authenticated `user_id`.
* **Domain-Driven Validations:** Translated complex business requirements (e.g., the 50/30/20 budgeting methodology) into robust database constraints using Ecto's `validate_inclusion/3` and custom error mappings.
* **Cross-Entity Validation:** Designed secure Ecto Context pipelines that validate ownership of related entities (e.g., ensuring a Wallet belongs to the current User) before allowing inserts or updates, preventing cross-tenant ID spoofing.
* **Dynamic Cascade Rules:** Configured distinct Ecto Migration constraint behaviors (`on_delete: :delete_all` vs. `on_delete: :nilify_all`) to match precise real-world business logic requirements for data retention.

## Security & Cryptography
* **Argon2:** Implemented state-of-the-art password hashing to protect against brute-force and hardware attacks.
* **Phoenix.Token:** Generated and verified cryptographically signed, lightweight tokens.
* **Session Management:** Designed opaque tokens (persisted in the database) to allow strict server-side session revocation.
* **XSS & CSRF Mitigation:** Strategically utilized `HttpOnly`, `Secure`, and `SameSite` cookies instead of standard `localStorage` to protect Web clients.
* **Authentication vs. Authorization:** Clear architectural separation between verifying *who* the user is (ApiAuth Plug) and *what* they are allowed to do (RequirePlan Plug).
* **Role-Based Access Control (RBAC):** Implementation of subscription-tier access control at the routing level, preventing privilege escalation.

## Network & API Architecture
* **CORS (Cross-Origin Resource Sharing):** Configured allowed origins, methods, and enabled credential transmission (`allow_credentials: true`) via the `corsica` library.
* **BFF (Backend for Frontend) Pattern:** Designed dynamic endpoints that adapt their authentication delivery method based on the client type (`client_type: "web" | "mobile"`).
* **Seamless Onboarding Flows:** Designed UX-optimized endpoints (e.g., auto-login upon registration) by securely passing authentication state immediately after resource creation.
* **API Usability & Localization:** Implemented custom error message translations directly at the Schema validation layer, ensuring the JSON responses are immediately actionable and user-friendly for frontend clients.

## Automated Testing (ExUnit)
* **TDD / BDD Concepts:** Wrote test suites using ExUnit's `test` and `setup` macros.
* **ConnCase (Integration Tests):** Simulated complex HTTP requests, injecting headers and cookies to test Controller and Plug behavior.
* **DataCase (Unit Tests):** Isolated testing of business logic, database constraints, and Ecto Changesets.
* **Middleware/Plug Testing:** Wrote isolated unit tests for custom Plugs, manipulating the `%Plug.Conn{}` struct to simulate authorized and unauthorized states.
* **End-to-End Pipeline Testing:** Validated the correct stacking of Router pipelines (Authentication -> Authorization -> Controller) to ensure airtight premium routes.
* **Context vs. Controller Testing:** Successfully isolated business logic (Context tests ensuring database integrity and tenant isolation) from web delivery logic (Controller tests validating JSON responses and HTTP status codes like 422 Unprocessable Entity).
## Elixir Fundamentals
* **Map Normalization:** Handled the "Mixed Keys" pitfall (String vs. Atom keys) by normalizing data structures with `Map.new/2` prior to database insertion, improving interoperability between tests and web controllers.
## Software Architecture & Design Patterns
* **Ledger Design:** Applied core principles of Double-Entry Bookkeeping to database schema design, utilizing tracking IDs (`transfer_id`) to maintain mathematical consistency in cross-wallet fund movements.
* **Edge-Case Modeling:** Solved complex personal finance edge cases (Pass-Through Transactions) natively at the database layer to preserve the integrity of future analytical reporting.