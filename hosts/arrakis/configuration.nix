# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
#nixos and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  boot.kernelParams = [ "consoleblank=60" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "arrakis"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.autoUpgrade = {
    enable = true;
    flake = "github:psoder/nixos/main#arrakis";
    flags = [ "--print-build-logs" ];
    dates = "04:00";
    randomizedDelaySec = "45min";
    persistent = true;
    allowReboot = true;
    rebootWindow = {
      lower = "04:00";
      upper = "06:00";
    };
  };

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "sv-latin1";

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=2G
    MaxRetentionSec=1month
    Compress=yes
  '';

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.psoder = {
    isNormalUser = true;
    description = "Pontus";
    group = "psoder";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2fu6PtQ/hFVb+ik45DPlBL6MBXjXLv/R6Dpbiv4F1s pontus@yavin-2026"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2/tUwBk2rlPtlldBEF6ZVTDwD8NHhlRn1iy9PGsXF7 pontus@trantor-2025"
    ];

    packages = with pkgs; [
      nixfmt-rfc-style
    ];
  };

  users.users.deploy = {
    isNormalUser = true;
    description = "Deploy user for running apps";
    shell = pkgs.fish;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIiVhGSdGsZlWkhRsmNk/RIXuAdHSzFKRGOLlhrdsAZY deploy@arrakis"
    ];
  };

  users = {
    users.ddns-updater = {
      isSystemUser = true;
      linger = true;
      group = "ddns-updater";
    };

    users.jellyfin = {
      isSystemUser = true;
      linger = true;
      group = "jellyfin";
      extraGroups = [ "media" ];
    };

    groups.ddns-updater = { };
    groups.psoder = { };
    groups.media = { };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs = {
    fish.enable = true;

    neovim = {
      enable = true;
      defaultEditor = true;
    };
  };

  virtualisation.docker = {
    enable = true;
    # rootless = {
    #   enable = true;
    #   setSocketVariable = true;
    # };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    sops
    age
    cloudflared
    ddns-updater
    yazi
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops/age/keys.txt";
    secrets = {
      "cloudflared/cert" = { };
      "cloudflare/tunnels/arrakis/credentials" = { };
      "cloudflare/zones/psoder.net/zone_id" = { };
      "cloudflare/zones/psoder.net/dns/api_token" = { };
    };

    templates."ddns-updater.config.json".content = builtins.toJSON {
      settings = [
        {
          provider = "cloudflare";
          zone_identifier = config.sops.placeholder."cloudflare/zones/psoder.net/zone_id";
          domain = "arete.psoder.net";
          ttl = 600;
          token = config.sops.placeholder."cloudflare/zones/psoder.net/dns/api_token";
          ip_version = "ipv4";
          ipv6_suffix = "";
        }
      ];
    };
    templates."ddns-updater.config.json".owner = "ddns-updater";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  systemd.tmpfiles.settings."10-srv" = {
    "/srv".d = {
      mode = "0755";
      user = "root";
      group = "root";
    };

    "/srv/files".d = {
      mode = "0755";
      user = "psoder";
      group = "psoder";
    };

    "/srv/media".d = {
      mode = "0775";
      user = "psoder";
      group = "media";
    };
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "b89658cb-d969-411a-8560-9531eceec6f0" = {
        credentialsFile = config.sops.secrets."cloudflare/tunnels/arrakis/credentials".path;
        default = "http_status:404";
        ingress = {
          "arrakis-ssh.psoder.net" = "ssh://localhost:22";
          "arete-api.psoder.net" = "http://localhost:8080";
        };
      };
    };
  };

  systemd.services = {
    ddns-updater = {
      enable = true;
      description = "ddns-updater service";

      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        TimeoutSec = "5min";
        ExecStart = ''
          ${pkgs.ddns-updater}/bin/ddns-updater \
          --LISTENING_ADDRESS=':6000' \
          --CONFIG_FILEPATH=${config.sops.templates."ddns-updater.config.json".path}
        '';
        RestartSec = 30;
        User = "ddns-updater";
        Group = "ddns-updater";
        StateDirectory = "ddns-updater";
        Restart = "on-failure";

        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";

        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;

        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];

        ReadOnlyPaths = [
          config.sops.templates."ddns-updater.config.json".path
        ];
        UMask = "0077";
      };
    };
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

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
  system.stateVersion = "25.11"; # Did you read the comment?

}
