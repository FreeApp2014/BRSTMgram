import Foundation
import TelegramBotSDK
import SwiftyCM
import ShellOut

class Controller {
    let bot: TelegramBot;
    init (bot: TelegramBot) {
        self.bot = bot;
    }
    func search(context: Context) -> Bool{
        if (context.update.message!.text!.count < 3){
            context.respondAsync("Please enter search query, minimum 3 characters");
            return true;
        }
        let text = context.update.message!.text!.substring(from: 3);
        if (text.count < 3) {
            context.respondAsync("Please enter search query, minimum 3 characters");
            return true;
        }
        do {
            let songs = try SCMClient.search(text);
            var msg = "Search Results:\n\n";
            var i = 0;
            for song in songs {
                let game = gameList.filter {a in a.id == song.gameId}
                let addition = song.id + ": " + game[0].title + " - " + song.title + "\n";
                if (msg.count + addition.count > 4096) {break;}
                msg += addition;
                i+=1;
            }
            context.respondAsync(msg);
        } catch SCMError.objectNotFoundError {
            context.respondAsync("Nothing found");
        } catch {
            context.respondAsync("An unexpected error occurred");
        }
        return true;
    }

    private enum InternalError: Error{
        case conversionError, writebrstmerror
    }

    func downloadWAV (context: Context) -> Bool{
        let text = context.update.message!.text!;
        let id = text.substring(from: 3);
        let queue = DispatchQueue.global(qos: .background);
        var state = false;
        bot.sendChatActionAsync(chatId:  context.update.message!.chat.id, action: "typing");
        let que2 = DispatchQueue.global(qos: .background);
        que2.async{
            while (!state){
                Thread.sleep(forTimeInterval: 5);
                self.bot.sendChatActionAsync(chatId: context.update.message!.chat.id, action: "typing");
            }
        }
        queue.async {
            do {
                let song = try Song(id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!);
                guard let data = song.download(inFormat: .brstm) else {
                    throw SCMError.serverFileError;
                }
                let filename = String(song.title.map {
                    $0 == "/" ? "_" : $0;
                })
                let fm = FileManager();
               if (!fm.createFile(atPath: "/tmp/\(song.id).brstm", contents: data)){
                   throw InternalError.writebrstmerror;
               }
                var out: String = "";
               do {
                   out = try shellOut(to: "brstm", arguments: ["\"/tmp/" + song.id + ".brstm\"", "-o \"/tmp/" + song.id + ".wav\""]);
                } catch {
                    let error = error as! ShellOutError
                    print(error.message) // Prints STDERR
                    print(error.output) // Prints STDOUT
                }
                Thread.sleep(forTimeInterval: 2);
                guard let readfh = FileHandle.init(forReadingAtPath: "/tmp/\(song.id).wav") else {
                    throw InternalError.conversionError
                }
                let finalData = readfh.readDataToEndOfFile();
                self.bot.sendDocumentAsync(chatId: context.update.message!.chat.id, document: InputFile(filename: song.id + " - " + filename + ".wav", data: finalData), replyToMessageId: context.update.message!.messageId);
                state = true;
            } catch InternalError.writebrstmerror {
                state = true;
                context.respondAsync("An error occurred saving brstm file");
            } catch SCMError.serverFileError {
                state = true;
                context.respondAsync("File could not be downloaded");
            } catch InternalError.conversionError{
                state = true;
                context.respondAsync("An error occurred while converting brstm to wav");
            } catch SCMError.objectNotFoundError {
                state = true;
                context.respondAsync("Song not found");
            } catch {
                state = true;
            }
        }
        return true;
    }
    func downloadBRSTM (context: Context) -> Bool{
        let text = context.update.message!.text!;
        let id = text.substring(from: 3);
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
                guard let data = song.download(inFormat: .brstm) else {
                    state = true;
                    throw SCMError.serverFileError;
                }
                let filename = String(song.title.map {
                    $0 == "/" ? "_" : $0;
                })
                self.bot.sendDocumentAsync(chatId: context.update.message!.chat.id, document: InputFile(filename: song.id + " - " + filename + ".brstm", data: data), replyToMessageId: context.update.message!.messageId);
                state = true;
            } catch {
                context.respondAsync("File could not be downloaded");
            }
        }
        return true;
    }
    func searchGame(context: Context) -> Bool {
        let text = context.update.message!.text!;
        let query = text.substring(from: 3);
        let list = gameList.filter {a in a.title.lowercased().contains(query.lowercased())};
        let msg = list.map {a in a.id + ": " + a.title}.joined(separator: "\n");
        context.respondAsync("Search Results:\n\n" + msg);
        return true;
    }
    func gameSpecificSearch(context: Context) -> Bool {
        let text = context.update.message!.text!;
        if (text.count > 3){
            let query = text.substring(from: 3);
            var args = query.split(separator: " ");
            if (args.count > 1) {
                let gid = args[0];
                args.remove(at: 0);
                let queryS = args.joined(separator: " ");
                do {
                    let songsraw = try SCMClient.search(queryS);
                    var msg = "Search Results:\n\n";
                    var i = 0;
                    let songs = songsraw.filter { a in
                        a.gameId == gid
                    };
                    if (songs.count == 0) {
                        throw SCMError.objectNotFoundError;
                    }
                    for song in songs {
                        let game = gameList.filter { a in
                            a.id == song.gameId
                        }
                        let addition = song.id + ": " + song.title + "\n";
                        if (msg.count + addition.count > 4096) {
                            break;
                        }
                        msg += addition;
                        i += 1;
                    }
                    context.respondAsync(msg);
                } catch SCMError.objectNotFoundError {
                    context.respondAsync("Nothing found");
                } catch {
                    context.respondAsync("An unexpected error occurred");
                }
            } else {
                let gid = args[0];
                do {
                    let game = try SwiftyCM.Game(String(gid));
                    let songList = game.songs.filter {a in a.canDownload }.map { a in a.id + ": " + a.title}.joined(separator: "\n");
                    context.respondAsync("Search Results:\n\n" + songList);
                } catch SCMError.objectNotFoundError {
                    context.respondAsync("Game not found");
                } catch {
                    context.respondAsync("An unexpected error occurred");
                }
            }
        } else {
            context.respondAsync("Please specify <game_id> [search_query]");
        }
        return true;
    }
    func partialMatchHandler(context: Context) -> Bool {
        true;
    }
}