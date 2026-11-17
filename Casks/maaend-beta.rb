cask "maaend-beta" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "macos", linux: "linux"
  downloaded_file_format = on_system_conditional macos: "dmg", linux: "tar.gz"

  version "3.2.0-beta.4"
  sha256  arm:          "97d902e1510eb35537315929ea4187e336635c0262cc1d81e8b58a4adf1eeb5c",
          intel:        "4b69de936500da805168c11cb18c58caf863cd09a9dc2642b6e84df8af6e7674",
          arm64_linux:  "e2c355ce7012090f8f0be9d84b73653a31f00cd94c4bf80c7cf8a8f3b0e39cf2",
          x86_64_linux: "35e59b9820785c4b07645c4dc9be09f38fdf6fbc5ee4bc97390befdd1f5f2d27"

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
