{ config, ... }:

{
  sops.secrets."restic/password" = {
    sopsFile = ../secrets/restic.yaml.enc;
  };

  services.restic = {
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
}
