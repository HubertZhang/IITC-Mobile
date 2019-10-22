//
//  bridges.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/10/18.
//  Copyright © 2019 IITC. All rights reserved.
//

import Foundation
import WBWebViewConsole

extension WBWebViewConsole: Console {
    func count() -> Int {
        return self.messages.count
    }

    func messages(at index: Int) -> ConsoleMessageProtocol {
        return self.messages[index] as! WBWebViewConsoleMessage
    }

    func commit(command: String) {
        self.sendMessage(command)
    }

    func registerListener(_ updater: @escaping () -> Void) -> Any {
        var observers: [Any] = []
        observers.append(NotificationCenter.default.addObserver(forName: .WBWebViewConsoleDidAddMessage, object: self, queue: .main, using: {
            _ in
            updater()
        }))
        observers.append(NotificationCenter.default.addObserver(forName: .WBWebViewConsoleDidClearMessages, object: self, queue: .main, using: {
            _ in
            updater()
        }))
        return observers
    }

    func unregisterListener(_ input: Any) {
        if let observers = input as? [Any] {
            for observer in observers {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

extension WBWebViewConsoleMessage: ConsoleMessageProtocol {
    func getLevel() -> ConsoleMessageLevel {
        switch self.level {
        case .debug:
            return .debug
        case .error:
            return .error
        case .info, .log:
            return .log
        case .warning:
            return .warning
        default:
            return .none
        }
    }

    func getMessage() -> String {
        return self.message
    }

    func getLine() -> Int {
        return self.line
    }

    func getSource() -> ConsoleMessageSource {
        switch self.source {
        case .JS:
            return .js
        case .native:
            return .native
        case .navigation:
            return .navigation
        case .userCommand:
            return .user
        case .userCommandResult:
            return .userResult
        @unknown default:
            return .js
        }
    }

}

extension WBWebViewConsole: ConsoleSuggestionProvider {
    func fetchSuggestions(for text: String, cursorIndex: Int, completion: @escaping ([String], NSRange) -> Void) {
        self.fetchSuggestions(forPrompt: text, cursorIndex: cursorIndex) { (suggestion, range) in
            guard let suggestion = suggestion as? [String] else {
                completion([], range)
                return
            }
            completion(suggestion, range)
        }
    }
}
