//
//  ConsoleViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/10/17.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit
import WBWebViewConsole

class ConsoleViewController: UIViewController {
    @IBOutlet weak var messageTableView: UITableView!

    var consoleObserver: Any?
    var console: Console! {
        didSet {
            if consoleObserver != nil {
                oldValue.unregisterListener(consoleObserver!)
            }
            consoleObserver = console.registerListener {
                [weak self] in
                let shouldScroll = self?.messageTableView.isBottomVisible() ?? false
                self?.messageTableView.reloadData()
                if shouldScroll {
                    self?.messageTableView.wbt_scrollToBottom(animated: true)
                }
            }
        }
    }
    var consoleInputViewController: ConsoleInputViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        messageTableView.register(UINib(nibName: "ConsoleMessageCell", bundle: nil), forCellReuseIdentifier: "consoleMessage")
        messageTableView.estimatedRowHeight = 52.0
        messageTableView.rowHeight = UITableView.automaticDimension

        constructInputView()

//        registerNotificationsForCurrentConsole()
    }

    override func viewWillAppear(_ animated: Bool) {
    }

    deinit {
        if self.consoleObserver != nil {
            console.unregisterListener(self.consoleObserver!)
            self.consoleObserver = nil
        }
    }

    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
    }

    func setupNavigationBar() {
        self.title = "Debug Console"
        if self.navigationController != nil {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearClicked))
        }

    }

    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }

    func constructInputView() {
        let consoleInputViewController = ConsoleInputViewController(nibName: "ConsoleInputViewController", bundle: nil)
        consoleInputViewController.console = self.console
        consoleInputViewController.uiDelegate = self
        self.consoleInputViewController = consoleInputViewController
        self.addChild(consoleInputViewController)
        consoleInputViewController.view.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(consoleInputViewController.view)
         NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:[v]|", options: [], metrics: nil, views: ["v": consoleInputViewController.view, "bottom": self.bottomLayoutGuide]))
         NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "|[v]|", options: [], metrics: nil, views: ["v": consoleInputViewController.view]))
        self.view.bringSubviewToFront(consoleInputViewController.view)
        consoleInputViewController.didMove(toParent: self)
    }

    @objc func clearClicked(_ sender: Any) {
        self.console.clearMessages()
    }

    // MARK: - Console Notifications

//    func registerNotificationsForCurrentConsole() {
//        NotificationCenter.default.addObserver(forName: NSNotification.Name.WBWebViewConsoleDidAddMessage, object: self.console, queue: .main, using: self.consoleDidAddMessage)
//        NotificationCenter.default.addObserver(forName: NSNotification.Name.WBWebViewConsoleDidClearMessages, object: self.console, queue: .main, using: self.consoleDidClearMessages)
//    }

    func consoleDidAddMessage(_ notification: Notification) {
        self.messageTableView.reloadData()
    }

    func consoleDidClearMessages(_ notification: Notification) {
        self.messageTableView.reloadData()
    }
}

extension ConsoleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return console.count()
    }

    // Provide a cell object for each row.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       // Fetch a cell of the appropriate type.
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "consoleMessage", for: indexPath) as? ConsoleMessageCell else {
            return UITableViewCell()
        }

        let message = self.console.messages(at: indexPath.row)
        cell.message.text = message.getMessage()
        cell.location.text = message.getLocation()

        cell.setStyle(message: message)

       return cell
    }
}

extension ConsoleViewController: UITableViewDelegate {

}

extension ConsoleViewController: ConsoleInputUIDelegate {
    func viewHeightDidChange(_ height: CGFloat) {
        if #available(iOS 11.0, *) {
            self.messageTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: height-self.view.safeAreaInsets.bottom, right: 0)
        } else {
            // Fallback on earlier versions
        }
    }
}

extension ConsoleMessageCell {
    func setStyle(message: ConsoleMessageProtocol) {
        let source = message.getSource()
        let level = message.getLevel()

        if #available(iOS 13.0, *) {
            self.message.textColor = UIColor.label
            self.contentView.backgroundColor = UIColor.systemBackground
        } else {
            self.message.textColor = UIColor.black
            self.contentView.backgroundColor = UIColor.white
        }
        if source == .js {
            let level = message.getLevel()
            self.levelImage.image = level.image()?.withRenderingMode(.alwaysTemplate)
            self.levelImage.tintColor = level.labelColor()
            self.message.textColor = level.labelColor()
            self.contentView.backgroundColor = level.backgroundColor()
        } else if source == .navigation {
            self.levelImage.image = source.image()?.withRenderingMode(.alwaysTemplate)
            if level == .warning {
                self.levelImage.tintColor = level.labelColor()
            } else {
                self.levelImage.tintColor = source.labelColor()
            }
        } else {
            self.levelImage.image = source.image()?.withRenderingMode(.alwaysTemplate)
            self.levelImage.tintColor = source.labelColor()
            self.message.textColor = source.labelColor()
        }
    }

}
