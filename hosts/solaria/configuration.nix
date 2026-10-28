{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
    ../../modules/backups.nix
    ../../modules/services/caddy.nix
    ../../modules/services/jellyfin.nix
    ../../modules/services/qbittorrent.nix
    ../../modules/services/samba.nix
    ../../modules/services/xandikos.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "solaria";
  networking.networkmanager.enable = true;

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=2G
    MaxRetentionSec=1month
    Compress=yes
  '';

  users = {
    users.psoder = {
      isNormalUser = true;
      group = "psoder";
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2fu6PtQ/hFVb+ik45DPlBL6MBXjXLv/R6Dpbiv4F1s pontus@yavin-2026"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2/tUwBk2rlPtlldBEF6ZVTDwD8NHhlRn1iy9PGsXF7 pontus@trantor-2025"
      ];
    };

    groups.psoder = {
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops/age/keys.txt";
    secrets = {
      #   "cloudflared/cert" = { };
      #   "cloudflare/tunnels/arrakis/credentials" = { };
      #   "cloudflare/zones/psoder.net/zone_id" = { };
      #   "radicale-users" = {
      #     sopsFile = ../../secrets/radicale-users.enc;
      #     format = "binary";
      #     owner = "radicale";
      #     group = "radicale";
      #     mode = "0400";
      #   };
    };
  };

  services = {
    openssh.enable = true;
    tailscale.enable = true;
    udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ATTRS{serial}=="WFL1EC8L", RUN+="${pkgs.hdparm}/bin/hdparm -S 240 /dev/%k"
    '';
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    443
  ];

  system.stateVersion = "26.05";
}
