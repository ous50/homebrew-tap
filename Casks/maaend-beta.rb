cask "maaend-beta" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "macos", linux: "linux"
  downloaded_file_format = on_system_conditional macos: "dmg", linux: "tar.gz"

  version "3.2.0-beta.3"
  sha256  arm:          "149cfd7051a176fd44546711e8450eeef8a5912dffc6dd059aef69e2bb3dce40",
          intel:        "8319fb0a665d95cdb716288fa19200f68445b6b05d206f4a0f22a9f7bedca45a",
          arm64_linux:  "4d8f68b2ce22f9d5e08c845c848a588fdd10fe813bc3e7ac902036ec674db106",
          x86_64_linux: "26eacfa03428ffbc11f77c1538c036ea0f3130566bf3b2427f631f9616078f17"

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
