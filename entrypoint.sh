#! /bin/sh

epmd -daemon

mix local.rebar --force

MIX_ENV=test mix deps.get --only test

mix coveralls.json
