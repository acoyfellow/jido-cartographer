ARG ELIXIR_IMAGE=hexpm/elixir:1.18.4-erlang-27.3.4.16-debian-bookworm-20260824-slim

FROM --platform=$BUILDPLATFORM ${ELIXIR_IMAGE} AS build
WORKDIR /build
ENV MIX_ENV=prod HEX_CACERTS_PATH=/tmp/build-ca-certificates.crt
RUN --mount=type=secret,id=extra_ca,required=false \
    cat /etc/ssl/certs/ca-certificates.crt > /tmp/build-ca-certificates.crt && \
    if [ -f /run/secrets/extra_ca ]; then cat /run/secrets/extra_ca >> /tmp/build-ca-certificates.crt; fi && \
    mix local.hex --force && mix local.rebar --force
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod && mix deps.compile
COPY config config
COPY lib lib
RUN mix compile

FROM ${ELIXIR_IMAGE}
WORKDIR /app
COPY --from=build /build/_build/prod/lib /app/lib
COPY bin/start /app/bin/start
ENV HOME=/app PORT=8080 LANG=C.UTF-8 ERL_LIBS=/app/lib
EXPOSE 8080
CMD ["/app/bin/start"]
