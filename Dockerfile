FROM elixir:1.8-alpine

RUN apk --update add git

RUN mix local.hex --force

ENV APP_DIR /opt/app/

COPY . $APP_DIR

WORKDIR $APP_DIR

RUN mix deps.get

COPY entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
