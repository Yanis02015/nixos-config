{
  description = "Hyprland on Nixos";
  
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # NB : Claude Desktop n'est plus un input flake (aaddrick) — il est packagé
    # localement depuis le .deb officiel Anthropic, voir nixos/claude-desktop.nix.
  };
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; }; 
      modules = [
        ./configuration.nix
      ];
    };
  };
}
