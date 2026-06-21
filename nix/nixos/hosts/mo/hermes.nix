{ config, ... }:
{
  users.users.hermes = {
    isSystemUser = true;
    group = "hermes";
    extraGroups = [ "wheel" ];
  };

  # hermes 서비스 실행 시에만 users 그룹 권한 부여
  systemd.services.hermes-agent.serviceConfig.SupplementaryGroups = [ "users" ];

  # /home/crong 그룹(users)에 읽기/실행 권한 보장
  systemd.tmpfiles.rules = [
    "d /home/crong 0750 crong users -"
  ];

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
    extraDependencyGroups = [ "messaging" "anthropic" "voice" ];
    settings = {
      model = {
        default = "glm-5-turbo";
        context_length = 200000;
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
      gateway = {
        cwd = "/home/crong/git/hermes";
      };
      voice = {
        record_key = "ctrl+b";
        max_recording_seconds = 120;
        auto_tts = false;
        beep_enabled = true;
        silence_threshold = 200;
        silence_duration = 3.0;
      };
      stt = {
        provider = "local";
        local = {
          model = "base";
        };
      };
      tts = {
        provider = "edge";
        edge = {
          voice = "en-US-AriaNeural";
        };
      };
      discord = {
        require_mention = true;
        auto_thread = true;
        reactions = true;
        history_backfill = true;
        history_backfill_limit = 50;
      };
    };
  };
}
