{ ... }:

{
  users = {
    users.qbittorrent = {
      isSystemUser = true;
      linger = true;
      group = "qbittorrent";
      extraGroups = [ "media" ];
    };

    groups.media = { };
    groups.qbittorrent = { };
  };

  services.qbittorrent = {
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

  services.caddy.virtualHosts."torrent.psoder.net" = {
    extraConfig = ''
      tls {
          dns cloudflare {env.CF_API_TOKEN}
      }

      reverse_proxy 127.0.0.1:8070
    '';
  };
}
