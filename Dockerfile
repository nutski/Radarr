# --- build stage ---
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

ARG RADARR_REPO=https://github.com/nutski/Radarr.git
ARG RADARR_BRANCH=devcustom
ARG RID=linux-x64
ARG FRAMEWORK=net6.0

WORKDIR /src

# tools needed by build.sh: git + curl + node/yarn (via corepack)
RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl ca-certificates \
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

# Build backend + frontend + package for a single RID (uses Radarr's build.sh)
RUN chmod +x ./build.sh \
 && ./build.sh --backend --frontend --packages -r ${RID} -f ${FRAMEWORK}

# --- runtime stage ---
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# Copy the packaged Radarr folder produced by build.sh
# build.sh outputs to _artifacts/<rid>/<framework>/Radarr
ARG RID=linux-x64
ARG FRAMEWORK=net6.0
COPY --from=build /src/_artifacts/${RID}/${FRAMEWORK}/Radarr/ /app/

EXPOSE 7878
ENV HOME=/config
ENTRYPOINT ["dotnet", "/app/Radarr.dll", "-nobrowser", "-data=/config"]
