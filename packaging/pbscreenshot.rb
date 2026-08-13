cask "pbscreenshot" do
  version "@VERSION@"
  sha256 "@SHA256@"

  url "https://github.com/olshansk/pbscreenshot/releases/download/v#{version}/pbscreenshot-#{version}.dmg"
  name "pbscreenshot"
  desc "Capture a screenshot and put it on the clipboard as a file reference"
  homepage "https://github.com/olshansk/pbscreenshot"

  depends_on macos: ">= :ventura"

  app "pbscreenshot.app"
  binary "#{appdir}/pbscreenshot.app/Contents/MacOS/pbscreenshot"

  zap trash: [
    "~/Library/Preferences/com.olshansky.pbscreenshot.plist",
    "~/Library/HTTPStorages/com.olshansky.pbscreenshot",
  ]
end
