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
    extraDependencyGroups = [ "messaging" "anthropic" ];
    settings = {
      model = {
        default = "glm-5-turbo";
        provider = "custom:aperture";
      };
      custom_providers = [
        {
          name = "aperture";
          base_url = "http://ai";
          key_env = "ANTHROPIC_API_KEY";
          api_mode = "anthropic_messages";
        }
      ];
      terminal = {
        backend = "local";
        timeout = 180;
      };
    };
  };
}
