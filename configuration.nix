# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
    ];
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # For Hyprland to enable Cachix for git builds
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  nix.optimise ={
    automatic = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than +5";
  };
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # For Wireguard routing
  networking.firewall.checkReversePath = false;
  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
        intel-media-driver
        vaapiVdpau
        nvidia-vaapi-driver
    ];
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.displayManager.sddm.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = true;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
      #reverseSync.enable = true;
	#allowExternalGpu = false;
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # sync = {
      #   enable = true;
      # };
    };
  };
  # For DDC backlight control
  hardware.i2c.enable = true;
  # For virtual camera
  boot.kernelModules = ["v4l2loopback"];
  boot.extraModulePackages = [ pkgs.linuxPackages.v4l2loopback ];
  # services.udev.extraRules = ''
  #   KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  # '';
  # Hack to fix issue with the driver and kernel when extra ghost monitor is shown
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
  boot.kernel.sysctl = { 
    "net.ipv4.ip_unprivileged_port_start" = true;
  };
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;
 services.avahi = {
  enable = true;
  nssmdns = true;
  openFirewall = true;
 };

   services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
    extraConfig = ''
      HandleLidSwitch=ignore
      IdleAction=ignore
      HandleSuspendKey=ignore
    '';
  };

  # Enable sound with pipewire.
  # hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  services.transmission = {
    enable = true;
    openFirewall = true;
    openRPCPort = true;
    settings = {
      download-dir = "/media/media/films";
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.den = {
    shell = pkgs.fish;
    useDefaultShell = true;
    isNormalUser = true;
    description = "Den Engineer";
    extraGroups = [ "networkmanager" "wheel" "video"];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };
  
  programs.hyprland = {
    # Install the packages from nixpkgs
    enable = true;
    # Whether to enable XWayland
    xwayland.enable = true;
    #package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    #portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game   Transfers
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

fonts.packages = with pkgs; [
  (nerdfonts.override { fonts = [ "Hack" ]; })
];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    telegram-desktop
    lxqt.lxqt-policykit
    btop
    rofi-wayland
    wl-clipboard
    cliphist
    wl-clip-persist
    libnotify
    google-chrome
    vscode
    zed-editor
    jetbrains.webstorm
    git
    nodejs_22
    bun
    bruno
    dbgate
    mpv
    playerctl
    brightnessctl
    ddcutil
    pwvucontrol
    easyeffects
    v4l-utils 
    ffmpeg
    jq
    hurl
    rye
    # Sreeshots stuff
    grim
    slurp
    swappy
    obsidian
    logseq

    onlyoffice-bin
    krita
    renoise
    reaper
    wineWowPackages.wayland
    winetricks
    yabridge
    yabridgectl
  ];

programs.fish = {
  enable = true;
  interactiveShellInit = ''
      bind \b 'backward-kill-word'
      stty intr \^q
  '';
};
programs.nix-ld.enable = true;
programs.nix-ld.libraries = with pkgs; [];
home-manager = {
  # also pass inputs to home-manager modules
  extraSpecialArgs = {inherit inputs;};
  users = {
    "den" = import ./home.nix;
  };
};

services.yubikey-agent.enable = true;

services.greetd = {
  enable = true;
  settings = rec {
    initial_session = {
      command = "Hyprland";
      user = "den";
    };
    default_session = initial_session;
  };
};

# Kills stuff if too much ram was consumed
services.earlyoom = {
  enable=true;
  freeMemThreshold = 3;
  extraArgs = [
    "-g" "--avoid '^(.Hyprland-wrapp|Xwayland)$'"
    "--prefer '^(electron|chrome)$'"
  ];
};

security.polkit.enable = true; 
security.pam.services.hyprlock = {};

fileSystems."/media" = { 
  device = "/dev/disk/by-uuid/56EC102CEC1008BF";
  fsType = "ntfs3";
  options = [ "nofail" "umask=000" ];
};
# lxqt.lxqt-policykit;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
