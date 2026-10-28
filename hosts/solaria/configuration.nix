{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
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

  systemd = {
    tmpfiles.settings."10-srv" = {
      "/srv".d = {
        mode = "0755";
        user = "root";
        group = "root";
      };

      "/srv/data".d = {
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
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    users = {
      psoder = {
        isNormalUser = true;
        group = "psoder";
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
        shell = pkgs.fish;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2fu6PtQ/hFVb+ik45DPlBL6MBXjXLv/R6Dpbiv4F1s pontus@yavin-2026"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2/tUwBk2rlPtlldBEF6ZVTDwD8NHhlRn1iy9PGsXF7 pontus@trantor-2025"
        ];
      };

      jellyfin = {
        isSystemUser = true;
        linger = true;
        group = "jellyfin";
        extraGroups = [ "media" ];
      };

      qbittorrent = {
        isSystemUser = true;
        linger = true;
        group = "qbittorrent";
        extraGroups = [ "media" ];
      };
    };

    groups = {
      psoder = { };
      media = { };
      jellyfin = { };
      qbittorrent = { };
    };

  };

  programs = {
    nixvim = {
      enable = true;
      colorschemes.catppuccin.enable = true;
      plugins.lualine.enable = true;

      opts = {
        number = true;
        relativenumber = true;
      };

      lsp = {
        servers = {
          nixd.enable = true;
        };
      };

      plugins = {
        lsp-format.enable = true;
      };
    };

    fish = {
      enable = true;
      shellAliases = {
        ls = "eza";
        cat = "bat";
        gs = "git status";
      };
      loginShellInit = ''
        function fish_greeting
          fastfetch
        end
      '';
      interactiveShellInit = ''
        zoxide init fish --cmd cd | source

        function fish_user_key_bindings
          fish_default_key_bindings -M insert
          fish_vi_key_bindings --no-erase insert
        end
      '';
    };

    neovim.defaultEditor = true;

    git = {
      enable = true;
      config = {
        core = {
          editor = "nvim";
          pager = "delta";
        };
        init.defaultBranch = "main";

        user = {
          name = "Pontus Söderlund";
          email = "52171526+psoder@users.noreply.github.com";
        };

        alias = {
          lg = "log --oneline --graph --abbrev-commit --date=relative";
          df = "diff";
          dfs = "diff --stat";
        };
      };
    };

    atuin = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      settings = {
        filter_mode = "directory";
        ctrl_n_shortcuts = true;
        keymap_mode = "vim-insert";
      };
    };
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    nixfmt
    nixfmt-tree
    sops
    age
    yazi
    zellij
    bottom
    fd
    ripgrep
    dust
    delta
    eza
    bat
    fzf
    zoxide
    fastfetch
    hdparm
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops/age/keys.txt";
    secrets = {
      #   "cloudflared/cert" = { };
      #   "cloudflare/tunnels/arrakis/credentials" = { };
      #   "cloudflare/zones/psoder.net/zone_id" = { };
      "cloudflare/zones/psoder.net/dns/api_token" = { };
      #   "radicale-users" = {
      #     sopsFile = ../../secrets/radicale-users.enc;
      #     format = "binary";
      #     owner = "radicale";
      #     group = "radicale";
      #     mode = "0400";
      #   };
      # "restic/r2-env" = {
      #   sopsFile = ../../secrets/restic.yaml.enc;
      # };
      "restic/password" = {
        sopsFile = ../../secrets/restic.yaml.enc;
      };
      "samba/data-password" = { };
    };

    templates = {
      "caddy_env".content = ''
        CF_API_TOKEN=${config.sops.placeholder."cloudflare/zones/psoder.net/dns/api_token"}
      '';
    };
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
  services = {
    openssh.enable = true;

    caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/caddy-dns/cloudflare@v0.2.4"
        ];
        hash = "sha256-dQvk6ezY6TQ1J7PjhCXnThF/SqVgPwBO8/RXzHCY+js=";
      };
      environmentFile = config.sops.templates."caddy_env".path;
      virtualHosts = {
        "apollo.psoder.net".extraConfig = ''
          tls {
              dns cloudflare {env.CF_API_TOKEN}
          }

          reverse_proxy 127.0.0.1:8096
        '';

        "torrent.psoder.net".extraConfig = ''
          tls {
              dns cloudflare {env.CF_API_TOKEN}
          }

          reverse_proxy 127.0.0.1:8070
        '';
      };
    };

    tailscale = {
      enable = true;
    };

    jellyfin.enable = true;

    qbittorrent = {
      enable = true;
      webuiPort = 8070;
      serverConfig = {
        LegalNotice.Accepted = true;
        Preferences = {
          WebUI = {
            Enabled = true;
            LocalHostAuth = false;
          };
        };
      };
    };

    samba = {
      enable = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "nixos-server";
          "security" = "user";
          "server min protocol" = "SMB2";
          "map to guest" = "never";
        };

        data = {
          path = "/srv/data";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = "psoder";
          "force user" = "psoder";
        };

        media = {
          path = "/srv/media";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = "psoder";
          "force user" = "psoder";
        };
      };
    };

    restic = {
      backups.data-files = {
        initialize = true;
        paths = [ "/srv/data/files" ];

        repository = "/mnt/hdd0/backups/restic/data-files";
        passwordFile = config.sops.secrets."restic/password".path;

        timerConfig = {
          OnCalendar = "*-*-* 00,06,12,18:00:00";
          Persistent = true;
        };

        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 12"
          "--keep-yearly 3"
        ];
      };
    };

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

  system.activationScripts.sambaPassword.text = ''
    password=$(${pkgs.coreutils}/bin/cat /run/secrets/samba/data-password)

    printf '%s\n%s\n' "$password" "$password" \
      | ${lib.getExe' pkgs.samba "smbpasswd"} -a -s psoder
  '';

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?
}
