import SwiftyCM
import Foundation
import TelegramBotSDK
/// Bot Token
let token = ProcessInfo.processInfo.environment["TG_TOKEN"]!;
let bot = TelegramBot(token: token);

/// Path for temporarily storing BRSTM files
let brstmPathPrefix = ProcessInfo.processInfo.environment["BRSTM_ARTIFACT_LOCATION"] ?? "/tmp/"
/// Path for temporarily storing WAV files
let wavPathPrefix = ProcessInfo.processInfo.environment["WAV_DOWNLOADS_LOCATION"] ?? "/tmp/"

var gameList: [GameListGameField] = [];

var initialized: Bool = false;

DispatchQueue.global().async {
    while (true) {
        do {
            gameList = (try SCMClient.gameList());
            initialized = true;
        } catch {
            if (initialized) {
                continue;
            }
            fatalError("Failed to fetch game list");
        }
        Thread.sleep(forTimeInterval: 500.0);
    }
}

let controller = Controller(bot: bot);
let router = Router(bot: bot);

router["s", .slashRequired] = controller.search;
router["d", .slashRequired] = controller.downloadWAV;
router["b", .slashRequired] = controller.downloadBRSTM;
router["g", .slashRequired] = controller.searchGame;
router["f", .slashRequired] = controller.gameSpecificSearch;
router["help", .slashRequired] = controller.helpCommand;
router["start", .slashRequired] = controller.helpCommand;
router.partialMatch = controller.partialMatchHandler;

while let update = bot.nextUpdateSync() {
    if update.message != nil {
        try router.process(update: update)
    }
}
fatalError("Error: \(String(describing: bot.lastError))");
