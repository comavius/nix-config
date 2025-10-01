{pkgs, ...}: {
  fonts = {
    fonts = with pkgs; [
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
      migu
      nerdfonts
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
          "JetBrainsMono Nerd Font"
          "Noto Emoji"
        ];
        emoji = ["Noto Emoji"];
      };
    };
  };
}
