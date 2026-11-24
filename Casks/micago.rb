cask "micago" do
  os macos: "Mac", linux: "Linux"

  version "0.96.0"
  sha256 arm:          "f1a4505d155a6d7ff855283bdc98916fb7d51e114122842d7731aae01bb102ac",
         intel:        "f1a4505d155a6d7ff855283bdc98916fb7d51e114122842d7731aae01bb102ac",
         x86_64_linux: "ded4802ad81e4f26b5fb8738590c40d7eb8e632e20a8b371a4f8bd1ff7ba12ab"

  on_macos do
    url "https://github.com/cinmou/micaGO/releases/download/v#{version}/micaGO-#{version}-#{os}.dmg"

    auto_updates true
    depends_on macos: :ventura

    app "micaGO Companion.app"

    uninstall quit: "com.micago.companion"

    zap trash: [
      "~/.micago",
      "~/Library/Preferences/com.micago.companion.plist",
    ]
  end
  on_linux do
    url "https://github.com/cinmou/micaGO/releases/download/v#{version}/micaGO-#{version}-#{os}.tar.gz"

    depends_on arch: :x86_64

    binary "micaGO/mica_go"
  end

  language "zh-Hant", "zh-TW" do
    desc "自託管的 iMessage 橋接工具"
    on_macos do
      caveats <<~EOS
        `brew uninstall` 會保留 ~/.micago 中的配對資料。
        如需一併刪除（之後需要重新配對）：
          brew uninstall --zap micago
      EOS
    end
    "zh_TW"
  end
  language "zh-HK", "zh-MO" do
    desc "自託管嘅 iMessage 橋接工具"
    on_macos do
      caveats <<~EOS
        `brew uninstall` 會保留 ~/.micago 入面嘅配對資料。
        如需一併刪除（之後需要重新配對）：
          brew uninstall --zap micago
      EOS
    end
    "zh_TW"
  end
  language "zh", "CN" do
    desc "自托管的 iMessage 桥接工具"
    on_macos do
      caveats <<~EOS
        `brew uninstall` 会保留 ~/.micago 中的配对数据。
        如需一并删除（之后需要重新配对）：
          brew uninstall --zap micago
      EOS
    end
    "zh_CN"
  end
  language "en", default: true do
    desc "Self-hosted iMessage bridge"
    on_macos do
      caveats <<~EOS
        `brew uninstall` keeps your pairing data in ~/.micago.
        To remove it as well (you will need to pair again):
          brew uninstall --zap micago
      EOS
    end
    "en_US"
  end

  name "micaGO"
  homepage "https://github.com/cinmou/micaGO"

  livecheck do
    url :url
    strategy :github_latest
  end
end
