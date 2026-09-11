cask "maaend" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "macos", linux: "linux"
  downloaded_file_format = on_system_conditional macos: "dmg", linux: "tar.gz"

  version "2.28.0"
  sha256  arm:          "836c815a586f99ec141d59f86df04dc0ce9d3d831393933539a2ce0d76245179",
          intel:        "db6f56335be9c2157cc905b64c4cf3906f8e16aa7f608d1d0aae85b1dbfb0ade",
          arm64_linux:  "4fd9307891197a9275090e03e2308f19bc2d82e242675cecae4fe5a487555860",
          x86_64_linux: "bdb6e562d204f33e265f387eb5ec4c87cdbceae273cb26b0beba5275ffbc81fe"

  on_macos do
    app "MaaEnd.app"

    uninstall quit: "com.maaend.app"

    zap trash: [
      "~/Library/Caches/com.maaend.app",
      "~/Library/WebKit/com.maaend.app",
    ]
  end
  on_linux do
    binary "MaaEnd"
  end

  language "zh", "CN" do
    desc "终末地小助手：基于视觉 AI 的「明日方舟：终末地」自动化工具"
    on_macos do
      caveats do
        <<~EOS
          安装完成！
          如果 macOS 因「此应用已经损坏」而拒绝启动，请执行以下命令：
            sudo xattr -cr /Applications/MaaEnd.app
        EOS
      end
    end
    "zh_CN"
  end
  language "en", default: true do
    desc "An Arknights:Endfield automation helper based on vision AI."
    on_macos do
      # This prints a helpful message to the user at the very end
      caveats do
        <<~EOS
          Installation completed!
          If macOS says this app is damaged or can't be opened, run this command:
            sudo xattr -cr /Applications/MaaEnd.app
        EOS
      end
    end
    "en_US"
  end

  url "https://github.com/MaaEnd/MaaEnd/releases/download/v#{version}/MaaEnd-#{os}-#{arch}-v#{version}.#{downloaded_file_format}"
  name "MaaEnd"
  homepage "https://github.com/MaaEnd/MaaEnd"

  # Documentation: https://docs.brew.sh/Brew-Livecheck
  livecheck do
    url :homepage
    strategy :github_latest
  end

  auto_updates true
  conflicts_with cask: "maaend-beta"
end
