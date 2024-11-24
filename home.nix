
{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.ags.homeManagerModules.default ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "den";
  home.homeDirectory = "/home/den";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/denengineer/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

programs.fzf = {
enable = true;
enableFishIntegration = true;
};

programs.foot = {
  enable = true;
	settings ={
main= {
 font= "Hack:size=13";
};

  colors = {
#    term = "xterm-256color";

 #   font = "Fira Code:size=11";
  #  dpi-aware = "yes";
foreground="4c4f69";
background="eff1f5";
regular0="5c5f77";
regular1="d20f39";
regular2="40a02b";
regular3="df8e1d";
regular4="1e66f5";
regular5="ea76cb";
regular6="179299";
regular7="acb0be";
bright0="6c6f85";
bright1="d20f39";
bright2="40a02b";
bright3="df8e1d";
bright4="1e66f5";
bright5="ea76cb";
bright6="179299";
bright7="bcc0cc";
selection-foreground="4c4f69";
selection-background="ccced7";
search-box-no-match="dce0e8 d20f39";
search-box-match="4c4f69 ccd0da";
jump-labels="dce0e8 fe640b";
urls="1e66f5";
  };

#  mouse = {
   # hide-when-typing = "yes";
  #};
};
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

programs.hyprlock = {
enable=true;
settings={
general = {
immediate_render= true;
no_fade_in=true;
no_fade_out=true;
hide_cursor=true;
      };
 background = [
    {
      color = "black";
      blur_passes = 0;
     }
  ];
   input-field = [
        {
          size = "250, 60";
          fade_on_empty=false;
          outer_color = "black";
          inner_color = "white";
          font_color = "black";
          placeholder_text = "";
        }
      ];
label = [
        {
          text = "🧬🧪";
          color = "white";
          font_size = 64;
          text_align = "center";
          halign = "center";
          valign = "center";
          position = "0, 160";
        }
        {
          text = "$TIME";
          color = "white";
          font_size = 32;
          text_align = "center";
          halign = "center";
          valign = "center";
          position = "0, 75";
        }
      ];
};
};

nixpkgs.overlays = [
  (self: super: {
      bitwig-studio = super.bitwig-studio.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          cp /home/den/Downloads/Bitwig.Studio.v5.2.0-FLARE/macOS/FLARE/bitwig.jar $out/libexec/bin/bitwig.jar;
          cp /home/den/Downloads/Bitwig.Studio.v5.2.0-FLARE/macOS/FLARE/activation.bwreg  $out/libexec/bin/activation.bwreg;
        '';
      });
  })
];

  programs.ags = {
    enable = true;

    # null or path, leave as null if you don't want hm to manage the config
#    configDir = ../ags;

    # additional packages to add to gjs's runtime
    extraPackages = with pkgs; [
      gtksourceview
      webkitgtk
      accountsservice
    ];
  };
}
