{ ... }:
{
  services.beszel.agent = {
    enable = true;
    openFirewall = true;
    environment = {
      LISTEN = "45876";
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLIlBwpSt8OB/ODdZXVXF1PrEULcyDMwN6uqZna/2Kv";
      TOKEN = "2e86c946-8b9e-41cc-a60a-782f8a5f77e4";
      HUB_URL = "https://brla.bun-bull.ts.net:8090";
    };
  };
}
