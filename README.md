# BRSTMgram

A Telegram bot for bringing SCM experience to your chat. Example instance: `@brstm_bot`<br /> 
Based on the [SwiftyCM](https://github.com/FreeApp2014/SwiftyCM) library <br />
Using [OpenRevolution](https://github.com/ic-scm/OpenRevolution) to do file conversion to WAV.

## Using

Swift 5.1 or later required. OpenRevolution 2.x or later required. <br />
The revolution main converter is expected to be found as `brstm` in $PATH, for example in `/usr/bin`.
Clone this repository, uncomment the token line in `Sources/brstmbottg/main.swift` and replace with your telegram bot token. <br /> 
Then run `swift package resolve` to download all dependencies, `swift build` to build and run with `swift run`

### Build issues

On linux the telegram library fails to build because of the embedded swiftyjson version. 
To fix that, replace the file at <br />
`.build/checkouts/telegram-bot-swift/Sources/TelegramBotSDK/SwiftyJSON/SwiftyJSON.swift` <br />
with the file <br />
`.build/checkouts/SwiftyJSON/Sources/SwiftyJSON/SwiftyJSON.swift` <br />
and it should build fine.
