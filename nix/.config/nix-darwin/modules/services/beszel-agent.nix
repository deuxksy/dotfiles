{ pkgs, ... }: {
  # 해당 모듈에 필요한 패키지 격리
  environment.systemPackages = [ pkgs.beszel ];

  launchd.user.agents.beszel-agent = {
    serviceConfig = {
      Label = "io.beszel.agent";
      ProgramArguments = [ "${pkgs.beszel}/bin/beszel-agent" ];
      
      # 환경변수 코드 내 직접 정의 (Source of Truth)
      EnvironmentVariables = {
        KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPo8CE9Y7ZScOXSEIOshSjYNTsHjp0vZ9XEuDQI59vSs";
        PORT = "45876";
        TOKEN = "REDACTED_BESZEL_KEY";
        HUB_URL = "https://heritage.bun-bull.ts.net/beszel";
        GPU_COLLECTOR = "macmon";
      };

      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      StandardOutPath = "/Users/crong/.cache/beszel/beszel-agent.log";
      StandardErrorPath = "/Users/crong/.cache/beszel/beszel-agent.log";
    };
  };
}
