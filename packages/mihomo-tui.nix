# https://github.com/NixOS/nixpkgs/pull/547113

{
  lib,
  rustPlatform,
  fetchFromGitHub,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "mihomo-tui";
  version = "0.6.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "potoo0";
    repo = "mihomo-tui";
    tag = "v${finalAttrs.version}";
    hash = "sha256-w0W0J/SsEw6go5eRcLzEbGTh4JMxlp4pWjrTddFfpvc=";
  };

  cargoHash = "sha256-wHuf+dlqAsD63gJH44w6r3+sPMJdFYxSReuqW8NCyng=";

  env = {
    RUSTFLAGS = "--cfg tokio_unstable";
    VERGEN_GIT_DESCRIBE = "v${finalAttrs.version}";
    VERGEN_BUILD_DATE = "2026-10-31";
    VERGEN_DEFAULT_ON_ERROR = "1";
  };

  __darwinAllowLocalNetworking = true;

  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  doCheck = false;
  doInstallCheck = true;

  meta = {
    description = "Simple TUI dashboard for monitoring and managing Mihomo via its REST API";
    homepage = "https://github.com/potoo0/mihomo-tui";
    changelog = "https://github.com/potoo0/mihomo-tui/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "mihomo-tui";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})