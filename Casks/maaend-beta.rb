cask "maaend-beta" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "macos", linux: "linux"
  downloaded_file_format = on_system_conditional macos: "dmg", linux: "tar.gz"

  version "3.3.0-beta.5"
  sha256  arm:          "f000307b9075bc5466362c3f65b2af5ea0070f94d3ac149fe41d90fc9bba0f9e",
          intel:        "5f07fdc995886b85c8dfd72578156dbea5eff165ff6451028eda98e747155195",
          arm64_linux:  "fa049df1645fa4deb5b75ae9459a4090ea7c8ce26293f62251f105523936c764",
          x86_64_linux: "3a183888e684e54f3550f58d72aeb0d2d53daaab13fcc5f527c080803166ea00"

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
