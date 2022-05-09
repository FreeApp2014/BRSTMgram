# BRSTMgram

A Telegram bot for bringing SCM experience to your chat. Example instance: `@brstm_bot`<br /> 
Based on the [SwiftyCM](https://github.com/FreeApp2014/SwiftyCM) library <br />
Using [OpenRevolution](https://github.com/ic-scm/OpenRevolution) to do file conversion to WAV.

## Using

### Authentication
The token is read from the `TG_TOKEN` environment variable.

### Cache
The application uses two environment variables to specify cache locations. Useful in case of running in a container to combine with volumes configuration, or for running on an read-only state system.
The files get automatically deleted after being processed.
- `BRSTM_ARTIFACT_LOCATION` - BRSTM file storage
- `WAV_DOWNLOADS_LOCATION` - WAV file storage

### Docker
The pre-built container image is [available](https://github.com/FreeApp2014/BRSTMgram/pkgs/container/brstmgram):
```
$ podman pull ghcr.io/freeapp2014/brstmgram:latest
```
Running:
```
$ podman run -dit -e TG_TOKEN=<your-bot-token> --name brstmgram ghcr.io/freeapp2014/brstmgram:latest 
```

Alternatively, the image can be built using the included Dockerfile. 

### Manual build
- BRSTMgram: Swift 5.3 or later required. OpenRevolution 2.x or later required. cURL development headers needed for the network features to function. <br />
The revolution main converter is expected to be found as `brstm` in $PATH, for example in `/usr/bin`.
Clone this repository, then run `swift package resolve` to download all dependencies, `swift build` to build and run with `swift run`.
- OpenRevolution: refer to [GitHub](https://github.com/ic-scm/OpenRevolution)

