# --- build stage ---
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

ARG RADARR_REPO=https://github.com/nutski/Radarr.git
ARG RADARR_BRANCH=devcustomui
ARG RID=linux-x64
ARG FRAMEWORK=net8.0

WORKDIR /src

# Base build deps + native tooling (needed for some yarn/node modules)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

# Install Node.js (for Radarr frontend build)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# Enable yarn via corepack
RUN corepack enable

# Get your fork + branch
RUN git clone --depth 1 --branch ${RADARR_BRANCH} ${RADARR_REPO} .

# Build backend + frontend + packages using Radarr's script
# bash -x + set -eux ensures the real failure is visible in logs
RUN set -eux; \
    dotnet --info; \
    node --version; \
    yarn --version; \
    chmod +x ./build.sh; \
    bash -x ./build.sh --backend --frontend --packages -r ${RID} -f ${FRAMEWORK}

# --- runtime stage ---
FROM mcr.microsoft.com/dotnet/aspnet:8.0

ARG RID=linux-x64
ARG FRAMEWORK=net8.0

WORKDIR /app

# Copy packaged Radarr output
COPY --from=build /src/_artifacts/${RID}/${FRAMEWORK}/Radarr/ /app/

EXPOSE 7878

# Radarr config path for containers
ENV HOME=/config
ENTRYPOINT ["dotnet", "/app/Radarr.dll", "-nobrowser", "-data=/config"]
