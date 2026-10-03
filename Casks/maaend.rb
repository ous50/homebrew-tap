cask "maaend" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "macos", linux: "linux"
  downloaded_file_format = on_system_conditional macos: "dmg", linux: "tar.gz"

  version "2.31.0"
  sha256  arm:          "fda91db14065526af023a9a3e35a39f13a417176b13654f4a0d2f63063347ba4",
          intel:        "957c3ffcf87104ee53b5b1fe72c8f33b4df4049c87b553599cf3d10135638382",
          arm64_linux:  "1d01ba5156146aa19391e35c476da9856678d19e5497764e3565617d1e5ade37",
          x86_64_linux: "1058e8b9a95fcf01828ad91f6703f7c55c3cff272b798eade390197f16546ba9"

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
