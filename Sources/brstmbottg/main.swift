import SwiftyCM
import Foundation
import TelegramBotSDK

let bot = TelegramBot(token: token);

var gameList: [GameListGameField] = [];
DispatchQueue.global().async {
    while (true) {
        do {
            gameList = (try SCMClient.gameList());
        } catch {
            fatalError("Failed to fetch gamelist");
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
    if let message = update.message {
        try router.process(update: update)
    }
}
fatalError("Error: \(String(describing: bot.lastError))");
