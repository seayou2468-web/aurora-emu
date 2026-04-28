// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let endpoint: String = "https://github.com/folium-app/SharedDependencies/releases/download"
let version: String = "0.0.5"
let `extension`: String = "xcframework.zip"

func url(_ name: String, _ version: String = "0.0.5") -> String {
    "\(endpoint)/\(version)/\(name).\(`extension`)"
}

let package = Package(
    name: "SharedDependencies",
    platforms: [
        .iOS(.v16),
        .macOS(.v26)
    ],
    products: [
        .library(name: "SharedDependencies", targets: [
            "SharedDependencies"
        ])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/OpenSSL", branch: "main")
    ],
    targets: [
        .target(name: "SharedDependencies", dependencies: [
            "lib_boostcontext",
            "lib_boostiostreams",
            "lib_boostprogramoptions",
            "lib_boostserialization",
            "lib_dynarmic",
            "lib_fmt",
            "lib_mcl",
            "lib_enet",
            "lib_faad2",
            "lib_genericcodegen",
            "lib_glslang",
            "lib_machineindependent",
            "lib_spirv",
            "lib_openal",
            "lib_opus",
            "lib_sdl3",
            "lib_sirit",
            "lib_soundtouch",
            "lib_teakra",
            "cereal",
            "cryptopp",
            "dds_ktx",
            "eventbus",
            "glib",
            "httplib",
            "inih",
            "jwt",
            "libslirp",
            "lodepng",
            "magic_enum",
            "metal_cpp",
            "microprofile",
            "miniz",
            "nihstro",
            "nlohmann",
            "oaknut",
            "stb",
            "toml",
            "tsl",
            "xxhash"
        ], path: "Sources/SharedDependencies", publicHeadersPath: "include", cxxSettings: [
            .define("SDL_MAIN_HANDLED")
        ]),
        .target(name: "cereal", publicHeadersPath: "include"),
        .target(name: "cryptopp", publicHeadersPath: "include", cxxSettings: [
            .define("CRYPTOPP_DISABLE_ARM_CRC32"),
            .headerSearchPath("include/cryptopp")
        ]),
        .target(name: "dds_ktx", publicHeadersPath: "include"),
        .target(name: "eventbus", publicHeadersPath: "include"),
        .target(name: "glib", publicHeadersPath: "include"),
        .target(name: "httplib", publicHeadersPath: "include"),
        .target(name: "inih", publicHeadersPath: "include"),
        .target(name: "jwt", dependencies: [
            "OpenSSL"
        ], publicHeadersPath: "include"),
        .target(name: "libslirp", dependencies: [
            "glib"
        ], publicHeadersPath: "include", cSettings: [
            .unsafeFlags([
                "-D_NETINET_TCP_VAR_H_",
                "-ffast-math"
            ])
        ]),
        .target(name: "lodepng", publicHeadersPath: "include"),
        .target(name: "magic_enum", publicHeadersPath: "include"),
        .target(name: "metal_cpp", publicHeadersPath: "include"),
        .target(name: "microprofile", publicHeadersPath: "include"),
        .target(name: "miniz", publicHeadersPath: "include"),
        .target(name: "nihstro", sources: [
            "parser_assembly"
        ], publicHeadersPath: "include", cxxSettings: [
            .unsafeFlags([
                "-I/opt/homebrew/include",
                "-I/usr/local/include"
            ])
        ]),
        .target(name: "nlohmann", publicHeadersPath: "include"),
        .target(name: "oaknut", publicHeadersPath: "include"),
        .target(name: "stb", publicHeadersPath: "include"),
        .target(name: "toml", publicHeadersPath: "include"),
        .target(name: "tsl", publicHeadersPath: "include"),
        .target(name: "xxhash", publicHeadersPath: "include"),
        
        .binaryTarget(name: "lib_boostcontext",
                      url: url("lib_boostcontext", "0.0.6"),
                      checksum: "0fdb5520d200b5c2b0b376c396b8271c8bf1627d576884e1a255a5630abddda1"),
        
        .binaryTarget(name: "lib_boostiostreams",
                      url: url("lib_boostiostreams", "0.0.6"),
                      checksum: "496dacfaa036ab2e6287a034f6659dd68e18c6808f00080a6dd546451fd0ae31"),
        
        .binaryTarget(name: "lib_boostprogramoptions",
                      url: url("lib_boostprogramoptions", "0.0.6"),
                      checksum: "a405b06fa63794e25334b6e4fa37ab34c8e541696f2ab9e02edae598d1dbda1a"),
        
        .binaryTarget(name: "lib_boostserialization",
                      url: url("lib_boostserialization", "0.0.6"),
                      checksum: "c1935bdb9c5b3611885399370b6f9a35a005ff0842bf02cd870cf1e150ce1a20"),
        
        .binaryTarget(name: "lib_dynarmic",
                      url: url("lib_dynarmic", "0.0.7"),
                      checksum: "cb5860a2db80f3b433b924b763cd8261cc64470d3480f0db67a764109d039de9"),
        
        .binaryTarget(name: "lib_enet",
                      url: url("lib_enet", "0.0.6"),
                      checksum: "3b26f257c9a7262fb3b41d3b8769b7326a1b57e21ac69c9366e15cc6543c5daa"),
        
        .binaryTarget(name: "lib_faad2",
                      url: url("lib_faad2", "0.0.6"),
                      checksum: "0a9ef946173bb718db2dd92bb99694bc05bdef9655067447c309bf01068fad93"),
        
        .binaryTarget(name: "lib_fmt",
                      url: url("lib_fmt", "0.0.7"),
                      checksum: "251329dee13a24aba30b9a2cf5f1ed769830fc53ac59573da483ebc4e5707cb7"),
        
        .binaryTarget(name: "lib_genericcodegen",
                      url: url("lib_genericcodegen", "0.0.6"),
                      checksum: "e3fc490833ab15667fb138bbc11b8980200f7901b973be70598b80de04369464"),
        
        .binaryTarget(name: "lib_glslang",
                      url: url("lib_glslang", "0.0.6"),
                      checksum: "25990afa3598b854d26cf1584e0ac0cb577d07765a2a7dd3539dfc69d4ed8553"),
        
        .binaryTarget(name: "lib_machineindependent",
                      url: url("lib_machineindependent", "0.0.6"),
                      checksum: "c7e57cc8941f55e8976911fe5e80c273a7f9b9a54dc86e39dede2f68364b7bed"),
        
        .binaryTarget(name: "lib_mcl",
                      url: url("lib_mcl", "0.0.7"),
                      checksum: "2c1245bc505755817d5504eb52ac89974ae5dbc08f1fe48afcb34b2e060bc162"),
        
        .binaryTarget(name: "lib_openal",
                      url: url("lib_openal", "0.0.6"),
                      checksum: "cd3b705180897f46c1568623ef505df5d1e6561204673a83e10d9fe68278daf2"),
        
        .binaryTarget(name: "lib_opus",
                      url: url("lib_opus", "0.0.6"),
                      checksum: "e4eae58d69642d6ff647e89dbf9a3fe360448c1e3e9a818c2514a4ad81a75e56"),
        
        .binaryTarget(name: "lib_sdl3",
                      url: url("lib_sdl3", "0.0.7"),
                      checksum: "157266698caea1dc10eff355d2d500eb15f994f17f52f16e8cee20f15cc99a9b"),
        
        .binaryTarget(name: "lib_sirit",
                      url: url("lib_sirit", "0.0.6"),
                      checksum: "b03a5e4fe9dbda4b9e74d354c43e447e8edfed4fef8578345e6061a3ce6806fe"),
        
        .binaryTarget(name: "lib_soundtouch",
                      url: url("lib_soundtouch", "0.0.6"),
                      checksum: "954cdde14d37cfaec06e0c7580c4c6ab4eb8fb3b5f01967dd33ab026fde19135"),
        
        .binaryTarget(name: "lib_spirv",
                      url: url("lib_spirv", "0.0.6"),
                      checksum: "56d38af6be42a19d7366d94a4021df2be8e9cedd8178917ed702893a04c76e99"),
        
        .binaryTarget(name: "lib_teakra",
                      url: url("lib_teakra", "0.0.7"),
                      checksum: "1acbc735d0ada8aa9111f4c9b928d83bb440039d45d35ae2f3f67429ff8f6bb3"),
        
        
    ],
    cLanguageStandard: .gnu2x,
    cxxLanguageStandard: .gnucxx2b
)
