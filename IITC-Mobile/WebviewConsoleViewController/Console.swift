//
//  Console.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/10/17.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit

enum ConsoleMessageSource {
    case js
    case navigation
    case native
    case user
    case userResult

    func labelColor() -> UIColor {
        if #available(iOS 13.0, *) {
            switch self {
            case .user:
                return .systemBlue
            case .navigation:
                return .systemGreen
            default:
                return .label
            }
        } else {
            switch self {
            case .user:
                return .blue
            case .navigation:
                return .green
            default:
                return .black
            }
        }
    }

    func image() -> UIImage? {
        switch self {
        case .navigation:
            return #imageLiteral(resourceName: "navigation")
        case .user:
            return #imageLiteral(resourceName: "user")
        case .userResult:
            return #imageLiteral(resourceName: "userResult")
        default:
            return nil
        }
    }
}

enum ConsoleMessageLevel {
    case none
    case debug
    case log
    case warning
    case error

    func labelColor() -> UIColor {
        if #available(iOS 13.0, *) {
            switch self {
            case .debug:
                return UIColor.systemBlue
            case .warning:
                return UIColor { (traitCollection) -> UIColor in
                    if traitCollection.userInterfaceStyle == .light {
                        return UIColor(red: 0.4, green: 0.3, blue: 0, alpha: 1)
                    } else {
                        return UIColor(red: 1, green: 1, blue: 0, alpha: 1)
                    }
                }

            case .error:
                return UIColor.systemRed
            default:
                return UIColor.label
            }
        } else {
            switch self {
            case .debug:
                return UIColor.blue
            case .warning:
                return UIColor(red: 0.4, green: 0.3, blue: 0, alpha: 1)
            case .error:
                return UIColor.red
            default:
                return UIColor.black
            }
        }
    }

    func backgroundColor() -> UIColor {
        if #available(iOS 13.0, *) {
            switch self {
            case.debug:
                return UIColor.systemBlue.withAlphaComponent(0.2)
            case .warning:
                return UIColor.systemYellow.withAlphaComponent(0.2)
            case .error:
                return UIColor.systemRed.withAlphaComponent(0.2)
            default:
                return UIColor.systemBackground
            }
        } else {
            switch self {
            case.debug:
                return UIColor.blue.withAlphaComponent(0.2)
            case .warning:
                return UIColor.yellow.withAlphaComponent(0.2)
            case .error:
                return UIColor.red.withAlphaComponent(0.2)
            default:
                return UIColor.white
            }
        }
    }
    func image() -> UIImage? {
        switch self {
        case .debug:
            return #imageLiteral(resourceName: "info")
        case .warning:
            return #imageLiteral(resourceName: "ic_action_warning")
        case .error:
            return #imageLiteral(resourceName: "cancel")
        default:
            return nil
        }
    }
}



protocol ConsoleMessageProtocol {
    func getSource() -> ConsoleMessageSource

    func getLevel() -> ConsoleMessageLevel
//    @property (nonatomic, strong) NSString * message;
//    var message: String {get}
    func getMessage() -> String
//    @property (nonatomic) NSInteger line;
//    var line: Int{get}
    func getLine() -> Int
//    @property (nonatomic) NSInteger column;
//    var column: Int{get}
//    @property (nonatomic, strong) NSString * url;
//    var url: String{get}
//
//    @property (nonatomic, strong) NSString * caller;
}

protocol Console {
    func count() -> Int

    func messages(at index: Int) -> ConsoleMessageProtocol

    func commit(command: String)

    func clearMessages()

    func registerListener(_: @escaping () -> Void) -> Any

    func unregisterListener(_: Any)
}

protocol ConsoleSuggestionProvider {
    func fetchSuggestions(for text: String, cursorIndex: Int, completion: @escaping ([String], NSRange) -> Void)
}
