{ lib, pkgs, ... }:

{
  services.samba = {
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

  sops.secrets."samba/data-password" = { };

  system.activationScripts.sambaPassword.text = ''
    password=$(${pkgs.coreutils}/bin/cat /run/secrets/samba/data-password)

    printf '%s\n%s\n' "$password" "$password" \
      | ${lib.getExe' pkgs.samba "smbpasswd"} -a -s psoder
  '';
}
