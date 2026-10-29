{ config, ... }:

{
  sops = {
    secrets = {
      "authelia/jwt_secret" = {
        owner = "authelia";
      };
      "authelia/encryption_key" = {
        owner = "authelia";
      };
      "authelia/users/psoder/email" = {
        owner = "authelia";
      };
      "authelia/users/psoder/password" = {
        owner = "authelia";
      };
    };

    templates."authelia_users" = {
      owner = "authelia";
      content = ''
        users:
          psoder:
            displayname: "Pontus"
            email: ${config.sops.placeholder."authelia/users/psoder/email"}
            password: ${config.sops.placeholder."authelia/users/psoder/password"}
            groups: ["admins"]
      '';
    };
  };

  users = {
    users.authelia = {
      isSystemUser = true;
      linger = true;
      group = "authelia";
    };

    groups.authelia = { };
  };

  services.authelia.instances.main = {
    enable = true;
    user = "authelia";

    secrets = {
      jwtSecretFile = config.sops.secrets."authelia/jwt_secret".path;
      storageEncryptionKeyFile = config.sops.secrets."authelia/encryption_key".path;
    };

    settings = {
      log.level = "info";
      server.address = "tcp://:9091/";

      session = {
        cookies = [
          {
            domain = "psoder.net";
            authelia_url = "https://auth.psoder.net";
          }
        ];
      };

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "auth.psoder.net";
            policy = "bypass";
          }
          {
            domain = "*.psoder.net";
            policy = "one_factor";
          }
        ];
      };

      storage.local.path = "/var/lib/authelia-main/db.sqlite";
      notifier.filesystem.filename = "/var/lib/authelia-main/notifications.yml";
      authentication_backend.file.path = config.sops.templates."authelia_users".path;
    };
  };

  services.caddy.virtualHosts."auth.psoder.net" = {
    extraConfig = ''
      tls {
          dns cloudflare {env.CF_API_TOKEN}
      }

      reverse_proxy 127.0.0.1:9091
    '';
  };
}
