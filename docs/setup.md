# Setup Instructions

<!-- vim-markdown-toc GFM -->

- [Database](#database)
  - [Docker](#docker)
  - [Homebrew](#homebrew)
  - [Postgres.app](#postgresapp)
- [Erlang & Elixir](#erlang--elixir)
  - [Prereqs (Homebrew)](#prereqs-homebrew)
  - [Mise](#mise)
  - [Other](#other)
  - [Nix](#nix)

<!-- vim-markdown-toc -->

_I personally used [Nix](#nix) for most of the development process on this project._

## Database

This project uses PostgreSQL 15+ for persistent data.

For dev and test, the assumptions in `config/*.exs` will expect a server running
locally with user `postgres` and password `postgres` with DB creation privileges
or SQL superuser rights.

If you don't have PostgreSQL installed already, here are a few possible options
in no particular order:

### Docker

```bash
docker run \
  -it -rm \
  -e POSTGRESS_DB=shrink_prod \
  -p 5432:5432 \
  -v ./data:/var/lib/postgresql/data \
  postgres:15.6-alpine
```

### Homebrew

```bash
brew install postgresql@15
brew services start postgresql@15
```

### Postgres.app

[Postgres.app](https://postgresapp.com/) is a MacOS-only GUI application that
offers a quick installation and lightweight management features.

## Erlang & Elixir

This project requires both Erlang 26 and Elixir 1.16 for development and operation.

### Prereqs (Homebrew)

```bash
# mise
brew install mise
# erlang
brew install autoconf openssl
# optional: for observer
brew install wxwidgets
```

### Mise

[Mise](https://mise.jdx.dev/) is a spiritual successor to [asdf](https://asdf-vm.com),
with much of the core functionality written in Rust. It still uses much of `asdf`'s
plugin ecosystem under the hood.

```bash
# mise + erlang + elixir + cargo + cargo-binstall + oha
mise settings set experimental true
mise install
```

### Other

If you use another compatible tool that respects a `.tool-version` file, such as
`asdf`, I've included one in this repository, so you should likely be able to
continue to use that approach without other special accommodations.

### Nix

Nix is a fairly wide and deep topic that I can't really do justice in my allotted
time, but if it happens that you are an existing Nix user with a Flakes-enabled
configuration, you can build this project using my pre-defined requirements in
`flake.nix` rather than using Homebrew and/or Mise. This approach still assumes
that PostgreSQL is present and configured as outlined above.

```bash
nix -vL develop .
```

Once you are returned to a shell prompt, you'll have Elixir, Erlang, `fly`, and
`oha` in `PATH`.
