# Contributing

## How-To Release

* Update `@version` in `mix.exs`
* Update `version` in `action.yml` / `steps` / `mix escript.install`
* `git commit -m "Release v[VERSION]"`
* `git tag -s v[VERSION] -m v[VERSION]`
* `mix hex.publish`
* `git push origin main --tags`

## How-To Update Erlang / Elixir

* Update Versions in `.tool-versions`
* Put the same versions into `action.yaml` / `steps` / `setup-beam`
