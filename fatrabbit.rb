# typed: true
# frozen_string_literal: true

# Formula for fatrabbit via Homebrew
class Fatrabbit < Formula
  desc "Defragment a FAT12, FAT16 or FAT32 volume in place"
  homepage "https://github.com/ptsochantaris/fatrabbit"
  url "https://github.com/ptsochantaris/fatrabbit/archive/refs/tags/1.0.3.tar.gz"
  sha256 "ef4e31ebe734cb940387cc798f3faf1461d8da150f892e6e131f82df3503a108"
  license "MIT"
  head "https://github.com/ptsochantaris/fatrabbit.git", branch: "main"

  # The package manifest's floor is macOS 26.3, and it is not cosmetic: the code is built on Span,
  # whose stdlib arrives with the OS. Homebrew only knows major versions, so :tahoe is as close as
  # this can say — between 26.0 and 26.3 SwiftPM refuses the manifest itself, which says so clearly.
  depends_on macos: :tahoe
  depends_on xcode: "26.0"

  def install
    # Exactly what `make release` runs, which is the build the project ships. The LTO flag is the
    # entire reason that Makefile exists — it cannot be expressed in a package manifest — so leaving
    # it out here would quietly install a different binary from the documented one. Expect a wall of
    # -Woverride-module warnings from the link: they are the dependency's lower macOS floor meeting
    # ours, one per bitcode module, and are noise.
    system "swift", "build",
           "--disable-sandbox",
           "-c", "release",
           "--experimental-lto-mode=full"

    bin.install ".build/release/fatrabbit"
  end

  def caveats
    <<~EOS
      fatrabbit writes to the raw device, so a real run needs root, and the volume has to be
      unmounted while staying attached:

        diskutil unmount /dev/disk4s1
        sudo fatrabbit /dev/disk4s1

      A mounted volume is refused outright, dry run or not. Run it with no volume named and every
      attached FAT volume is listed for you to pick from. An image file needs no privileges at all.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/fatrabbit --version")

    # A dry run on an image file opens it read-only and asks for no privileges at all, so the whole
    # open, scan, plan and relocate path can run right here. What it needs is a FAT volume, and
    # newfs_msdos cannot make one in a file — it asks the device for a partition offset and gives up
    # — so the volume is written by hand below: a 2 MB FAT16 holding one three-cluster file
    # deliberately scattered across clusters 2, 5 and 9, which is something for the planner to do
    # rather than an empty volume it can answer without thinking.
    sector = 512
    fat_sectors = 17
    root_sectors = 32
    clusters = 4200
    total = 1 + (2 * fat_sectors) + root_sectors + clusters

    jump = [0xEB, 0x3C, 0x90].pack("C3")

    boot = ("\x00" * sector).b
    boot[0, 11] = "#{jump}FATRABIT"
    boot[11, 2] = [sector].pack("v") # bytes/sector
    boot[13] = [1].pack("C") # sectors/cluster
    boot[14, 2] = [1].pack("v") # reserved sectors
    boot[16] = [2].pack("C") # number of FATs
    boot[17, 2] = [root_sectors * sector / 32].pack("v") # root entries
    boot[19, 2] = [total].pack("v") # total sectors
    boot[21] = [0xF8].pack("C") # media descriptor
    boot[22, 2] = [fat_sectors].pack("v") # sectors/FAT
    boot[36] = [0x80].pack("C") # drive number
    boot[38] = [0x29].pack("C") # extended boot signature
    boot[39, 4] = [0x12345678].pack("V") # volume ID
    boot[43, 11] = "BREWTEST   "
    boot[54, 8] = "FAT16   "
    boot[510, 2] = [0x55, 0xAA].pack("C2")

    # 4,200 data clusters puts this above FAT16's 4,085 floor, so the variant follows from the
    # geometry exactly as it does on a real volume — nothing here declares it but the label.
    entries = Array.new(clusters + 2, 0)
    entries[0] = 0xFFF8
    entries[1] = 0xFFFF
    entries[2] = 5 # the fragmented chain: 2 -> 5 -> 9 -> end
    entries[5] = 9
    entries[9] = 0xFFFF
    fat = entries.pack("v*").ljust(fat_sectors * sector, "\x00")

    archive = [0x20].pack("C")
    root = "TEST    TXT#{archive}".b.ljust(32, "\x00")
    root[26, 2] = [2].pack("v") # first cluster
    root[28, 4] = [3 * sector].pack("V") # size in bytes
    root = root.ljust(root_sectors * sector, "\x00")

    File.binwrite("test.img", boot + fat + fat + root + ("\x00" * (clusters * sector)))

    # The transcript goes to stderr, so it has to be redirected to be seen here.
    output = shell_output("#{bin}/fatrabbit --plain --dry-run test.img 2>&1")
    assert_match "FAT16", output
    assert_match "Found 1 file", output
    assert_match "0 objects still fragmented", output
  end
end
