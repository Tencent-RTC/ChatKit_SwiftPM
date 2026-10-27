// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TUIChatKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "TUIChatKit", targets: ["TUIChatKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Tencent-RTC/AtomicXCore_SwiftPM.git", "3.0.0"..<"5.0.0"),
        .package(url: "https://github.com/Tencent-RTC/Chat_SDK_SwiftPM.git", .upToNextMajor(from: "9.0.7652")),
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMinor(from: "8.11.0")),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
    ],
    targets: [
        .binaryTarget(
            name: "AlbumPickerCore",
            url: "https://liteav.sdk.qcloud.com/app/tuikit/download/release/1.0/AlbumPickerCore_1.0.8.zip",
            checksum: "efc6df223819804e128d7bb3483e9e7560331ab9fddbe7e7307776af780b9c96"
        ),
        .binaryTarget(
            name: "AlbumPicker",
            url: "https://sdk-im-1252463788.cos.ap-hongkong.myqcloud.com/album-picker/1.0.8/AlbumPicker_1.0.8.zip",
            checksum: "826c89c2329dd2ec886ee7a8614a1b8099ea834117a973531b4fdfb7aeab54de"
        ),
        .target(
            name: "TUIChatKit",
            dependencies: [
                "AlbumPicker",
                "AlbumPickerCore",
                .product(name: "AtomicXCore", package: "AtomicXCore_SwiftPM"),
                .product(name: "Chat_SDK_SwiftPM", package: "Chat_SDK_SwiftPM"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "SnapKit", package: "SnapKit"),
            ],
            path: "Sources",
            exclude: ["LICENSE"],
            resources: [
                .process("resources/assets/chat/chat.xcassets"),
                .process("resources/assets/chat/videorecorder.xcassets"),
                .copy("resources/strings"),
                .copy("resources/assets/chat/VideoRecorder.bundle")
            ]
        )
    ]
)
