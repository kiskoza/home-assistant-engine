# Home Assisstant Engine

I would like to move my automations from cryptic yml files to nice, testable elixir modules. Let's brew something...

## Set up the project

1. Get a running Home Assistant using docker.
  ```bash
    docker run \
      --name homeassistant \
      --privileged \
      --restart=unless-stopped \
      -e TZ=Europe/Budapest \
      -v $(pwd)/ha-config:/config \
      --network=host \
      ghcr.io/home-assistant/home-assistant:stable
  ```
2. Go through the Onboarding process

## Run the project in development

1. `docker start homeassistant` and `docker stop homeassistant` to manage the homeassistant instance
