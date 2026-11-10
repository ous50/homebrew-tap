cask "micago" do
  os macos: "Mac", linux: "Linux"

  version "0.94.0"
  sha256 arm:          "12fc068434695eb575ac9f33055eb993923eb0e11dab1173df47bb64687e2cce",
         intel:        "12fc068434695eb575ac9f33055eb993923eb0e11dab1173df47bb64687e2cce",
         x86_64_linux: "4e1b0b339c392887536484d4af88fa441e06f151af3f154889c9270280caf0a1"

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
