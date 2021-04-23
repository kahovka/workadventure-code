{
  adventure =
    { config, pkgs, modulesPath, ... }:
    { deployment.targetHost = "yournamehere.io"; # change domain name here
    users.extraUsers.root.openssh.authorizedKeys.keys = [(builtins.readFile ../terraform/adventure.pub)];
    imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
    ec2.hvm = true;
    nixpkgs.system = "x86_64-linux";

    networking.firewall = {
      allowedTCPPorts = [ 80 443 8080 ];
    };

    virtualisation.oci-containers.containers = let 
      baseUrl = "yournamehere.io";
      jitsiUrl = "meet.jit.si";

      SECRET_KEY = "someSecretKey";
      ADMIN_API_TOKEN = "someAdminToken";

      mkImage = { suffix, imageDigest, sha256, options }: ({
        image = "thecodingmachine/workadventure-${suffix}:${imageDigest}";
        imageFile = pkgs.dockerTools.pullImage {
          imageName = "thecodingmachine/workadventure-${suffix}";
          imageDigest = "sha256:${imageDigest}";
          sha256 = sha256;
          finalImageTag = imageDigest;
        } ;
      } // options );

    in {
      workadventure-front = let
        imageDigest = "a905a2e0c98a3aca5d88aec03e2833212797323a3c2cb15be6efc9d04fcd8312"; 
        sha256 = "sha256:0wdsg919ll6vjk4abvk061y8sjpr9zdi7kl7icfa4k73w00h4qgr"; # may differ
      in mkImage {
        inherit imageDigest sha256; suffix = "front"; options = { 
          environment = {
            JITSI_URL = jitsiUrl;
            API_URL = "api.${baseUrl}";
            
            START_ROOM_URL = "/_/global/kahovka.github.io/tcm-client/TCM/office-map/map.json";
          };
          ports = [ "8090:80" ];
        };
      };

      workadventure-pusher = let 
        imageDigest = "43dc4bfb15b7a4c09c4c38ea8595a53389770b01c528c29440adfdb1f9939d9b";
        sha256 = "sha256:0fqfcv1g0m5b4jfyjai5qyi27hp2lpfhhds6nkxc2a3mcsw95jl7"; # may differ
      in mkImage {
        inherit imageDigest sha256; suffix = "pusher"; options = { 
          environment = {
            JITSI_URL = jitsiUrl;
            SECRET_KEY = SECRET_KEY;
            ADMIN_API_TOKEN = ADMIN_API_TOKEN;
            API_URL= "workadventure-back:50051";
          };
          ports = [ "8081:8080" ];

          dependsOn = [ "workadventure-back" ];
          extraOptions = [ "--link" "workadventure-back" ];
        };
      };

      workadventure-back = let
        imageDigest = "0f8e13015b09c462a2583330426130ea7058a9f1da5946e56288ad268586a5c1";
        sha256 = "sha256:138z9qbwscfz4bnxpvn8d66zzxk7wcdypv7clmj67vsghz9lbqib"; # may differ
      in mkImage {
        inherit imageDigest sha256; suffix = "back"; options = { environment = {
          JITSI_URL = jitsiUrl;
          SECRET_KEY = SECRET_KEY;
          ADMIN_API_TOKEN = ADMIN_API_TOKEN;
          ALLOW_ARTILLERY = "true";
        };};
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "frontend" = {
            serverName = "yournamehere.io"; # change domain name here
          enableACME = true;                                                                
          forceSSL = true;                                                                  

          locations."/" = {                                                                 
            proxyPass = "http://127.0.0.1:8090/";
            priority = 10;     
          };      
          locations."/Floor0/" = {
            root = "/srv/";
            priority = 5;
          };
        };   
        "backend" = {
            serverName = "api.yournamehere.io";
          enableACME = true;                                                                
          forceSSL = true;                                                            
          locations."/" = {                                                                 
            proxyPass = "http://127.0.0.1:8081/";     
          };      
        };                                                                   
      };  
    };
    security.acme.email = "your@email.com"; # change email here
    security.acme.acceptTerms = true;
    };
}