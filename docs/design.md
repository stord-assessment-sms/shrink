# Design Decisions

History and motive for technical design decisions.

<!-- vim-markdown-toc GFM -->

* [Tech Stack](#tech-stack)
  * [Dependencies](#dependencies)
* [Scope Additions](#scope-additions)
  * [Code Quality Tooling](#code-quality-tooling)
  * [Testing Helpers](#testing-helpers)
  * [Partial User Modeling](#partial-user-modeling)
  * [Caching](#caching)
  * [Hourly/Daily Stats](#hourlydaily-stats)
    * [Debouncing](#debouncing)
* [Scope Omissions](#scope-omissions)
  * [BEAM Clustering](#beam-clustering)
  * [Resistance to Misuse](#resistance-to-misuse)
  * [Realtime UIs](#realtime-uis)
    * [Stats Table Interactivity](#stats-table-interactivity)
  * [Visual Design](#visual-design)

<!-- vim-markdown-toc -->

## Tech Stack

I chose a familiar and relatively basic tech stack:

- Erlang 26.2.3
- Elixir 1.16.2
- Phoenix 1.7
  - Bandit
- Ecto + EctoSQL
- PostgreSQL 15.6

### Dependencies

I've also supplemented with some other Hex packages that I have commonly reached
for in past work:

- Cachex
- Credo
- Dialyzer + Dialyxir
- EasyHTML
- ExcellentMigrations
- ExMachina
- NimbleCSV
- Styler
- `tailwind_formatter`

## Scope Additions

### Code Quality Tooling

I have used `mix fmt`, Credo and Dialyzer in essentially all of my historical
Elixir work, and in the last few years I have also found utility in Adobe's
`styler`, `tailwind_formatter` for organizing HTML classes, and the
`excellent_migrations` package. All of these reduce how much human attentiveness
is needed/spent on important-but-not-urgent considerations and lead to more
consistent codebases over time and across contributors.

### Testing Helpers

I've written a lot of Elixir software and do strive for high test quality and
coverage, I think with some success. Based on those experiences, I pulled in a
number of libraries that may seem like overkill for this application's
scope, e.g. ExMachina with only a handful of simple tables, but that I have
almost always wound up using these in long-lived or critical projects.

I also pulled in `EasyHTML` to simplify code that inspects DOM structures, even
though a Phoenix app defaults to including Floki, because I think Access-based
traversals can be very succinct and clear. Having used this approach before in
personal projects, I vendored some test helpers I've built around this extension
library.

### Partial User Modeling

I've included a stub for a User Ecto Schema and Postgres table, but have not
fleshed this out per the instructions' "don't worry about it" sentiment. I did
think it was important to acknowledge the influence of the ownership concept on
how I modeled the database tables, since it informs validations and query logic
needed to maintain proper scoping. It provides better grounding for future
discussion.

The `users` database table/schema are treated as read-only constructs in all
other surrounding code, so the Plug that retrieves a User ID from the Phoenix
session will fall back to a hard-coded UUID which is part of the database seeds.

I did not intend or attempt to implement actual user authentication/authorization
flows, but if I had to pursue it in the near future I would prototype with
`mix phx.gen.auth` for internal apps or move straight to something like
`guardian`/`ueberauth` for customer-facing.

This product domain is a little limited to warrant complex authorization logic,
but I do often try to design my systems with authorization as a first class
citizen, most often modeled in an RBAC paradigm because I feel it offers a
great balance of educational needs vs evolutionary support vs security outcomes.

### Caching

For read-heavy records, it felt very natural to slot in Cachex to save the SQL
round-trip to look up Links that have been recently visited. I have used this
library quite a bit as a better facade to ETS tables, for information that is
too volatile to store in a `persistent_term`, and I felt it paid off for the
LOE of what is basically a glorified `Map.get` with a fallback value.

### Hourly/Daily Stats

While recording a visit count was part of the acceptance criteria, I opted to
record visits by link plus date plus hour. This can still be trivially rolled
up by Postgres, but can also be leveraged in things like window functions,
SQL `ROLLUP` and `CUBE`, etc. for more interesting statistics.

Further, this offers a natural seam for row expiration/archival, table partitioning,
or other similar techniques, which should be used to keep performance and health
up in a long-lived system with significant data growth. Time-series information
is rarely an optimal fit for an RDBMS at scale.

I'm a happy paying customer of Plausible Analytics and used my recollection of
[their UI](https://plausible.io/plausible.io) for conceptual inspiration on
what kind of information-over-time might be enabled by this approach.

#### Debouncing

In order to avoid bursty SQL traffic, visits are accumulated in a partitioned
GenServer (with `slug` as the partition key) and flushed to PostgreSQL after some
configurable period of inactivity. This defaults to 5 seconds with no new visits
to slugs that fall within that partition. A lively production site would likely
want to reduce that interval significantly, to perhaps 50-150ms.

This shortened interval would also help derisk the potential for lost data, as
I did not yet implement logic to make sure the GenServer does a final flush
during a graceful BEAM shutdown.

## Scope Omissions

### BEAM Clustering

There is no perceived benefit in the current feature scope for distributed Erlang,
Phoenix PubSub/Presence, or other clustering-based functionality.

### Resistance to Misuse

A few recognizable concerns are present but unsolved in my current implementation:

Links may not be deleted or soft-deleted, but if this were permitted, historical
slugs should never be reused but point to a new destination.

Link slugs appear vaguely random to humans, but are a casually-URL-safe encoding
of a randomly generated UUID, which is then truncated to 6 characters maximum.

These have the advantage of not being enumerable or trivially reversible.
However, since they are random sequences, they may possibly generate seemingly
inappropriate or hurtful (sub)strings when read by a person.

Care must be taken that the `/:slug` route in the Router appears after all
statically known routes with only one forward slash, e.g. `/stats`, due to
how the dispatch is decided for the request

This class of application is a frequent target for abuse, and a real product
would need to include moderation tools to remove offensive or illegal content,
and would likely benefit from rate-limiting techniques as well.

### Realtime UIs

I have a **lot** of thoughts both negative and positive about Phoenix LiveView,
but I deliberately did not pursue using it (or SPA techniques) here.
Most of the feature set works absolutely fine with server-rendered HTML and can't
be materially improved by a more complex development/mental model.

#### Stats Table Interactivity

In a real offering I would likely choose to extend the stats table to support
sorting by columns and include pagination controls. This is one of the few areas
I do think LiveView can (sometimes) carry its weight.

Pagination in particular would be warranted as a separate concern from LV,
simply due to the performance concerns generated by unbounded data growth.

### Visual Design

I had earmarked some time to use TailwindUI to shore up my design skills, as I do
have a purchased license for this content and consider it a wonderful investment.
However, this would not be an honest representation of my innate frontend design
skills, so I opted to stay within my own understanding of Tailwind primitives.
I feel I landed on something that qualifies as not-hideous, but I do not feel
it meets more than table-stakes for UI/UX. It's not expected that this would
thrill anyone within frontend or design specialties.

There are so few meaningful routes that there is not really any opportunity for
non-trivial horizontal or vertical navigation bars, and as mentioned above I
intentionally avoided using LiveView or JS.

Color theory in particular is not something I have solid grounding in, so I've
kept everything almost grayscale with a very few blue highlights here and there.
