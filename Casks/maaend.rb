# Documentation: https://docs.brew.sh/Cask-Cookbook
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
cask "maaend" do

  name "MaaEnd"
  homepage "https://github.com/MaaEnd/MaaEnd"

  # Documentation: https://docs.brew.sh/Brew-Livecheck
  livecheck do
    url :homepage
    strategy :github_latest
  end
  
  arch arm: "aarch64", intel: "x86_64"
  on_arch_conditional arm: "aarch64", intel: "x86_64"

  version "2.23.0"
  

  on_macos do
    sha256 arm:   "9375446c52c2ba6c7cb0b2bdefa26041895d831638197a5f1a0367a7e1bcc117",
           intel: "6c2deffed531eb7e48f7c3bfd06ad792611fdf39445e379c4a51930c02ac73ab"
    url "https://github.com/MaaEnd/MaaEnd/releases/download/v#{version}/MaaEnd-macos-#{arch}-v#{version}.dmg"

    depends_on macos: :catalina

    app "MaaEnd.app"

    # Documentation: https://docs.brew.sh/Cask-Cookbook#stanza-zap
    zap rmdir: [
      "~/Library/Caches/com.maaend.app",
      "~/Library/WebKit/com.maaend.app",
    ]

    uninstall quit: "com.maaend.app"
  end
  on_linux do
    sha256 arm:   "9a1b7f3d60fd261189952b4ad400dfa47ab7fb96d6c9c9a82fde973072dfabc2",
           intel: "2c5e1e38668cff96204fc64f699646573db0643752da9a99dcf1e1612f3abb65"

    url "https://github.com/MaaEnd/MaaEnd/releases/download/v#{version}/MaaEnd-linux-#{arch}-v#{version}.tar.gz"

    depends_on arch: :intel

    binary "MaaEnd"
  end

  language "zh", "CN" do
    desc "终末地小助手：基于视觉 AI 的「明日方舟：终末地」自动化工具"
    "zh_CN"
    on_macos do 
      caveats do
        <<~EOS
          安装完成！
          如果 macOS 因「此应用已经损坏」而拒绝启动，请执行以下命令：
            sudo xattr -cr /Applications/MaaEnd.app
        EOS
      end
    end
  end
  language "en", default: true do
    desc "An Arknights:Endfield automation helper based on vision AI."
    "en_US"
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
  end

end
