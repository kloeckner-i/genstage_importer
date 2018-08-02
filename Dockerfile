FROM bitwalker/alpine-elixir:1.7.1
LABEL MAINTAINER Andrey Marchenko

ENV DEBIAN_FRONTEND=noninteractive

# Install hex
RUN mix local.hex --force
RUN mix local.rebar --force

ENV APP_HOME /app

WORKDIR $APP_HOME

COPY . .

CMD mix do deps.get, phx.server
