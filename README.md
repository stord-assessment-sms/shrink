## Mise Prereqs

```shell
# mise
brew install autoconf mise openssl
# erlang prereqs
brew install autoconf mise openssl
# optional: for observer
brew install wxwidgets

# mise + cargo + cargo-binstall + oha + erlang +elixir
mise settings set experimental true
mise install

# install oha via homebrew instead
brew install oha

# For `mix deps.get` segfaults on ARM + Erlang 26.2.3
mix archive.install github hexpm/hex branch latest
```
