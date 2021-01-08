test:
    FROM +test-setup

    RUN apk add --no-progress --update docker docker-compose
    RUN apk add postgresql-client

    COPY /docker-compose.yml ./docker-compose.yml

    WITH DOCKER
        # Start docker compose
        # In parallel start compiling tests
        # Check for DB to be up x 3
        # Run the database tests
        RUN docker-compose up -d & \
            MIX_ENV=test mix deps.compile && \
            while ! pg_isready --host=localhost --port=5432 --quiet; do sleep 1; done; \
            mix test
    END

    RUN mix format --check-formatted

setup-base:
   ARG ELIXIR=1.11.2
   ARG OTP=23.1.1
   FROM hexpm/elixir:$ELIXIR-erlang-$OTP-alpine-3.12.0
   RUN apk add --no-progress --update git build-base
   ENV ELIXIR_ASSERT_TIMEOUT=10000
   WORKDIR /src

test-setup:
   FROM +setup-base
   COPY mix.exs .
   COPY mix.lock .
   COPY .formatter.exs .
   COPY --dir apps config ./
   RUN mix local.rebar --force
   RUN mix local.hex --force
   RUN mix deps.get

