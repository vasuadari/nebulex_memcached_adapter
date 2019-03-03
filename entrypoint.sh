#! /bin/sh

epmd -daemon

MIX_ENV=test mix deps.get

mix test
