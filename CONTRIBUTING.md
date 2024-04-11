# Developer-facing Project Standards

Code quality expectations for this project can be upheld with a `mix ci` alias,
which includes:

- Formatter check (empowered by [Styler](https://hex.pm/packages/styler))
- Compiler-level warnings are a fatal error
- ExUnit test suite with an ongoing coverage requirement
- Dialyzer analysis of typespecs
- [ExcellentMigrations](https://hex.pm/packages/excellent_migrations) analysis
  of the safety of existing/new Ecto migrations
- Credo lints with mild local customizations

These expectations are also enforced remotely through the GitHub Actions workflows.
