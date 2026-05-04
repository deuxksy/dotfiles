{ pkgs, ... }:
let
  # beszel 0.18.6 checkPhase: SMART_DEVICES 파싱 테스트 실패 → doCheck 비활성화
  beszelPkg = pkgs.beszel.overrideAttrs (old: { doCheck = false; });
in
{
  environment.systemPackages = [ beszelPkg ];

  launchd.user.agents.beszel-agent = {
    serviceConfig = {
      Label = "io.beszel.agent";
      ProgramArguments = [ "${beszelPkg}/bin/beszel-agent" ];

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
