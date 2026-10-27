# TUIChatKit：Swift Package Manager 接入

[English](README.md) | 简体中文

TUIChatKit 是腾讯云基于 AtomicXCore 和即时通信 IM 构建的 iOS 聊天 UI 组件库，提供会话列表、通讯录、单聊与群聊等 UIKit 页面，可通过 Swift Package Manager（SwiftPM）集成到已有应用。

本仓库仅对外提供 `TUIChatKit` product，UIKit 源码来自 [TUIKit_iOS 的 `chat/uikit` 目录](https://github.com/Tencent-RTC/TUIKit_iOS/tree/main/chat/uikit)。**9.1.7822** 版本以 TUIKit_iOS `main` 分支的 [`b818d3e5`](https://github.com/Tencent-RTC/TUIKit_iOS/commit/b818d3e52c2c5efa87bc6a64321dac26c3160e7b) 提交为基准。

## 功能

- 会话列表及置顶、免打扰、标为未读、删除会话、清空历史等操作。
- 单聊、群聊，以及文本、图片、视频、语音、文件、表情消息。
- 可配置的消息菜单：复制、引用、转发、撤回、删除、多选、表情回应。
- @提及、已读回执、正在输入状态及聊天背景。
- 通讯录、好友申请、群申请、我的群组和黑名单。
- 自定义消息展示、输入菜单、消息菜单与气泡外观。
- 浅色/深色主题、自定义主色、英语、简体中文、繁体中文、阿拉伯语及 RTL 布局。
- 语音转文字、翻译和朗读能力接入，实际可用性取决于账号配置与服务支持。

本 product 不包含完整的音视频通话 UI。处理聊天组件的通话事件时，需要单独接入通话组件，可参考 [CallKit_SwiftPM](https://github.com/Tencent-RTC/CallKit_SwiftPM)。

## 环境要求

- iOS 14.0 及以上。
- SwiftPM tools version 5.9 及以上，同时需要编译器兼容二进制依赖。
- 推荐使用 Xcode 16 及以上。本版本已使用 Xcode 26.1.1 完成 iOS 真机与模拟器构建验证。
- 已创建腾讯云 IM 应用，并取得 `SDKAppID`、`UserID` 和有效的 `UserSig`。

验证 demo 的最低系统版本为 iOS 15.0，不影响组件的 iOS 14.0 部署目标。

## 集成

### 通过 Xcode 添加依赖

1. 选择 **File → Add Package Dependencies**。
2. 输入 `https://github.com/Tencent-RTC/ChatKit_SwiftPM.git`。
3. 如需复现本次发布，选择 **Exact Version**，填写 `9.1.7822`；后续升级可按需设置版本范围。
4. 将 **TUIChatKit** product 添加到应用 target。

`AlbumPicker`、`AlbumPickerCore` 是内部二进制 target，不单独作为 product 提供。SwiftPM 会自动下载并嵌入对应 XCFramework 和资源，无需手动拷贝。不要在同一个 target 中通过 CocoaPods 再次引入这些依赖，以免产生重复链接或模块冲突。

### 在 `Package.swift` 中声明依赖

在宿主 package 的依赖列表和 target 中加入：

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

导入 UI 模块：

```swift
import TUIChatKit
```

如果应用直接调用 `LoginStore`、构造 `ConversationInfo` 或使用其他 AtomicXCore 类型，还需把 `https://github.com/Tencent-RTC/AtomicXCore_SwiftPM.git` 中的 **AtomicXCore** product 添加到 target，并保持版本范围与 TUIChatKit 一致：`3.0.0..<5.0.0`。

## 初始化与登录

先在[腾讯云 IM 控制台](https://console.cloud.tencent.com/im)创建应用，再由可信服务端为当前用户签发 `UserSig`。不要将应用密钥写入客户端，也不要在生产环境中使用客户端生成 UserSig。

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

登录成功后展示聊天页面。登录失败时，应由宿主应用提供错误提示与重试流程。

## 使用 UIKit 页面

### 会话列表

`ConversationsPage` 的点击回调提供会话信息和可选的定位消息，可嵌入应用的导航或 tab 布局。

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

### 打开单聊或群聊

`ChatPage` 接收 `ConversationInfo`，不能直接传入裸 `userID` 或 `groupID`。群聊要求当前用户已具备访问该群的权限；打开页面不会创建群或自动入群。

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

将独立 `ChatPage` 推入导航栈时，需要像会话列表示例一样设置 `onBack`，将组件返回按钮连接到宿主导航控制器。

### 通讯录

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

示例中的 `navigationController` 为宿主应用的导航控制器。如使用聊天组件自带的返回按钮，也需为上述聊天页配置 `onBack`。

## 权限与自定义

按启用的媒体功能，在应用 `Info.plist` 中填写相应权限说明：

| Key | 用途 |
| --- | --- |
| `NSMicrophoneUsageDescription` | 录制语音消息 |
| `NSCameraUsageDescription` | 拍照、录制视频 |
| `NSPhotoLibraryUsageDescription` | 选择照片和视频 |
| `NSPhotoLibraryAddUsageDescription` | 保存媒体到相册 |

权限文案应明确说明用途并做好本地化。媒体功能会按需请求权限；填写说明本身不会自动取得授权。

```swift
ThemeState.shared.setThemeMode(.system)
LanguageHelper.saveLanguage("zh-Hans")
```

主题支持 `.system`、`.light`、`.dark`。进一步定制可使用 `ChatMessageListConfig`、`ChatMessageInputConfig`、会话/联系人配置以及 `ChatPage` 的回调。

## 目录与依赖

```text
ChatKit_SwiftPM/
├── Sources/
├── Package.swift
├── README.md
├── README.cn.md
└── LICENSE
```

| 依赖 | 版本约束 |
| --- | --- |
| AtomicXCore_SwiftPM | `>= 3.0.0`，`< 5.0.0` |
| Chat_SDK_SwiftPM | `>= 9.0.7652`，`< 10.0.0` |
| Kingfisher | `>= 8.11.0`，`< 8.12.0` |
| SnapKit | `>= 5.7.1`，`< 6.0.0` |
| AlbumPicker / AlbumPickerCore | `1.0.8` 二进制制品 |

TUIChatKit 的发布版本与依赖版本独立。SwiftPM 会编译 asset catalog，并保留本地化 bundle 的目录结构，无需额外拷贝资源。

## 示例与文档

- [TUIKit_iOS 仓库与示例工程](https://github.com/Tencent-RTC/TUIKit_iOS)
- [TUIKit_iOS 中文介绍](https://github.com/Tencent-RTC/TUIKit_iOS/blob/main/README.cn.md)
- [TUIKit_iOS English overview](https://github.com/Tencent-RTC/TUIKit_iOS/blob/main/README.md)
- [腾讯云即时通信文档](https://cloud.tencent.com/document/product/269)
- [AtomicXCore 文档](https://tencent-rtc.github.io/TUIKit_iOS/documentation/atomicxcore)

以上文档覆盖更广泛的 TUIKit/SDK 生态，本文中的 UIKit 构造方式针对本 package。问题反馈请提交至 [GitHub Issues](https://github.com/Tencent-RTC/ChatKit_SwiftPM/issues)，附组件版本、Xcode 版本、设备/系统和复现步骤，不要包含密钥或私聊内容。

## 许可证

TUIChatKit 源码遵循 [MIT License](LICENSE)，版权所有 © 2026 Tencent。第三方依赖与二进制 SDK 分别遵循各自许可证和服务条款。
