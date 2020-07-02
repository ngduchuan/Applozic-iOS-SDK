//
//  ALSearchViewModel.swift
//  Applozic
//
//  Created by Sunil on 02/07/20.
//  Copyright © 2020 applozic Inc. All rights reserved.
//

import Foundation

class ALSearchViewModel: NSObject {
    var messageList = [ALMessage]()

    func numberOfSections() -> Int {
        return 1
    }

    func numberOfRowsInSection() -> Int {
        return messageList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < messageList.count && messageList.count > 1 ,
            let cell = tableView.dequeueReusableCell(withIdentifier: ALConversationCell.forCellReuseIdentifier, for: indexPath) as? ALConversationCell else { return UITableViewCell()
        }
        return cell
    }

    func clear(){
        messageList.removeAll()
    }

    func messageAtIndexPath(indexPath: IndexPath) -> ALMessage? {
        guard indexPath.row < messageList.count && messageList.count > 1 else {
            return nil
        }
        return messageList[indexPath.row] as ALMessage
    }

    func searchMessage(with key: String,
                       _ completion: @escaping ((_ result: Bool) -> Void)) {
        searchMessages(with: key) { messages, error in
            guard let messages = messages, error == nil else {
                print("Error \(String(describing: error)) while searching messages")
                completion(false)
                return
            }

            // Sort
            _ = messages
                .sorted(by: {
                    Int(truncating: $0.createdAtTime) > Int(truncating: $1.createdAtTime)
                }).filter {
                    ($0.groupId != nil || $0.to != nil)
            }.map {
                self.messageList.append($0)
            }
            completion(true)
        }
    }

    func searchMessages(
        with key: String,
        _ completion: @escaping (_ message: [ALMessage]?, _ error: Any?) -> Void
    ) {
        let service = ALMessageClientService()
        let request = ALSearchRequest()
        request.searchText = key
        service.searchMessage(with: request) { messages, error in
            guard
                let messages = messages as? [ALMessage]
                else {
                    completion(nil, error)
                    return
            }
            completion(messages, error)
        }
    }
}
