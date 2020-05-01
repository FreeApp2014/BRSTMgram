# BRSTMgram

A telegram bot for bringing SCM experience to your chat.<br /> 
Based on the [SwiftyCM](https://github.com/FreeApp2014/SwiftyCM) library <br />
Using [Revolution](https://github.com/Extrasklep/revolution) to do file conversion to WAV.

## Using

Swift 5.1 or later required. Revolution 2.x or later required. <br />
The revolution main converter is expected to be found as `brstm` in $PATH, for example in `/usr/bin`.
Clone this repository, uncomment the token line in `Sources/brstmbottg/main.swift` and replace with your telegram bot token. <br /> 
Then run `swift package resolve` to download all dependencies, `swift build` to build and run with `swift run`

### Build issues

On linux the telegram library fails to build because of the embedded swiftyjson version. 
To fix that, replace the file at 
`.build/checkouts/telegram-bot-swift/Sources/TelegramBotSDK/SwiftyJSON/SwiftyJSON.swift` 
with the file 
`.build/checkouts/SwiftyJSON/Sources/SwiftyJSON/SwiftyJSON.swift` 
and it should build fine.