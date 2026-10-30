cask "maaend" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "macos", linux: "linux"
  downloaded_file_format = on_system_conditional macos: "dmg", linux: "tar.gz"

  version "2.35.0"
  sha256  arm:          "9e03657fc3e57a6825171e35bccfe640e9c346ec0f6642e1e8d8d94a9954736c",
          intel:        "c5331ebac15378cb6bffb6940ba8534ae33b118eeebeb33ae4ba857d4d61dcf6",
          arm64_linux:  "a6c2da87122b7b05e2463467ae3f50bdb04c1eb238803c15d87d88a57319e77e",
          x86_64_linux: "ffa3e3bee28a5bc421eb395660e8e5f933c4272897463dbb1cd8a98590bb1589"

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
