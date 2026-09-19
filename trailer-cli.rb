# typed: true
# frozen_string_literal: true

# Formula for trailer-cli via Homebrew
class TrailerCli < Formula
  desc "Managing Pull Requests & Issues For GitHub & GH Enterprise from the command-line"
  homepage "https://github.com/ptsochantaris/trailer-cli"
  url "https://github.com/ptsochantaris/trailer-cli/archive/refs/tags/1.7.0.tar.gz"
  sha256 "0e475a3e6bd9cb452fc4f9af60a0d51f69848afadf8e4fca3eb0b5e0a1cf95d7"
  license "MIT"
  depends_on xcode: "27.0"

  def install
    args = ["--disable-sandbox",
            "-c", "release",
            "-Xswiftc", "-Ounchecked",
            "-Xswiftc", "-enforce-exclusivity=unchecked"]

    system "swift", "build", *args

    # SwiftPM has moved its output directory between releases, so ask it where the
    # binary landed instead of hardcoding the path.
    bin_path = Utils.safe_popen_read("swift", "build", *args, "--show-bin-path").strip
    bin.install "#{bin_path}/trailer"
  end

  test do
    assert_match "Usage: trailer", shell_output("#{bin}/trailer", 1)
  end
end
