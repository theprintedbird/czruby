FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies in single layer to minimize image size
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        zsh \
        ruby \
        coreutils \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set XDG environment variables
ENV XDG_DATA_HOME=/tmp/czruby-data
ENV XDG_CACHE_HOME=/tmp/czruby-cache
ENV XDG_CONFIG_HOME=/tmp/czruby-config

# Create XDG directories with proper permissions
RUN mkdir -p $XDG_DATA_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME && \
    chmod 755 $XDG_DATA_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME

# Set working directory
WORKDIR /app

# Copy only what's needed (leverages .dockerignore)
COPY . .

# Make test scripts executable
RUN chmod +x test/*.zsh

# Set zsh as default shell for better debugging experience
SHELL ["/usr/bin/zsh", "-c"]

# Run tests by default
CMD ["zsh", "test/run_all_tests.zsh"]
