{ ... }:
{
  services.beszel.agent = {
    enable = true;
    openFirewall = true;
    environment = {
      LISTEN = "45876";
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPo8CE9Y7ZScOXSEIOshSjYNTsHjp0vZ9XEuDQI59vSs";
      TOKEN = "96f03983-0ece-41f3-97bc-74be4fcf9398";
      HUB_URL = "https://heritage.bun-bull.ts.net/beszel";
    };
  };
}
