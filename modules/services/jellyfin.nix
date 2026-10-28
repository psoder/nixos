{ ... }:

{
  users.users.jellyfin = {
    isSystemUser = true;
    linger = true;
    group = "jellyfin";
    extraGroups = [ "media" ];
  };

  users.groups.jellyfin = { };

  services.jellyfin.enable = true;

  services.caddy.virtualHosts."apollo.psoder.net" = {
    extraConfig = ''
      tls {
          dns cloudflare {env.CF_API_TOKEN}
      }

      reverse_proxy 127.0.0.1:8096
    '';
  };
}
