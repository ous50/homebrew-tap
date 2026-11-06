cask "maaend-beta" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "macos", linux: "linux"
  downloaded_file_format = on_system_conditional macos: "dmg", linux: "tar.gz"

  version "3.0.0"
  sha256  arm:          "1a06b953e6c5c7b21c683af282432e41623107772a28bc0e1ddf19b93dc02c32",
          intel:        "ee8e7aba46436a2756d7406dfb90e77f021ee41ba200de41a816d8dc0171f01b",
          arm64_linux:  "c742b9281559ff990ecab9b17392e75d700d64eb9eadf068abfb77eebf560531",
          x86_64_linux: "891de92d40613fde9db259ff31a3d36255ed9c6f830fca9a4c0d2d65be797995"

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
