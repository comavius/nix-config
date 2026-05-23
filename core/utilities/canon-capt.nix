{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

let
  lib = pkgs.lib;

  rpath64 = lib.makeLibraryPath [
    pkgs.glibc
    pkgs.cups
    pkgs.libxml2
    pkgs.zlib
    pkgs.gtk2
    pkgs.glib
    pkgs.gdk-pixbuf
    pkgs.atk
    pkgs.popt
    pkgs.gnome2.libglade
  ];

  rpath32 = lib.makeLibraryPath [
    pkgs.pkgsi686Linux.glibc
    pkgs.pkgsi686Linux.libxml2
    pkgs.pkgsi686Linux.popt
  ];
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "canon-capt";
  version = "2.71";

  src = pkgs.fetchurl {
    url = "https://gdlp01.c-wss.com/gds/7/0100003447/08/linux-capt-drv-v271-jp.tar.gz";
    sha256 = "0gfaj2b3ylfw5jhafw7lpbs6si396nznhvzfcshmg2q1293gfhsz";
  };

  sourceRoot = "linux-capt-drv-v271-jp";

  nativeBuildInputs = [
    pkgs.file
    pkgs.patchelf
    pkgs.rpmextract
  ];

  installPhase = ''
    runHook preInstall

    srcDir=$PWD

    mkdir -p "$out"
    cd "$out"
    rpmextract "$srcDir/64-bit_Driver/RPM/cndrvcups-common-3.21-1.x86_64.rpm"
    rpmextract "$srcDir/64-bit_Driver/RPM/cndrvcups-capt-2.71-1.x86_64.rpm"

    mkdir -p "$out"/{bin,lib/cups,rpm,src,doc}
    for bin in "$out"/usr/bin/* "$out"/usr/sbin/* "$out"/usr/local/bin/*; do
      ln -sf "$bin" "$out/bin/$(basename "$bin")"
    done
    ln -sf "$out/usr/lib64/cups/backend" "$out/lib/cups/backend"
    ln -sf "$out/usr/lib64/cups/filter" "$out/lib/cups/filter"

    cd "$srcDir"
    cp -v 32-bit_Driver/RPM/*.rpm "$out/rpm/"
    cp -v 64-bit_Driver/RPM/*.rpm "$out/rpm/"
    cp -v Src/*.tar.gz "$out/src/"
    cp -v Doc/* "$out/doc/"

    while IFS= read -r elf; do
      if ! patchelf --print-needed "$elf" >/dev/null 2>&1; then
        continue
      fi

      if file -b "$elf" | grep -q "ELF 32-bit"; then
        patchelf --set-rpath "${rpath32}:$out/usr/lib" "$elf"
        if patchelf --print-interpreter "$elf" >/dev/null 2>&1; then
          patchelf --set-interpreter ${pkgs.pkgsi686Linux.glibc}/lib/ld-linux.so.2 "$elf"
        fi
      elif file -b "$elf" | grep -q "ELF 64-bit"; then
        patchelf --set-rpath "${rpath64}:$out/usr/lib64:$out/usr/local/lib64" "$elf"
        if patchelf --print-interpreter "$elf" >/dev/null 2>&1; then
          patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 "$elf"
        fi
      fi
    done < <(find "$out" -type f)

    runHook postInstall
  '';

  dontFixup = true;
  dontBuild = true;

  meta = {
    description = "Canon CAPT Linux driver extracted from Canon's linux-capt-drv-v271-jp RPMs";
    homepage = "https://canon.jp/support/software/os/select";
    license = lib.licenses.unfree;
    platforms = [ "i686-linux" "x86_64-linux" ];
  };
}
