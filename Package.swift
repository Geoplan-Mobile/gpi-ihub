// swift-tools-version: 5.9
//
// release repo 배포 매니페스트 (wrapper 패턴).
// binaryTarget 은 자체적으로 의존성을 선언할 수 없어, 의존성을 실어보내는
// carrier target(gpi-ihub-deps) 을 함께 둔다. 소비 앱은 gpi-ihub 하나만
// 의존하면 되고, gpi-ihub-deps 의 존재를 인지하지 못한다.
//

import PackageDescription

let package = Package(
    name: "gpi-ihub",
    platforms: [
        .iOS("27.0"),
    ],
    products: [
        .library(
            name: "gpi-ihub",
            targets: ["gpi-ihub", "gpi-ihub-deps"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Geoplan-Mobile/gpi-dltdoa.git",
            exact: "2.1.0"
        ),
        .package(
            url: "https://github.com/Geoplan-Mobile/gpi-prm.git",
            exact: "2.0.0"
        ),
        .package(
            url: "https://github.com/Geoplan-Mobile/gpi-logger.git",
            from: "1.0.1"
        ),
    ],
    targets: [
        .binaryTarget(
            name: "gpi-ihub",
            path: "gpi-ihub.xcframework"
        ),
        .target(
            name: "gpi-ihub-deps",
            dependencies: [
                .product(name: "gpi-dltdoa", package: "gpi-dltdoa"),
                .product(name: "gpi-prm", package: "gpi-prm"),
                .product(name: "gpi-logger", package: "gpi-logger"),
            ]
        ),
    ]
)
