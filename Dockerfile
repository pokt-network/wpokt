# Use the latest foundry image
FROM ghcr.io/foundry-rs/foundry as base

# Copy our source code into the container
WORKDIR /app
COPY . .

# Build and test the source code
RUN forge build
RUN forge test

RUN apk add --update --no-cache bash

# Run the application
CMD ["/app/docker/entrypoint.sh"]
