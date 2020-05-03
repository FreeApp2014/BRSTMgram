import SwiftyCM
import Foundation
import TelegramBotSDK

// let telegramToken = "your-token-here"

let bot = TelegramBot(token: telegramToken);

var gameList: [GameListGameField];

do {
    gameList = try SCMClient.gameList();
} catch {
    fatalError("Failed to fetch gamelist");
}
let controller = Controller(bot: bot);
let router = Router(bot: bot);

router["s", .slashRequired] = controller.search;
router["d", .slashRequired] = controller.downloadWAV;
router["b", .slashRequired] = controller.downloadBRSTM;
router["g", .slashRequired] = controller.searchGame;
router["f", .slashRequired] = controller.gameSpecificSearch;
router.partialMatch = controller.partialMatchHandler;

while let update = bot.nextUpdateSync() {
    if (update.message != nil) {
        try router.process(update: update)
    }
}

fatalError("Error: \(String(describing: bot.lastError))");