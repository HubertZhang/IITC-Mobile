//
//  ConsoleInputViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/10/18.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit

protocol ConsoleInputUIDelegate: class {
    func viewHeightDidChange(_: CGFloat)
}

class ConsoleInputHistoryManager {
    static var shared = ConsoleInputHistoryManager()
    typealias HistoryEntry = (text: String, selected: NSRange?)

    var entries: [String] = []
    var index: Int = 0
    var latest: HistoryEntry = ("", nil)

    func commit(text: String) {
        entries.append(text)
        latest = ("", nil)
        index = entries.count
    }

    func storeCurrent(text: String, selected: NSRange? = nil) {
        latest.text = text
        latest.selected = selected
    }

    func hasPrevious() -> Bool {
        return entries.count >= index && index > 0
    }

    func getPrevious() -> HistoryEntry? {
        if !hasPrevious() {
            return nil
        }
        index -= 1
        return (entries[index], nil)
    }

    func hasNext() -> Bool {
        return entries.count > index
    }

    func getNext() -> HistoryEntry? {
        if !hasNext() {
            return nil
        }
        index += 1
        if index == entries.count {
            return latest
        }
        return (entries[index], nil)
    }

}

class ConsoleInputViewController: UIViewController, UIGestureRecognizerDelegate {
    var bottomSafeAreaInsets: CGFloat {
        if #available(iOS 11.0, *) {
            return self.view.safeAreaInsets.bottom
        } else {
            return 0
        }
    }

    @IBOutlet weak var bottomHeight: NSLayoutConstraint!
    @IBOutlet weak var actionButton: UIImageView!

    @IBOutlet weak var textView: UITextView!

    var console: Console!

    weak var uiDelegate: ConsoleInputUIDelegate?

    var observers: [Any] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupKeyCommands()
        setupActionButtonView()
    }

    override func viewWillAppear(_ animated: Bool) {
        setupSuggestionTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        registerKeyboardHeightObserver()
        self.handleHeightChange()
    }

    override func viewDidLayoutSubviews() {
        self.uiDelegate?.viewHeightDidChange(self.view.frame.height)
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.suggestionTableViewController.willMove(toParent: nil)
        self.suggestionTableViewController.view.removeFromSuperview()
        self.suggestionTableViewController.removeFromParent()
//        for observer in self.observers {
//            NotificationCenter.default.removeObserver(observer)
//        }
//        self.observers = []
    }

    // MARK: - SafeArea
    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.handleHeightChange()
    }

    func handleHeightChange() {
        let absolutePosition = self.view.convert(self.view.bounds, to: self.view.window)
        let bottomHeight = absolutePosition.maxY

        UIView.animate(withDuration: 0.25) {
            self.bottomHeight.constant = max(self.keyboardHeight -  max(self.view.window!.frame.height-bottomHeight, 0), self.bottomSafeAreaInsets)
        }
    }

    // MARK: - Prompt Completion
    weak var suggestionTableViewController: ConsoleSuggestionTableViewController!
    var suggestionTableViewHeightConstraint: NSLayoutConstraint!

    func setupSuggestionTableView() {
        let vc = ConsoleSuggestionTableViewController(style: .plain)
        vc.delegate = self
        self.suggestionTableViewController = vc

        suggestionTableViewHeightConstraint = vc.view.heightAnchor.constraint(equalToConstant: 0)

        self.addChild(suggestionTableViewController)
        suggestionTableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(suggestionTableViewController.view)
        NSLayoutConstraint.activate([
            suggestionTableViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            suggestionTableViewController.view.bottomAnchor.constraint(equalTo: self.textView.topAnchor),
            suggestionTableViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            suggestionTableViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            suggestionTableViewHeightConstraint
        ])
        self.view.bringSubviewToFront(suggestionTableViewController.view)
        suggestionTableViewController.didMove(toParent: self)
    }

    var suggestionReplaceRange: NSRange?

    func updatePromptCompletion(text: String, cursorIndex: Int) {
        guard let console = self.console as? ConsoleSuggestionProvider else {
            return
        }
        console.fetchSuggestions(for: text, cursorIndex: cursorIndex) {
            (s, range) in
            self.suggestionReplaceRange = range
            self.suggestionTableViewController.update(suggestions: s)
            self.suggestionTableViewHeightConstraint.constant = CGFloat(min(s.count * 36, 36*3))
        }
    }

    func stopPromptCompletion() {
        self.suggestionTableViewHeightConstraint.constant = 0
    }

    // MARK: - Action Button

    var actionButtonPanel: ConsoleInputActionButtonViewController!

    func setupActionButtonView() {
        let vc = ConsoleInputActionButtonViewController(nibName: "ConsoleInputActionButtonViewController", bundle: Bundle.main)

        vc.addAction(withTitle: "Toggle Keyboard",
                     disabler: {false},
                     action: {
                        [weak self] in
                        self?.toggleKeyboard()
                     })

        vc.addAction(withTitle: "Next",
                     disabler: {!ConsoleInputHistoryManager.shared.hasNext()},
                     action: {
                                     [weak self] in
                                     self?.nextHistory()
                     })
        vc.addAction(withTitle: "Previous",
                     disabler: {!ConsoleInputHistoryManager.shared.hasPrevious()},
                     action: {
                                     [weak self] in
                                     self?.previousHistory()
                     })

        vc.addAction(withTitle: "New Line",
                     disabler: {[weak self] in
                        !(self?.textView.isFirstResponder ?? false)
                     },
                     action: {
                                     [weak self] in
                                     self?.insertNewLine()
                     })

        self.actionButtonPanel = vc
    }


    func attachActionPanel() {
        self.addChild(actionButtonPanel)
        actionButtonPanel.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(actionButtonPanel.view)
        NSLayoutConstraint.activate([
            actionButtonPanel.view.bottomAnchor.constraint(equalTo: self.actionButton.bottomAnchor, constant: 4),
            actionButtonPanel.view.trailingAnchor.constraint(equalTo: self.actionButton.trailingAnchor, constant: 6)
        ])
        self.view.bringSubviewToFront(actionButtonPanel.view)
        actionButtonPanel.didMove(toParent: self)

    }

    func detachActionPanel() {
        actionButtonPanel.willMove(toParent: nil)
        actionButtonPanel.view.removeFromSuperview()
        actionButtonPanel.removeFromParent()
    }

    @IBAction func actionButtonLongGestureHandler(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            attachActionPanel()
        }
        actionButtonPanel.handleLongPress(gestureRecognizer)
        if gestureRecognizer.state == .ended {
            detachActionPanel()
        }
    }

    @IBAction func actionButtonClicked(_ sender: Any) {

    }

    // MARK: - Actions
    private var insertingNewLine: Bool = false
    @objc func insertNewLine() {
        insertingNewLine = true

        self.textView.insertText("\n")

        insertingNewLine = false
    }

    func commitCommand() {
        var command = textView.text ?? ""
        command = command.trimmingCharacters(in: .whitespacesAndNewlines)
        if command == "" {
            return
        }
        ConsoleInputHistoryManager.shared.commit(text: command)
        self.console.commit(command: command)
        textView.text = nil
    }

    func toggleKeyboard() {
        if (self.textView.isFirstResponder) {
            self.textView.resignFirstResponder()
        } else {
            self.textView.becomeFirstResponder()
        }
    }
    func previousHistory() {
        guard let entry = ConsoleInputHistoryManager.shared.getPrevious() else {
            return
        }
        ConsoleInputHistoryManager.shared.storeCurrent(text: self.textView.text, selected: self.textView.selectedRange)
        self.textView.text = entry.text
    }

    func nextHistory() {
        guard let entry = ConsoleInputHistoryManager.shared.getNext() else {
            return
        }
        self.textView.text = entry.text
        if entry.selected != nil {
            self.textView.selectedRange = entry.selected!
        }
    }

    // MARK: - Keyboard
    private var keyboardHeight: CGFloat = 0.0

    func registerKeyboardHeightObserver() {
        let handler: (Notification) -> Void = {
            [weak self] notification in
            guard let endFrame = notification.userInfo?[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            guard let self = self else {
                return
            }

            if (!endFrame.isNull) {
                self.keyboardHeight = max(UIScreen.main.bounds.height-endFrame.origin.y, 0)
            }

            self.handleHeightChange()
        }

            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main, using: handler)
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main, using: handler)
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main, using: handler)
    }

    func setupKeyCommands() {
        self.addKeyCommand(UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(upArrowPressed)))
        self.addKeyCommand(UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(downArrowPressed)))
        self.addKeyCommand(UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(insertNewLine)))
    }

    @objc func upArrowPressed() {
        if textView.isFirstResponder {
            guard let cursorRange = textView.selectedTextRange else {
                previousHistory()
                return
            }
            guard let lineStart = textView.tokenizer.position(from: cursorRange.start, toBoundary: .line, inDirection: .layout(.left)) else {
                previousHistory()
                return
            }
            if lineStart != textView.beginningOfDocument {
                let position = textView.position(from: cursorRange.start, in: .up, offset: 1) ?? textView.beginningOfDocument
                textView.selectedTextRange = textView.textRange(from: position, to: position)
                return
            }
            previousHistory()
        }
    }

    @objc func downArrowPressed() {
        if textView.isFirstResponder {
            guard let cursorRange = textView.selectedTextRange else {
                nextHistory()
                return
            }
            guard let lineEnd = textView.tokenizer.position(from: cursorRange.start, toBoundary: .line, inDirection: .layout(.right)) else {
                nextHistory()
                return
            }
            if lineEnd != textView.endOfDocument {
                let position = textView.position(from: cursorRange.start, in: .down, offset: 1) ?? textView.endOfDocument
                textView.selectedTextRange = textView.textRange(from: position, to: position)
                return
            }
            nextHistory()
        }
    }
}

// MARK: - UITextViewDelegate
extension ConsoleInputViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        self.stopPromptCompletion()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n" && !insertingNewLine) {
            self.commitCommand()
            return false
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        updateTextViewSuggestion(textView)
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        updateTextViewSuggestion(textView)
    }

    func updateTextViewSuggestion(_ textView: UITextView) {
        if (textView.text.count > 0 && textView.selectedRange.length == 0 && textView.isFirstResponder) {
            self.updatePromptCompletion(text: textView.text, cursorIndex: textView.selectedRange.location)
        } else {
            self.stopPromptCompletion()
        }
    }
}

// MARK: - ConsoleSuggestionTableViewDelegate
extension ConsoleInputViewController: ConsoleSuggestionTableViewDelegate {
    func choose(suggestion: String) {
        if suggestion == "" {
            return
        }

        guard let text = textView.text else {
            textView.text = suggestion
            self.stopPromptCompletion()
            return
        }

        var range = self.suggestionReplaceRange ?? NSRange()

        range.location = max(0, range.location)
        range.location = min(text.count, range.location)
        range.length = min(range.length, text.count - range.location)

        let start = textView.position(from: textView.beginningOfDocument, offset: range.location)!

        let end = textView.position(from: start, offset: range.length)!

        textView.replace(textView.textRange(from: start, to: end)!, withText: suggestion)

        self.stopPromptCompletion()
    }
}
