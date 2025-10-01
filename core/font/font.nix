{pkgs, ...}: {
  fonts = {
    fonts = with pkgs; [
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
      migu
      noto-fonts
      noto-fonts-monochrome-emoji
    ];
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = {
        serif = [
          "Noto Serif CJK JP"
          "Noto Emoji"
        ];
        sansSerif = [
          "Noto Sans CJK JP"
          "Noto Emoji"
        ];
        monospace = [
          "Noto Sans Mono"
          "Noto Emoji"
        ];
        emoji = ["Noto Emoji"];
      };
    };
  };
}
