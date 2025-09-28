{ lib
, rustPlatform
, fetchCrate
, pkg-config
}:

rustPlatform.buildRustPackage
  (finalAttrs: {
    pname = "zlib-rs";
    version = "0.5.2";

    src = fetchCrate {
      inherit (finalAttrs) pname version;
      hash = "sha256-zdonyLDEkSbFAmSlDXNT/yS4UCgBtPezocnKsl0RzI8=";
    };

    cargoHash = "sha256-Mwkz3vuON+Nb+RGo8B6S09LCWVPoMDNbR7oeQp5Sh4Q=";
    cargoDepsName = finalAttrs.pname;

    nativeBuildInputs = [ pkg-config ];

    meta = with lib; {
      description = "A Rust implementation of zlib";
      homepage = "https://github.com/trifectatechfoundation/zlib-rs";
      license = licenses.mit;
      platforms = platforms.linux;
      maintainers = with maintainers; [ alekseysidorov ];
    };
  })
