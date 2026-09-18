{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "mihomo-tui";
  version = "0.4.5";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "potoo0";
    repo = "mihomo-tui";
    tag = "v${finalAttrs.version}";
    hash = "sha256-tNeH4HnpUL6UipDtSTfQLcT0ruwkUkho5+M6Mlj5E4c=";
  };

  cargoHash = "sha256-JOa5otMJE1GqpGnsIvY/O4ps0N3N1wpepESigY0+Dic=";
  RUSTFLAGS = "--cfg tokio_unstable";

  env = {
    VERGEN_GIT_DESCRIBE = "";
    VERGEN_BUILD_DATE = "";
  };

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A simple TUI dashboard for monitoring and managing Mihomo via its REST API";
    homepage = "https://github.com/potoo0/mihomo-tui";
    changelog = "https://github.com/potoo0/mihomo-tui/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "mihomo-tui";
  };
})
