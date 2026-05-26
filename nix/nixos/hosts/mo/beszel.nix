{ ... }:
{
  services.beszel.agent = {
    enable = true;
    openFirewall = true;
    environment = {
      LISTEN = "45876";
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDvz1k/7RiSoe0As2jq1wAsz53+cy7RVolK8qKynyj2/";
      TOKEN = "369e62be-58f6-4fcb-9765-a047e4ee73f4";
      HUB_URL = "https://heritage.bun-bull.ts.net/beszel";
    };
  };
}
