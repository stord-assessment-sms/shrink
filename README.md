# Shrink

Shrink is a fictitious webapp written and demonstrated for a code assessment by
[Stord](https://www.stord.com) for candidate [Shane Sveller](mailto:shane@sveller.dev).

A live version of the application is deployed temporarily to
[white-tree-1051.fly.dev](https://white-tree-1051.fly.dev/).

## Contents

<!-- vim-markdown-toc GFM -->

* [Features](#features)
* [Design Decisions](#design-decisions)
* [Setup](#setup)
* [Running The App](#running-the-app)
  * [Native](#native)
    * [Database](#database)
    * [Server](#server)
  * [Docker-Compose](#docker-compose)
* [Deployment](#deployment)
* [Known Good Versions](#known-good-versions)

<!-- vim-markdown-toc -->

## Features

- Visit [`/`](https://white-tree-1051.fly.dev/) and supply a full HTTP/HTTPS URL
  to receive a shortened link (~6 characters plus the domain)
  - The 10 most recent links for the user are displayed at the bottom of this page
  - Each recent link has a clickable button to copy its short URL to the clipboard
- Visit [`/:slug`](https://white-tree-1051.fly.dev/gvrtcm) to receive a 301
  redirect to the full URL (or a 404 for invalid slugs)
  - Visited slugs are cached in-memory for up to 5 minutes, since they may not
    be mutated after creation
  - Therefore, popular links will not need to perform a database lookup at the
    expense of runtime memory consumption
  - Negative/failed lookups are cached for up to 1 minute
  - Visits are recorded in a separate database table with hourly granularity
  - Visits are debounced before writing to the database, with a default period of 5 seconds
- Visit [`/stats`](https://white-tree-1051.fly.dev/stats) to view a tabular
  report of existing links, their slugs, and visit counts
  - Stats page supports reporting in hourly/daily granularity or overall sums
  - Clickable link to download a CSV report of the currently visible stats

## Design Decisions

See [Design](./docs/design.md) sub-document.

## Setup

See [Setup](./docs/setup.md) sub-document.

## Running The App

### Native

Download and build dependencies:

```bash
mix do deps.get, deps.compile
```

> [!TIP]
> If like me, you are using an ARM/M1/M2/M3 chip, you may need the following due
> to an [open issue](https://github.com/erlang/otp/issues/8238). This manifests
> as segfaults during commands such as `mix deps.get`.

```bash
mix archive.install github hexpm/hex branch latest
```

#### Database

Create local database if needed, and then run migrations and seeds:

```bash
mix ecto.setup
```

#### Server

The standard approach to running a Phoenix application for development purposes
applies:

```bash
mix phx.server
# OR for REPL access
iex -S mix phx.server
```

You can now visit the application at [localhost:4000](http://localhost:4000/).

> [!TIP]
> If you immediately get a 401 Unauthorized, the seeds are likely missing from
> the database. You can fix that by rerunning `mix ecto.setup` or
> `mix run priv/repo/seeds.exs`. **This also applies to Docker-Compose below.**

### Docker-Compose

A `docker-compose.yml` is included, so you can run the entire application without
any BEAM tooling installed, if so desired.

```bash
docker-compose pull
docker-compose build app
docker-compose up -d db
docker-compose run --rm app "/app/bin/migrate"
docker-compose run --rm app "/app/bin/seed"
docker-comopse up -d app
open http://localhost:4001
```

To clean up:

```bash
docker-compose down --volumes --rmi local
```

## Deployment

Additional details about the Fly.io deployment are available in the
[Deployment](./docs/deployment.md) sub-document.

## Known Good Versions

These are the versions of everything I used while developing this project, which
may be repeated elsewhere:

| Software       | Version  | Notes                         |
| -------------- | -------- | ----------------------------- |
| Docker Desktop | 4.28.0   |                               |
| Erlang         | 26.2.3   | With JIT                      |
| Elixir         | 1.16.2   | `compiled with Erlang/OTP 26` |
| MacOS          | 14.4.1   | ARM                           |
| `mise`         | 2024.4.3 |                               |
| `oha`          | 1.4.1    |                               |
