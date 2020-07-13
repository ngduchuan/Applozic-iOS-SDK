//
//  ALSearchViewController.swift
//  Applozic
//
//  Created by Sunil on 26/06/20.
//  Copyright © 2020 applozic Inc. All rights reserved.
//

import Foundation

@objc public class ALSearchResultViewController : UITableViewController {

    enum EmptyLabelInfoText {
        static let searchInfoText =  NSLocalizedString("SearchInfoText", tableName: ALApplozicSettings.getLocalizableName(), bundle: Bundle.main, value: "Press search button to start searching...", comment: "")

        static let noSearchResultFound =  NSLocalizedString("noSearchResultFound", tableName: ALApplozicSettings.getLocalizableName(), bundle: Bundle.main, value: "No results found", comment: "")
    }

    let messageService = ALMessageService()
    let viewModel = ALSearchViewModel()

    fileprivate let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        label.numberOfLines = 1
        label.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    @objc required public init() {
        super.init(nibName: nil, bundle: nil)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ALConversationCell.self, forCellReuseIdentifier: ALConversationCell.forCellReuseIdentifier)
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.white
        tableView.keyboardDismissMode = .onDrag

        // Add Activity Indicator
        activityIndicator.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
        activityIndicator.color = UIColor.gray
        view.addSubview(activityIndicator)
        view.bringSubviewToFront(activityIndicator)
        showEmptyViewInfo(searchInfo: EmptyLabelInfoText.searchInfoText)
    }

    // MARK: - TABLE VIEW DATA SOURCE METHODS

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection()
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = viewModel.tableView(tableView, cellForRowAt: indexPath) as? ALConversationCell,
            let message = viewModel.messageAtIndexPath(indexPath: indexPath)
            else { return UITableViewCell()
        }
        cell.update(message: message)
        return cell
    }

    // MARK: - TABLE VIEW DELEGATE METHODS

    public override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard  let message = viewModel.messageAtIndexPath(indexPath: indexPath) else {
            return
        }
        self.launchChat(message: message)
    }

    @objc public func search(key: String) {
        removeEmpty()
        activityIndicator.startAnimating()
        clear()
        viewModel.searchMessage(with: key) { (result) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                if (result) {
                    self.removeEmpty()
                    self.tableView.reloadData()
                } else {
                    self.showEmptyViewInfo(searchInfo: EmptyLabelInfoText.noSearchResultFound)
                }
            }
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.viewModel.clear()
            self.tableView.reloadData()
        }
    }

    @objc public func clearAndShowEmptyView() {
        showEmptyViewInfo(searchInfo: EmptyLabelInfoText.searchInfoText)
        self.clear()
    }

    func showEmptyViewInfo(searchInfo: String){
        emptyLabel.text = searchInfo
        self.tableView.backgroundView = emptyLabel
        self.tableView.separatorStyle = .none
    }

    func removeEmpty() {
        self.tableView.backgroundView = nil
    }

    func launchChat(message: ALMessage){
        let storyboard = UIStoryboard(name: "Applozic", bundle: Bundle(for: ALChatViewController.self))
        let chatView = storyboard.instantiateViewController(withIdentifier: "ALChatViewController") as! ALChatViewController
        chatView.isSearch = true
        chatView.individualLaunch = true
        chatView.displayName = nil

        if (message.groupId != nil ) {
            chatView.channelKey = message.groupId
            let channelService = ALChannelService()
            channelService.getChannelInformation(message.groupId, orClientChannelKey: nil) { (channel) in
                if (channel != nil) {
                    self.presentingViewController?.navigationController?.pushViewController(chatView, animated: true)
                }
            }
        } else {
            chatView.contactIds = message.to
            chatView.modalPresentationStyle = .fullScreen
            presentingViewController?.navigationController?.pushViewController(chatView, animated: true)
        }
    }
}
