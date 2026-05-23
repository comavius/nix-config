/*
Copyright (c) 2003-2026 Eelco Dolstra and the Nixpkgs/NixOS contributors

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
# https://github.com/NixOS/nixpkgs/blob/9b5a2912f5327110b400074ed68bbdf737b85852/pkgs/by-name/we/weylus/package.nix
{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  dbus,
  ffmpeg,
  x264,
  libva,
  gst_all_1,
  libxv,
  libxtst,
  libxrender,
  libxrandr,
  libxi,
  libxinerama,
  libxft,
  libxfixes,
  libxext,
  libxcursor,
  libxcomposite,
  libdrm,
  pkg-config,
  pango,
  pipewire,
  cmake,
  git,
  autoconf,
  libtool,
  typescript,
  wayland,
  libxkbcommon,
}:

rustPlatform.buildRustPackage {
  pname = "weylus";
  version = "unstable-2026-03-27";

  src = fetchFromGitHub {
    owner = "H-M-H";
    repo = "weylus";
    rev = "38a01a8f8e429500c7e9f67fc1c88ca37a4d1e93";
    hash = "sha256-kcFXwrxg9PQxR4/71s10TMtaFvksuQaNReSoGBbrdM0=";
  };

  buildInputs = [
    ffmpeg
    x264
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    dbus
    libva
    gst_all_1.gst-plugins-base
    libxext
    libxft
    libxinerama
    libxcursor
    libxrender
    libxfixes
    libxtst
    libxrandr
    libxcomposite
    libxi
    libxv
    pango
    libdrm
    wayland
    libxkbcommon
  ];

  nativeBuildInputs = [
    cmake
    git
    typescript
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    pkg-config
    autoconf
    libtool
  ];

  cargoHash = "sha256-2K+zLgZ3ApTCpj/OYy0f80pkvXPaB6TJe4fcrqsxPPw=";

  cargoBuildFlags = [ "--features=ffmpeg-system" ];
  cargoTestFlags = [ "--features=ffmpeg-system" ];

  postFixup =
    let
      GST_PLUGIN_PATH = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
        gst_all_1.gst-plugins-base
        pipewire
      ];
    in
    lib.optionalString stdenv.hostPlatform.isLinux ''
      wrapProgram $out/bin/weylus --prefix GST_PLUGIN_PATH : ${GST_PLUGIN_PATH}
    '';

  postInstall = ''
    install -vDm755 weylus.desktop $out/share/applications/weylus.desktop
  '';

  env = {
    NIX_CFLAGS_COMPILE = toString [
      "-Wno-incompatible-pointer-types"
    ];
  };

  meta = {
    description = "Use your tablet as graphic tablet/touch screen on your computer";
    mainProgram = "weylus";
    homepage = "https://github.com/H-M-H/Weylus";
    license = with lib.licenses; [ agpl3Only ];
    maintainers = [ ];
  };
}