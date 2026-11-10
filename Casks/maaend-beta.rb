cask "maaend-beta" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "macos", linux: "linux"
  downloaded_file_format = on_system_conditional macos: "dmg", linux: "tar.gz"

  version "3.1.0-beta.4"
  sha256  arm:          "f286a0447dc067a967ccac31427458bc96db360372860aebb3d153a8649c50bb",
          intel:        "6347d5e7bad8031047d7b66dbb8fce694146e21a0177d93e44fef56dbf8ee46b",
          arm64_linux:  "8ff8207e030cfe92566f3dc093c6fbed3b4f976832eca65f42979a905a917fe2",
          x86_64_linux: "dbf078b331c8ebfa9eb2fb6aaa214f098c192ed584c223e411acc6d6f91e61b6"

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
    desc "终末地小助手Beta版：基于视觉 AI 的「明日方舟：终末地」自动化工具"
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
    desc "An Arknights:Endfield automation helper based on vision AI, in beta version."
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
  name "MaaEnd Beta"
  homepage "https://github.com/MaaEnd/MaaEnd"

  # Documentation: https://docs.brew.sh/Brew-Livecheck
  livecheck do
    url :homepage
    strategy :git do |tags|
      tags.filter_map do |tag|
        # Matches versions like 2.26.0-beta.5 or v2.26.0-beta.5
        tag[/^v?(\d+(?:\.\d+)+(?:-beta\.\d+)?)$/i, 1]
      end
    end
  end

  auto_updates true
  conflicts_with cask: "maaend"
end
