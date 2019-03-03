#! /bin/sh

epmd -daemon

MIX_ENV=test mix deps.get --only test

mix coveralls
