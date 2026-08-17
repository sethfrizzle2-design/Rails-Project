# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

Rails 6.1 on Ruby 2.6.9 (rbenv), SQLite, Webpacker 5, Turbo (turbo-rails 1.5, no Stimulus), Bootstrap,
Highcharts. Minitest with fixtures. Gems install into `./home` (`BUNDLE_PATH: "home"` in `~/.bundle/config`),
so `home/` is a vendored gem tree, not application code — same for `Rails-Project/`, `node_modules/`, and the
stray `buses`/`readme` files at the root. All are excluded in `.rubocop.yml`.

## Commands

```bash
bundle exec rails s                 # dev server; webpacker compiles on demand (compile: true)
bin/webpack-dev-server              # optional, for JS hot reload
bundle exec rails test              # full suite (parallelized by processor count)
bundle exec rails test test/controllers/responses_controller_test.rb          # one file
bundle exec rails test test/controllers/responses_controller_test.rb:8        # one test by line
bundle exec rails test -n "/chart draws/"                                     # by name pattern
bundle exec rubocop                 # lint (rubocop pinned to 1.49.x, last release supporting Ruby 2.6)
bundle exec rubocop -a              # safe autocorrect
bin/rails db:prepare                # creates/migrates BOTH databases
bin/rails db:seed                   # generates 100 fake responses for "Better Test Form" via faker
```

`bin/rails` runs through Spring. Spring caches app code, so after changing an initializer or `config/`,
`bin/spring stop`.

## Two databases

`config/database.yml` defines `primary` and `secondary` per environment:

| | primary | secondary |
|---|---|---|
| dev file | `db/development.sqlite3` | `db/buses.sqlite3` |
| migrations | `db/migrate` | `db/secondary_migrate` |
| schema | `db/schema.rb` | `db/secondary_schema.rb` |

`SecondaryRecord` (`app/models/secondary_record.rb`) is the abstract base that `connects_to` the secondary
database; `Bus` is its only real subclass. Everything else inherits `ApplicationRecord`. New migrations for
buses need `bin/rails g migration Name --database secondary`; per-database tasks are
`db:migrate:primary` / `db:migrate:secondary`. `db/other_schema.rb` is a leftover empty schema — ignore it.

## Authentication

Hand-rolled, no Devise. `User` uses `has_secure_password`; `SessionsController#create` looks the user up by
downcased email, calls `reset_session`, and stores `session[:current_user_id]`.

`ApplicationController` applies `before_action :require_login` **globally** and includes the `Authenticated`
concern, which exposes `current_user` / `user_signed_in?` as helper methods. Consequences:

- A controller that must be reachable while signed out has to `skip_before_action :require_login`
  (only `SessionsController` does today).
- Every controller/integration test needs a `POST login_path` in `setup` (see
  `test/controllers/responses_controller_test.rb`); `test/fixtures/users.yml` provides `tester` and `admin`
  with password `secret123`.
- Admin-only actions gate on `user_admin?` in a controller-local `require_admin` (see `BusesController`).

Note that `Authenticated#current_user` writes `current_user ||= User.find_by(...)` to a local, so it
memoizes nothing and re-queries on each call — RuboCop flags it as `Lint/UselessAssignment`.

## Form builder → response → chart pipeline

This is the core feature and it spans four controllers.

**Authoring** (`FormsController#new`, `app/views/forms/new.html.erb`): one `Form` `has_many :questions`,
each `Question` `has_many :options` (ordered by `:id` — that order is load-bearing for both the answer
choices and the chart slices). Saved in a single request through nested attributes.

Rows are added and removed client-side without JS of our own: `questions#create`, `questions#remove`,
`options#create`, `options#remove` render `.erb` **Turbo Stream** templates that append `fields_for` partials
or remove a target element. DOM ids are derived from `object_id` of the newly built model
(`"question_#{question_form.object.object_id}"`), and the remove links pass that id as `?target=`.

**Question format** is a plain string column with exactly three meaningful values: `"Number"`, `"Text"`,
`"Multiple Choice"`. These strings are hard-coded in the format `<select>` in
`app/views/questions/_question.html.erb`, in the per-format branches of the response and builder views, in
`ResponsesController::CHARTABLE_FORMATS`, and in `ChartsHelper#question_chart_tag`. Changing or adding a
format means touching all of them.

**Responding** (`ResponsesController#new` + `app/views/responses/new.html.erb`): a `Response` has many
`Input`s via nested attributes. Inputs denormalize `question_id` and `question_words`, and a `Response` is
tied to its form by the **`form_name` string**, not a foreign key — an earlier migration deliberately removed
`form_id`. Queries therefore read `Response.where(form_name: form.name)`.

**Charting** (`ResponsesController#chart`, `ChartsHelper`, `app/views/responses/chart.html.erb`): the
controller builds plain hashes (`{id:, format:, title:, data:}`) — no chart markup in the controller. Answer
counts come from **one** grouped query for all selected questions (`answer_counts`), not one per question.
Multiple Choice keeps the question's own option order and keeps zero-count options; Number sorts numerically;
Text is capped at the 15 most common answers with the cap named in the title. `question_ids` absent means
"first look, chart everything"; present-but-empty means the user unchecked everything, which is why the
filter form always submits a blank `question_ids[]`.

`ChartsHelper` renders each chart as `div[data-highchart]` holding JSON options, then `chart_script_tag`
emits the one script that instantiates them. Highcharts comes from a CDN `<script>` in the layout (Chartkick
is imported in the pack but the response charts use Highcharts directly). **Always pass
`chart_script_tag scope: "<frame id>"` when the charts live inside a turbo frame** — Turbo re-runs the script
on every frame replacement, so an unscoped selector redraws charts outside the frame, and the helper also
destroys Highcharts instances whose containers Turbo discarded (otherwise detached SVGs leak).

## Turbo frame conventions

Nearly every page is a picker plus a frame: a `form_with ... data: {turbo_frame: "X"}` that submits into a
`turbo_frame_tag "X"`, usually with `onchange: "this.form.requestSubmit()"` on the select. Navigation
buttons in the layout and on the home page must break out with `form: { data: { turbo_frame: "_top" } }`,
otherwise the whole page loads inside a frame.

## Conventions and known rough edges

- Ruby is indented **4 spaces**, uses double quotes, and indents `private` helpers one extra step;
  `.rubocop.yml` encodes all of this, along with `Metrics` disabled and a 120-column limit.
- ERB is loosely formatted (`<%end%>`, inline styles, Bootstrap 4 and 5 class names mixed). Match the
  surrounding file rather than reformatting.
- Several views still do their own querying and paging in ERB (`responses/show.html.erb` computes offsets
  and page links inline; `builders/show.html.erb` and `responses/new.html.erb` call `Form.find_by` in the
  view). Pagy is wired into `ApplicationController`/`ApplicationHelper` but nothing uses it yet.
- Controllers contain no-op ivar statements such as a bare `@form` (RuboCop `Lint/Void`); they are
  placeholders, and the real assignment usually happens in the view.
- `rubocop` currently reports 7 pre-existing offenses. Fix offenses in code you touch rather than adding
  excludes or a todo file.
- Only `responses_controller_test.rb` and `testsites_controller_test.rb` have real tests; the rest are
  generated stubs.