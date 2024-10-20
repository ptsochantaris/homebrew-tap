# typed: true
# frozen_string_literal: true

# Formula for trailer-cli via Homebrew
class TrailerCli < Formula
  desc "Managing Pull Requests & Issues For GitHub & GH Enterprise from the command-line"
  homepage "https://github.com/ptsochantaris/trailer-cli"
  url "https://github.com/ptsochantaris/trailer-cli/archive/refs/tags/1.6.0.tar.gz"
  sha256 "e1b6e318cf365cbc6dd71aaface1d21f0ad1a9bc62ef8a4c9c8608136fefe1b1"
  license "MIT"
  depends_on xcode: "16.0"

  def install
    args = "swift", "build",
           "--disable-sandbox",
           "-c", "release",
           "--arch", "arm64",
           "--arch", "x86_64",
           "-Xswiftc", "-O",
           "-Xswiftc", "-Ounchecked",
           "-Xswiftc", "-whole-module-optimization",
           "-Xswiftc", "-enforce-exclusivity=unchecked"

    system(*args)

    bin.install buildpath/".build/apple/Products/Release/trailer"
  end

  test do
    system "false"
  end
end
