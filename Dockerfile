# --- build stage ---
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG RADARR_REPO=https://github.com/nutski/Radarr.git
ARG RADARR_BRANCH=devcustom

WORKDIR /src
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch ${RADARR_BRANCH} ${RADARR_REPO} .
# If Radarr uses submodules in your branch, uncomment:
# RUN git submodule update --init --recursive

# Build + publish
RUN dotnet publish ./src/Radarr/Radarr.csproj -c Release -o /out --no-self-contained

# --- runtime stage ---
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /out/ /app/

# Radarr default port
EXPOSE 7878

# IMPORTANT: you still need to mount /config in Unraid
ENV HOME=/config
ENTRYPOINT ["dotnet", "/app/Radarr.dll", "-nobrowser", "-data=/config"]
