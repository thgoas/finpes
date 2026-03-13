This is a web application written using the Phoenix web framework.

## Implemented Features: Finpes (SaaS Personal Finance) API

We are building "Finpes", a SaaS API designed for Personal Finance management. It features a robust, hybrid authentication architecture serving both Web (React/Vite) and Mobile (Flutter) clients securely.

* **API-Only Setup:** Built on a Phoenix API-only foundation (`--no-html`, `--no-assets`).
* **SaaS Data Modeling (Ecto):** * Configured `users` and `user_tokens` tables utilizing `binary_id` (UUIDs).
  * Added SaaS-specific columns to the `users` table: `plan_role` (defaults to "free") and `payment_gateway_id` (indexed for fast webhook lookups from Stripe/Pagar.me).
* **Security & Validations:** * Integrated `argon2_elixir` for state-of-the-art password hashing. 
  * Enforced strict Ecto Changeset validations (regex for strong passwords, unique email constraints, minimum length).
  * Implemented a custom error formatter (`traverse_errors`) to return clean, localized error messages to the frontend.
* **Seamless Onboarding (Auto-Login):** The `POST /api/register` endpoint automatically logs the user in upon successful creation, generating the session token immediately without requiring a secondary login request.
* **Hybrid Token Strategy:** * Utilized `Phoenix.Token` for lightweight, cryptographically signed session tokens.
  * Tokens are persisted in the database, allowing for instant, server-side revocation.
* **Custom Authentication Middleware:** Created `FinpesWeb.Plugs.ApiAuth`, a custom Plug that dynamically authenticates requests by extracting credentials from either **Cookies** (Web) or the **Authorization: Bearer** header (Mobile).
* **CORS & Web Security:** * Configured `corsica` to securely handle cross-origin requests.
  * Mitigated XSS (Cross-Site Scripting) attacks for Web clients by delivering tokens via `HttpOnly`, `Secure`, and `SameSite=Lax` cookies.
* **Role-Based Access Control (RBAC) & SaaS Authorization:**
  * Implemented a custom authorization middleware (`FinpesWeb.Plugs.RequirePlan`) to protect premium routes.
  * The Plug dynamically checks the authenticated user's `plan_role` (e.g., "pro", "premium") against the allowed plans for a specific route pipeline.
  * Successfully differentiates between Authentication (`401 Unauthorized` for missing/invalid tokens) and Authorization (`403 Forbidden` for valid users without the required subscription plan).
  * Built integration tests (`ProAccessTest`) to guarantee that premium endpoints (like `/api/pro/dashboard`) are strictly shielded from "free" tier users, ensuring a secure monetization architecture.
* **Phase 1: Financial Core - Wallets:**
  * Engineered the `Wallet` entity within an isolated `Finance` context to manage user checking accounts, savings, and credit cards, resolving naming collisions with user authentication.
  * **Zero-Float Policy:** Implemented a strict integer-only database architecture for currency (`initial_balance` is stored in cents) to completely eliminate decimal rounding errors (e.g., the "Lost Cent Problem").
  * **Strict Tenant Isolation:** Built the Context and Controller logic to enforce that all database queries and mutations require the authenticated `user_id`, guaranteeing cross-tenant data security.
  * **Resilient Data Transformation:** Ensured seamless key conversion (Atoms to Strings) at the Context layer, allowing the API to gracefully handle internal Elixir map structures and external JSON payloads.
  * Exposed a fully secure RESTful JSON API (`GET`, `POST`, `PUT`, `DELETE`) under the `/api/wallets` endpoint.
* **Phase 2: Financial Core - Categories:**
  * Engineered the `Category` entity within the `Finance` context to classify and organize user transactions.
  * **Smart Budgeting (50/30/20 Rule):** Implemented a `classification` field strictly validated against `essential`, `optional`, and `savings`. This domain-level rule empowers the frontend to generate advanced financial health analytics automatically.
  * **Data Integrity & Localization:** Enforced strict Ecto validations for category types (`income` or `expense`) and classifications, successfully mapping backend database constraints to localized, user-friendly error messages for the frontend.
  * **Consistent Tenant Isolation:** Replicated the strict `user_id` scoping to guarantee that users can create, modify, and view exclusively their own custom categories.
  * Exposed a secure RESTful JSON API (`GET`, `POST`, `PUT`, `DELETE`) under the `/api/categories` endpoint.
* **Phase 3: Financial Core - Transactions:**
  * Developed the central `Transaction` entity connecting Users, Wallets, and Categories.
  * **Pass-Through Expenses (The "Third-Party" Problem):** Engineered an `ignore_in_reports` boolean flag, allowing users to track expenses made on behalf of others (e.g., lending a credit card) without corrupting their personal 50/30/20 financial health charts.
  * **Double-Entry Ledger Foundation:** Implemented a `transfer_id` field to support atomic, mirrored transactions between wallets (e.g., transferring funds from checking to savings) maintaining perfect zero-sum balances.
  * **Advanced Cross-Entity Tenant Isolation:** Hardened the Context layer to explicitly verify Wallet ownership prior to transaction insertion, completely neutralizing ID-spoofing attacks across tenants.
  * **Smart Foreign Key Constraints:** Configured dynamic database constraints: deleting a Wallet cascades to delete its transactions (`delete_all`), while deleting a Category gracefully preserves the financial record (`nilify_all`).
  * Exposed a secure RESTful JSON API (`GET`, `POST`, `PUT`, `DELETE`) under the `/api/transactions` endpoint.

---

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

### Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">)`) class with your own values, no default classes are inherited, so your
custom classes must fully style the input

## Elixir guidelines

- Elixir lists **do not support index based access via the access syntax**

  **Never do this (invalid)**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Instead, **always** use `Enum.at`, pattern matching, or `List` for index based list access, ie:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

- Elixir variables are immutable, but can be rebound, so for block expressions like `if`, `case`, `cond`, etc
  you *must* bind the result of the expression to a variable if you want to use it and you CANNOT rebind the result inside the expression, ie:

      # INVALID: we are rebinding inside the `if` and the result never gets assigned
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID: we rebind the result of the `if` to a new variable
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- **Never** nest multiple modules in the same file as it can cause cyclic dependencies and compilation errors
- **Never** use map access syntax (`changeset[:field]`) on structs as they do not implement the Access behaviour by default. For regular structs, you **must** access the fields directly, such as `my_struct.field` or use higher level APIs that are available on the struct if they exist, `Ecto.Changeset.get_field/2` for changesets
- Elixir's standard library has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards
- Elixir's builtin OTP primitives like `DynamicSupervisor` and `Registry`, require names in the child spec, such as `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then you can use `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. The majority of times you will want to pass `timeout: :infinity` as option

## Mix guidelines

- Read the docs and options before using tasks (by using `mix help task_name`)
- To debug test failures, run tests in a specific file with `mix test test/my_test.exs` or run all previously failed tests with `mix test --failed`
- `mix deps.clean --all` is **almost never needed**. **Avoid** using it unless you have good reason

## Test guidelines

- **Always use `start_supervised!/1`** to start processes in tests as it guarantees cleanup between tests
- **Avoid** `Process.sleep/1` and `Process.alive?/1` in tests
  - Instead of sleeping to wait for a process to finish, **always** use `Process.monitor/1` and assert on the DOWN message:

      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

   - Instead of sleeping to synchronize before the next call, **always** use `_ = :sys.get_state/1` to ensure the process has handled prior messages
## Phoenix guidelines

- Remember Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.

- You **never** need to create your own `alias` for route definitions! The `scope` provides the alias, ie:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  the UserLive route would point to the `AppWeb.Admin.UserLive` module

- `Phoenix.View` no longer is needed or included with Phoenix, don't use it
## Ecto Guidelines

- **Always** preload Ecto associations in queries when they'll be accessed in templates, ie a message that needs to reference the `message.user.email`
- Remember `import Ecto.Query` and other supporting modules when you write `seeds.exs`
- `Ecto.Schema` fields always use the `:string` type, even for `:text`, columns, ie: `field :name, :string`
- `Ecto.Changeset.validate_number/2` **DOES NOT SUPPORT the `:allow_nil` option**. By default, Ecto validations only run if a change for the given field exists and the change value is not nil, so such as option is never needed
- You **must** use `Ecto.Changeset.get_field(changeset, :field)` to access changeset fields
- Fields which are set programatically, such as `user_id`, must not be listed in `cast` calls or similar for security purposes. Instead they must be explicitly set when creating the struct
- **Always** invoke `mix ecto.gen.migration migration_name_using_underscores` when generating migration files, so the correct timestamp and conventions are applied