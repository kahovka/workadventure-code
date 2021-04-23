{ sources ? import ./nix/sources.nix }:
let
  nixpkgs = import sources.nixpkgs { };
in
nixpkgs.mkShell {
  name = "server";
  buildInputs = [
   nixpkgs.terraform_0_13
   nixpkgs.nixops
     ];
  postShellHook = ''
    '';
}
