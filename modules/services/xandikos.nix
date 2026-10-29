{ ... }:

{
  users = {
    users.xandikos = {
      isSystemUser = true;
      linger = true;
      group = "xandikos";
    };

    groups.xandikos = { };
  };

  services.xandikos = {
    enable = true;
    port = 8008;
    address = "127.0.0.1";
    extraOptions = [
      "--autocreate"
      "--current-user-principal /psoder"
      "--dump-dav-xml"
      "--directory /var/lib/xandikos"
    ];
  };

  services.caddy.virtualHosts."dav.psoder.net" = {
    extraConfig = ''
      tls {
          dns cloudflare {env.CF_API_TOKEN}
      }

      forward_auth 127.0.0.1:9091 {
      	uri /api/authz/forward-auth
      	copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      }

      reverse_proxy 127.0.0.1:8008
    '';
  };
}
