{ config, pkgs, ... }:

{
  sops = {
    secrets."cloudflare/zones/psoder.net/dns/api_token" = { };

    templates = {
      "caddy_env".content = ''
        CF_API_TOKEN=${config.sops.placeholder."cloudflare/zones/psoder.net/dns/api_token"}
      '';
    };
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.4"
      ];
      hash = "sha256-dQvk6ezY6TQ1J7PjhCXnThF/SqVgPwBO8/RXzHCY+js=";
    };
    environmentFile = config.sops.templates."caddy_env".path;
  };
}
