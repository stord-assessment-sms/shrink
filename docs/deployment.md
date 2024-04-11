# Deployment

As noted in the README, a live version of the application is deployed temporarily
to [white-tree-1051.fly.dev](https://white-tree-1051.fly.dev/). First visits
after a period of inactivity may take several seconds due to autoscaling to zero,
but should be prompt during further navigation.

<!-- vim-markdown-toc GFM -->

* [Fly.io](#flyio)
* [Configuration/Topology](#configurationtopology)
* [Deploying a new release](#deploying-a-new-release)
  * [Manually](#manually)
  * [Automated](#automated)

<!-- vim-markdown-toc -->

## Fly.io

Fly.io was chosen for a well-paved road supporting Elixir/Phoenix apps with
PostgreSQL storage very well.

## Configuration/Topology

The `fly.toml` file outlines all current configuration, but in summary the
application will run 0-2 replicas out of the Chicago O'hare (ORD) region,
automatically scaling up with traffic. It runs Ecto migrations upon every
release event, but seeds were performed one-time manually via `fly ssh console`
and running `/app/bin/seed`.

A PostgreSQL database is also deployed via `fly pg create` and `fly pg attach`,
with the lowest available specs. This does not scale-to-zero. The `DATABASE_URL`
and `SECRET_KEY_BASE` are provided as Fly Secrets.

The application itself will shutdown when Bandit reports no open connections for
a default of **60 seconds**, which is configurable at compile-time. A value of
`:infinity` will disable this behavior, and it is encouraged to disable or
increase this interval when using Docker-Compose.

## Deploying a new release

### Manually

```bash
fly deploy --now --remote-only
open https://white-tree-1051.fly.dev/
```

### Automated

I did not feel comfortable including a Fly deploy token secret on this public
repository, but this would be straightforward to implement on top of my `test`
GHA workflow.
