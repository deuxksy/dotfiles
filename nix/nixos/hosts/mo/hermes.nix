{ config, ... }:
{
  sops.secrets."hermes-env" = {
    format = "yaml";
    sopsFile = ../../secrets/hermes.yaml;
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
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
