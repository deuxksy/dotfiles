{ config, ... }:
{
  sops.age.keyFile = "/home/crong/.config/sops/age/keys.txt";

  sops.secrets."hermes-env" = {
    format = "yaml";
    sopsFile = ../../secrets/hermes.yaml;
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    environment = {
      GATEWAY_ALLOW_ALL_USERS = "true";
    };
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    extraDependencyGroups = [ "messaging" ];
    settings = {
      model = {
        default = "glm-5.1";
        base_url = "http://ai/v1";
      };
      terminal = {
        backend = "local";
        timeout = 180;
      };
    };
  };
}
