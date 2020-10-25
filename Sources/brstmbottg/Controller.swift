import Foundation
import TelegramBotSDK
import SwiftyCM
import ShellOut

extension String {
    var commandArgStr: String {
        return self.substring(from: self.index(self.firstIndex(of: Character(" ")) ?? self.index(self.startIndex, offsetBy: 4), offsetBy: 1));
    }
}

class Controller {

    let bot: TelegramBot;

    init (bot: TelegramBot) {
        self.bot = bot;
    }

    func search(context: Context) -> Bool{
        if (context.update.message!.text!.count < 3){
            context.respondAsync("Please enter search query, minimum 3 characters", replyToMessageId: context.update.message!.messageId);
            return true;
        }

        let text = context.update.message!.text!.commandArgStr;

        if (text.count < 3) {
            context.respondAsync("Please enter search query, minimum 3 characters", replyToMessageId: context.update.message!.messageId);
            return true;
        }

        do {
            let songs = try SCMClient.search(text);
            var msg = "*Search Results*:\n\n";
            var i = 0;

            for song in songs {
                let game = gameList.filter {a in a.id == song.gameId}
                let addition = "`" + song.id + "`: _" + game[0].title + "_ - " + song.title + "\n";
                if (msg.count + addition.count > 4096) {break;}
                msg += addition;
                i+=1;
            }

            context.respondAsync(msg, parseMode: "markdown", replyToMessageId: context.update.message!.messageId);
        } catch SCMError.objectNotFoundError {
            context.respondAsync("Nothing found", replyToMessageId: context.update.message!.messageId);
        } catch {
            context.respondAsync("An unexpected error occurred", replyToMessageId: context.update.message!.messageId);
        }

        return true;
    }

    private enum InternalError: Error{
        case conversionError, writeBrstmError
    }

    func downloadWAV (context: Context) -> Bool{
        let text = context.update.message!.text!;
        if (text.split(separator: " ").count == 1) {
            context.respondAsync("Please provide id", replyToMessageId: context.update.message!.messageId);
            return true;
        }
        let id = text.commandArgStr;
        let queue = DispatchQueue.global(qos: .background);
        var state = false;
        let que2 = DispatchQueue.global(qos: .background);

        que2.async{
            while (!state){
                self.bot.sendChatActionAsync(chatId: context.update.message!.chat.id, action: "typing");
                Thread.sleep(forTimeInterval: 5);
            }
        }

        queue.async {
            do {
                let song = try Song(id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!);
                let result = song.download(inFormat: .brstm);

                if (!song.canDownload){
                    throw SCMError.objectNotFoundError;
                }

                var data: Data;

                switch (result) {
                case .failure(let error):
                    throw error;
                case .success(let tmp):
                    data = tmp;
                }

                let filename = String(song.title.map {$0 == "/" ? "_" : $0;});

                let fm = FileManager();
                if (!fm.createFile(atPath: "/tmp/\(song.id).brstm", contents: data)){
                   throw InternalError.writeBrstmError;
                }

                do {
                   _ = (try shellOut(to: "brstm", arguments: ["\"/tmp/" + song.id + ".brstm\"", "-o \"/tmp/" + song.id + ".wav\""]));
                } catch {
                   let error = error as! ShellOutError;
                   print(error.message, error.output);
                }

                guard let readfh = FileHandle.init(forReadingAtPath: "/tmp/\(song.id).wav") else {
                    throw InternalError.conversionError
                }

                let finalData = readfh.readDataToEndOfFile();
                self.bot.sendAudioAsync(chatId: context.update.message!.chat.id,
                        audio: InputFile(filename: song.id + " - " + filename + ".wav", data: finalData), 
                        replyToMessageId: context.update.message!.messageId);
                state = true;

            } catch InternalError.writeBrstmError {
                state = true;
                context.respondAsync("An error occurred saving BRSTM file", replyToMessageId: context.update.message!.messageId);
            } catch SCMError.serverFileError {
                state = true;
                context.respondAsync("File could not be downloaded", replyToMessageId: context.update.message!.messageId);
            } catch SCMError.httpRequestError {
                state = true;
                context.respondAsync("File could not be downloaded", replyToMessageId: context.update.message!.messageId);
            } catch InternalError.conversionError{
                state = true;
                context.respondAsync("An error occurred while converting BRSTM to wav", replyToMessageId: context.update.message!.messageId);
            } catch SCMError.objectNotFoundError {
                state = true;
                context.respondAsync("Song not found", replyToMessageId: context.update.message!.messageId);
            } catch {
                context.respondAsync("An unexpected error has occurred", replyToMessageId: context.update.message!.messageId)
                state = true;
            }
        }

        return true;
    }

    func downloadBRSTM (context: Context) -> Bool{
        let text = context.update.message!.text!;
        if (text.split(separator: " ").count == 1) {
            context.respondAsync("Please provide id", replyToMessageId: context.update.message!.messageId);
            return true;
        }
        let id = text.commandArgStr;
        let queue = DispatchQueue.global(qos: .background);
        var state = false;
        bot.sendChatActionAsync(chatId:  context.update.message!.chat.id, action: "typing");
        let que2 = DispatchQueue.global(qos: .background);

        que2.async{
            while (!state){
                Thread.sleep(forTimeInterval: 5);
                self.bot.sendChatActionAsync(chatId:  context.update.message!.chat.id, action: "typing");
            }
        }

        queue.async {
            do {
                let song = try Song(id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!);

                if (!song.canDownload){
                    throw SCMError.objectNotFoundError;
                }
                
                let result = song.download(inFormat: .brstm);

                var data: Data;

                switch (result) {
                case .failure(let error):
                    throw error;
                case .success(let tmp):
                    data = tmp;
                }

                let filename = String(song.title.map {$0 == "/" ? "_" : $0;});
                self.bot.sendDocumentAsync(chatId: context.update.message!.chat.id,
                        document: InputFile(filename: song.id + " - " + filename + ".brstm", data: data), 
                        replyToMessageId: context.update.message!.messageId);
                state = true;

            } catch {
                context.respondAsync("File could not be downloaded", replyToMessageId: context.update.message!.messageId);
                state = true;
            }
        }

        return true;
    }

    func searchGame(context: Context) -> Bool {
        let text = context.update.message!.text!;
        if (text.split(separator: " ").count == 1) {
            context.respondAsync("Please provide id", replyToMessageId: context.update.message!.messageId);
            return true;
        }
        let query = text.commandArgStr;
        let list = gameList.filter {a in a.title.lowercased().contains(query.lowercased())};
        let msg = list.map {a in "`" + a.id + "`: " + a.title}.joined(separator: "\n");
        context.respondAsync("*Search Results*:\n\n" + msg, parseMode: "markdown");
        return true;
    }

    func gameSpecificSearch(context: Context) -> Bool {
        let text = context.update.message!.text!;
        if (text.split(separator: " ").count > 1){
            let query = text.commandArgStr;
            var args = query.split(separator: " ");

            if (args.count > 1) {
                let gid = args[0];
                args.remove(at: 0);
                let queryS = args.joined(separator: " ");

                do {
                    let songs = try! Game(String(gid)).songs.filter {a in
                        var retval = true;
                        for word in queryS.split(separator: " "){
                            retval = retval && a.title.localizedCaseInsensitiveContains(word);
                        }
                        return retval;
                    }
                    var msg = "Search Results:\n\n";
                    var i = 0;
                    if (songs.count == 0) {
                        throw SCMError.objectNotFoundError;
                    }

                    for song in songs {
                        let addition = song.id + ": " + song.title + "\n";

                        if (msg.count + addition.count > 4096) {
                            break;
                        }

                        msg += addition;
                        i += 1;
                    }

                    context.respondAsync(msg);
                } catch SCMError.objectNotFoundError {
                    context.respondAsync("Nothing found", replyToMessageId: context.update.message!.messageId);
                } catch {
                    context.respondAsync("An unexpected error occurred", replyToMessageId: context.update.message!.messageId);
                }
            } else {
                let gid = args[0];

                do {
                    let game = try SwiftyCM.Game(String(gid));
                    var songList = game.songs.filter {a in a.canDownload }.map { a in "`" + a.id + "`: " + a.title}.joined(separator: "\n");

                    if (songList.count > 4010) {
                        songList = songList.substring(to: 4010) + "\n_<...>(" + String(songList.substring(from: 4011).split(separator: "\n").count) + " more)_";
                    }

                    context.respondAsync("*Search Results*:\n\n" + songList, parseMode: "markdown");
                } catch SCMError.objectNotFoundError {
                    context.respondAsync("Game not found", replyToMessageId: context.update.message!.messageId);
                } catch {
                    context.respondAsync("An unexpected error occurred", replyToMessageId: context.update.message!.messageId);
                }
            }
        } else {
            context.respondAsync("Please specify `<game_id> [search_query]`", parseMode: "markdown", replyToMessageId: context.update.message!.messageId);
        }
        return true;
    }

    func partialMatchHandler(context: Context) -> Bool {
        true;
    }
    
    func helpCommand(context: Context) -> Bool {
        context.respondAsync("*Welcome to BRSTMgram, the commands you can use*:\n`/s <query>` - find song\n`/g <query>` - find game\n`/f <game_id> [query]` - list game songs and filter to query if provided\n`/b <song_id>` - download brstm song\n`/d <song_id>` - download wav song", parseMode: "markdown", replyToMessageId: context.update.message!.messageId);
        return true;
    }
}
