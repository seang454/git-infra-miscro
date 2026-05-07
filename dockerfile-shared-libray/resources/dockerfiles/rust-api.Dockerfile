FROM rust:1.82 AS build
WORKDIR /src
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=build /src/target/release/* /app/server
EXPOSE 8080
ENTRYPOINT ["/app/server"]
