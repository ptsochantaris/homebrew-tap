# typed: true
# frozen_string_literal: true

# Formula for trailer-cli via Homebrew
class TrailerCli < Formula
  desc "Managing Pull Requests & Issues For GitHub & GH Enterprise from the command-line"
  homepage "https://github.com/ptsochantaris/trailer-cli"
  url "https://github.com/ptsochantaris/trailer-cli/archive/refs/tags/1.4.0.tar.gz"
  sha256 "8936949f0d6d0d9e5e1ec7e300e2b384ab878b9ee76288bfc0a5e9791d0e391f"
  license "MIT"
  depends_on xcode: "14.2"

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
