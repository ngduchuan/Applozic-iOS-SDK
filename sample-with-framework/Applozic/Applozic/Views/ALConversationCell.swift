//
//  ALConversationCell.swift
//  Applozic
//
//  Created by Sunil on 29/06/20.
//  Copyright © 2020 applozic Inc. All rights reserved.
//

import Foundation

public class ALConversationCell : UITableViewCell {

    let channelService = ALChannelService()
    let contactService = ALContactService()
    let messageClientService = ALMessageClientService()
    static let forCellReuseIdentifier = "ALConversationCell"

    enum Padding {
        enum AvatarImageView {
            static let top: CGFloat = 15.0
            static let leading: CGFloat = 17.0
            static let height: CGFloat = 50
            static let width: CGFloat = 50
        }

        enum BadgeNumberLabel {
            static let top: CGFloat = 2.0
            static let bottom: CGFloat = -2.0
            static let trailing: CGFloat = -2.0
            static let leading: CGFloat = 2.0
            static let height: CGFloat = 11.0
            static let width: CGFloat = 11.0
        }

        enum BadgeNumberView {
            static let top: CGFloat = 0
            static let leading: CGFloat = -12.0
        }

        enum NameLabel {
            static let top: CGFloat = 2.0
            static let leading: CGFloat = 15.0
            static let height: CGFloat = 20.0
            static let trailing: CGFloat = -10.0
        }

        enum MessageTextLabel {
            static let top: CGFloat = 2.0
            static let height: CGFloat = 20.0
            static let leading: CGFloat = 15.0
            static let trailing: CGFloat = -10.0
        }

        enum TimeLabel {
            static let trailing: CGFloat = -19.0
            static let height: CGFloat = 15.0
            static let width: CGFloat = 70.0
            static let top: CGFloat = 0
        }
    }

    private var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 22.5
        imv.translatesAutoresizingMaskIntoConstraints = false
        layer.backgroundColor = UIColor.clear.cgColor
        layer.masksToBounds = true
        return imv
    }()

    private var nameLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        label.textColor = .gray
        return label
    }()

    private var messageTextLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "HelveticaNeue", size: 14)
        label.textColor = UIColor(red: 155/255.0, green: 155/255.0, blue: 155/255.0, alpha: 1.0)
        return label
    }()

    private var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "HelveticaNeue", size: 14)
        label.textColor = UIColor(red: 155/255.0, green: 155/255.0, blue: 155/255.0, alpha: 1.0)
        label.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .left : .right
        return label
    }()

    private lazy var badgeNumberView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ALApplozicSettings.getUnreadCountLabelBGColor()
        return view
    }()

    private lazy var badgeNumberLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "0"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont(name: "HelveticaNeue", size: 9)
        return label
    }()

    private var lineView: UIView = {
        let view = UIView()
        let layer = view.layer
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 200.0 / 255.0, green: 199.0 / 255.0, blue: 204.0 / 255.0, alpha: 0.33)
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(messageTextLabel)
        contentView.addSubview(badgeNumberView)
        contentView.addSubview(badgeNumberLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(lineView)

        contentView.bringSubviewToFront(nameLabel)
        contentView.bringSubviewToFront(messageTextLabel)
        contentView.bringSubviewToFront(badgeNumberLabel)
        contentView.bringSubviewToFront(timeLabel)
        contentView.bringSubviewToFront(lineView)

        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.AvatarImageView.leading).isActive = true
        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.AvatarImageView.top).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: Padding.AvatarImageView.height).isActive = true
        avatarImageView.widthAnchor.constraint(equalToConstant: Padding.AvatarImageView.width).isActive = true

        nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: Padding.NameLabel.height).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Padding.NameLabel.leading).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: Padding.NameLabel.trailing).isActive = true

        timeLabel.heightAnchor.constraint(equalToConstant: Padding.TimeLabel.height).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Padding.TimeLabel.trailing).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: Padding.TimeLabel.width).isActive = true
        timeLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: Padding.TimeLabel.top).isActive = true

        messageTextLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Padding.MessageTextLabel.top).isActive = true
        messageTextLabel.heightAnchor.constraint(equalToConstant: Padding.MessageTextLabel.height).isActive = true
        messageTextLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Padding.MessageTextLabel.leading).isActive = true
        messageTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Padding.MessageTextLabel.trailing).isActive = true

        badgeNumberView.addSubview(badgeNumberLabel)
        badgeNumberView.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: Padding.BadgeNumberView.top).isActive = true
        badgeNumberView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Padding.BadgeNumberView.leading).isActive = true

        badgeNumberLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)

        badgeNumberLabel.topAnchor.constraint(equalTo: badgeNumberView.topAnchor, constant: Padding.BadgeNumberLabel.top).isActive = true
        badgeNumberLabel.bottomAnchor.constraint(equalTo: badgeNumberView.bottomAnchor, constant: Padding.BadgeNumberLabel.bottom).isActive = true
        badgeNumberLabel.leadingAnchor.constraint(equalTo: badgeNumberView.leadingAnchor, constant: Padding.BadgeNumberLabel.leading).isActive = true
        badgeNumberLabel.trailingAnchor.constraint(equalTo: badgeNumberView.trailingAnchor, constant: Padding.BadgeNumberLabel.trailing).isActive = true

        badgeNumberLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: Padding.BadgeNumberLabel.width).isActive = true
        badgeNumberLabel.heightAnchor.constraint(greaterThanOrEqualToConstant:  Padding.BadgeNumberLabel.height).isActive = true

        lineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        lineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        lineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        contentView.layoutIfNeeded()
        badgeNumberView.layer.cornerRadius = badgeNumberView.frame.size.height / 2.0

    }

    func update(message : ALMessage)  {
        messageTextLabel.text = message.getLastMessage()
        var imageURl : String? = ""
        var placeHolderImageName = ""
        var totalNumberOfUnreadMesageCount = 0
        if (message.groupId != nil) {
            let channel = channelService.getChannelByKey(message.groupId)
            imageURl = channel?.channelImageURL ?? "";
            nameLabel.text =  channel?.name
            placeHolderImageName = "applozic_group_icon.png"
            totalNumberOfUnreadMesageCount = Int(truncating: channel?.unreadCount ?? 0)

        } else {
            let contact = contactService .loadContact(byKey: "userId", value: message.to)

            placeHolderImageName = "ic_contact_picture_holo_light.png"
            imageURl = contact?.contactImageUrl ?? "";
            nameLabel.text =  contact?.getDisplayName()
            totalNumberOfUnreadMesageCount = Int(truncating: contact?.unreadCount ?? 0)
        }

        messageClientService.downloadImageUrlAndSet(imageURl, imageView: avatarImageView, defaultImage: placeHolderImageName)
        
        let unreadMsgCount = totalNumberOfUnreadMesageCount
        let numberText: String = (unreadMsgCount < 1000 ? "\(unreadMsgCount)" : "999+")

        let isHidden = (unreadMsgCount < 1)

        badgeNumberView.isHidden = isHidden
        badgeNumberLabel.text = numberText

        let isToday = ALUtilityClass.isToday(Date(timeIntervalSince1970: TimeInterval(message.createdAtTime.doubleValue / 1000)))

        timeLabel.text = message.getCreatedAtTime(isToday)
    }

}
