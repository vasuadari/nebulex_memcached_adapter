FROM elixir:1.8-alpine

ENV APP_DIR /opt/app/

COPY . $APP_DIR

WORKDIR $APP_DIR

RUN mix local.hex --force

RUN mix deps.get
