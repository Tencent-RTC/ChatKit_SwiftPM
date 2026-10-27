# TUIChatKit for Swift Package Manager

English | [简体中文](README.cn.md)

TUIChatKit is Tencent Cloud's ready-to-use iOS chat UI library built on AtomicXCore and Tencent Cloud Chat. It provides UIKit pages for conversations, contacts, one-to-one chats, and group chats. Add it to an existing application through Swift Package Manager (SwiftPM).

This repository distributes the `TUIChatKit` product. Its UIKit source comes from the [`chat/uikit` directory of TUIKit_iOS](https://github.com/Tencent-RTC/TUIKit_iOS/tree/main/chat/uikit). Version **9.1.7822** is based on the TUIKit_iOS `main` commit [`b818d3e5`](https://github.com/Tencent-RTC/TUIKit_iOS/commit/b818d3e52c2c5efa87bc6a64321dac26c3160e7b).

## Features

- Conversation lists with pin, mute, mark-unread, delete, and clear-history actions.
- One-to-one and group messaging: text, images, video, voice, files, and stickers.
- Configurable message actions: copy, quote, forward, recall, delete, multiselect, and emoji reactions.
- Mentions, read receipts, typing indicators, and chat backgrounds.
- Contacts, friend requests, group applications, joined groups, and blacklists.
- Custom message rendering, input menus, message menus, and bubble appearance.
- Light/dark themes, custom primary colors, English, Simplified Chinese, Traditional Chinese, Arabic, and RTL layouts.
- Speech-to-text, translation, and read-aloud integrations, subject to account configuration and service availability.

Voice/video call UI is not part of this product. Integrate a calling component separately when handling the chat UI's call events. See [CallKit_SwiftPM](https://github.com/Tencent-RTC/CallKit_SwiftPM).

## Requirements

- iOS 14.0 or later.
- SwiftPM tools version 5.9 or later; a compiler compatible with the binary dependencies is also required.
- Xcode 16 or later is recommended. This release has been build-validated with Xcode 26.1.1 for iOS devices and simulators.
- A Tencent Cloud Chat application with an `SDKAppID`, a `UserID`, and a valid `UserSig`.

The verification demo targets iOS 15.0. This does not change the library's iOS 14.0 deployment target.

## Install

### Add the package in Xcode

1. Select **File → Add Package Dependencies**.
2. Enter `https://github.com/Tencent-RTC/ChatKit_SwiftPM.git`.
3. Select **Exact Version** and enter `9.1.7822` to reproduce this release. Use an appropriate version range for future updates.
4. Add the **TUIChatKit** product to your application target.

`AlbumPicker` and `AlbumPickerCore` are internal binary targets, not separately exposed products. SwiftPM automatically downloads and embeds their XCFrameworks and resources. Do not add duplicate CocoaPods copies of these dependencies to the same target.

### Declare a SwiftPM dependency

Add the following dependency and product reference to your package:

```swift
dependencies: [
    .package(
        url: "https://github.com/Tencent-RTC/ChatKit_SwiftPM.git",
        exact: "9.1.7822"
    )
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "TUIChatKit", package: "ChatKit_SwiftPM")
        ]
    )
]
```

Import the UI module:

```swift
import TUIChatKit
```

If your application directly uses `LoginStore`, `ConversationInfo`, or other AtomicXCore types, also add the **AtomicXCore** product from `https://github.com/Tencent-RTC/AtomicXCore_SwiftPM.git` to your target. Keep its version in the same `3.0.0..<5.0.0` range as TUIChatKit.

## Authenticate

Create your Chat application in the [Tencent Cloud Chat console](https://console.cloud.tencent.com/im). Obtain a server-issued `UserSig` for the user before showing chat pages. Never embed the application's secret key or generate production UserSig values in the client.

```swift
import AtomicXCore
import TUIChatKit
import UIKit

func loginChat(
    sdkAppID: Int32,
    userID: String,
    userSig: String,
    completion: @escaping (Bool) -> Void
) {
    LoginStore.shared.login(
        sdkAppID: sdkAppID,
        userID: userID,
        userSig: userSig
    ) { result in
        DispatchQueue.main.async {
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }
}
```

Show your application UI after successful login, and handle login failures in your application's error flow.

## Use the UIKit pages

### Conversations

`ConversationsPage` reports the selected conversation and an optional message to locate. Embed the page in your navigation or tab layout.

```swift
func makeConversationsPage(
    navigationController: UINavigationController
) -> ConversationsPage {
    ConversationsPage(onConversationClick: { [weak navigationController] info in
        guard let navigationController = navigationController else { return }
        let chat = ChatPage(
            conversation: info.conversation,
            locateMessage: info.locateMessage,
            onBack: { [weak navigationController] in
                navigationController?.popViewController(animated: true)
            }
        )
        navigationController.pushViewController(chat, animated: true)
    })
}
```

### Open a one-to-one or group chat

`ChatPage` accepts a `ConversationInfo`, not a raw user ID or group ID. For a group chat, the user must already have access to the group; opening a page does not create or join it.

```swift
func makeC2CChat(userID: String) -> ChatPage {
    var conversation = ConversationInfo(
        conversationID: ChatUtil.getC2CConversationID(userID)
    )
    conversation.type = .c2c
    conversation.title = userID
    return ChatPage(conversation: conversation)
}

func makeGroupChat(groupID: String) -> ChatPage {
    var conversation = ConversationInfo(
        conversationID: ChatUtil.getGroupConversationID(groupID)
    )
    conversation.type = .group
    conversation.title = groupID
    return ChatPage(conversation: conversation)
}
```

When pushing a standalone `ChatPage`, supply `onBack` to connect its back button to your navigation controller, as in the conversation example above.

### Contacts

```swift
let contacts = ContactsPage(
    onContactClick: { contact in
        let page = makeC2CChat(userID: contact.userID)
        navigationController.pushViewController(page, animated: true)
    },
    onGroupClick: { group in
        let page = makeGroupChat(groupID: group.groupID)
        navigationController.pushViewController(page, animated: true)
    }
)
```

The `navigationController` in this snippet is the host application's navigation controller. Configure `onBack` for these chat pages if using the component's own back button.

## Permissions and customization

Add usage descriptions to your application's `Info.plist` for the features you enable:

| Key | Purpose |
| --- | --- |
| `NSMicrophoneUsageDescription` | Record voice messages |
| `NSCameraUsageDescription` | Take photos and record video |
| `NSPhotoLibraryUsageDescription` | Select photos and videos |
| `NSPhotoLibraryAddUsageDescription` | Save media to the photo library |

Use meaningful, localized permission descriptions. Permissions are requested by the corresponding media features; including a usage description does not grant access automatically.

```swift
ThemeState.shared.setThemeMode(.system)
LanguageHelper.saveLanguage("zh-Hans")
```

Theme modes include `.system`, `.light`, and `.dark`. For more customization, use `ChatMessageListConfig`, `ChatMessageInputConfig`, conversation/contact configs, and the callbacks on `ChatPage`.

## Package layout and dependencies

```text
ChatKit_SwiftPM/
├── Sources/
├── Package.swift
├── README.md
├── README.cn.md
└── LICENSE
```

| Dependency | Constraint |
| --- | --- |
| AtomicXCore_SwiftPM | `>= 3.0.0`, `< 5.0.0` |
| Chat_SDK_SwiftPM | `>= 9.0.7652`, `< 10.0.0` |
| Kingfisher | `>= 8.11.0`, `< 8.12.0` |
| SnapKit | `>= 5.7.1`, `< 6.0.0` |
| AlbumPicker / AlbumPickerCore | `1.0.8` binary artifacts |

The TUIChatKit release version is independent of these dependency versions. Asset catalogs are processed by SwiftPM; localized bundles retain their directory structure. No manual resource copying is required.

## Demo and documentation

- [TUIKit_iOS repository and demos](https://github.com/Tencent-RTC/TUIKit_iOS)
- [TUIKit_iOS English overview](https://github.com/Tencent-RTC/TUIKit_iOS/blob/main/README.md)
- [TUIKit_iOS 中文介绍](https://github.com/Tencent-RTC/TUIKit_iOS/blob/main/README.cn.md)
- [Tencent Cloud Chat documentation](https://cloud.tencent.com/document/product/269)
- [AtomicXCore documentation](https://tencent-rtc.github.io/TUIKit_iOS/documentation/atomicxcore)

These links cover the broader TUIKit/SDK ecosystem; the UIKit constructors shown above are specific to this package. Report issues through [GitHub Issues](https://github.com/Tencent-RTC/ChatKit_SwiftPM/issues), including the package version, Xcode version, device/OS, and reproduction steps. Do not include credentials or private message content.

## License

TUIChatKit source is distributed under the [MIT License](LICENSE), copyright © 2026 Tencent. Third-party packages and binary SDKs retain their own licenses and service terms.
