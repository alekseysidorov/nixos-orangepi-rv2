# works: boot from nvme (bottom slot), boot from usb (blue ones)
{ lib
, buildPackages
, buildLinux
, fetchFromGitHub
, fetchpatch
, stdenv
, fetchurl
, ...
} @ args:

let
  modDirVersion = "6.6.75";

  fetchCwtPatch = { name, hash }: {
    inherit name;
    patch = fetchpatch {
      url = "https://raw.githubusercontent.com/cwt-opi-rv2/linux-cwt-orangepi-ky/main/${name}";
      inherit hash;
    };
  };

  fetchKernelPatchArchive = { name, hash }: {
    inherit name;
    patch = stdenv.mkDerivation {
      pname = name;
      version = "1";
      src = fetchurl {
        url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/incr/${name}";
        inherit hash;
      };
      dontConfigure = true;
      dontBuild = true;
      dontInstall = true;
      unpackPhase = ''
        xz -dc $src > $out
      '';
    };
  };
in
(buildLinux (args // {
  inherit modDirVersion;
  version = "${modDirVersion}-ky";

  src = fetchFromGitHub {
    owner = "orangepi-xunlong";
    repo = "linux-orangepi";
    rev = "ae9e974d3e19f460b6397bfe8f0f1417a073ce05";
    hash = "sha256-3mJMruK/oQNsw9VWDVln1CZ+Zv8MXQBy4gmsi7EbX+s=";
  };

  defconfig = "x1_defconfig";

  structuredExtraConfig = with lib.kernel; {
    # ttyS0
    SERIAL_8250 = lib.mkForce no;
    SERIAL_PXA_KY_X1 = yes;

    # Graphics
    POWERVR_ROGUE = yes;

    # Broken
    SPI_DESIGNWARE_EXT = no;
    TOUCHSCREEN_GT9XX = no;
    TOUCHSCREEN_GOODIX = no;
    TYPEC_HUSB239 = no;
    USB_NET_ASIX = no;
    WLAN_VENDOR_REALTEK = no;

    ETHERCAT = no;
    TOUCHSCREEN_FTS = no;

    # Make the build faster
    COMPILE_TEST = no;
    DRM_NOUVEAU = no;
    DRM_AMDGPU = no;
  };

  kernelPatches = [
    { name = "bcmdhd-makefile-include-fix"; patch = ./bcmdhd-makefile-include-fix.patch; }
    (fetchCwtPatch { name = "linux-01-enable_pxa_pwm_on_ky_x1.patch"; hash = "sha256-nDTiRfAhgok06tP//m9NG2PoEfpKQS2Gz5mpHSHo9Pg="; })
    (fetchCwtPatch { name = "linux-02-add_DMA_BUF_ns_import_to_amvx.patch"; hash = "sha256-V2vWHTmai4PZapTGlAJnJUetv+P4C0xK01GgFUdcCKw="; })
    (fetchCwtPatch { name = "linux-03-enable-ky_x1-clocksource.patch"; hash = "sha256-2UpkCWH+QcQtJWOT1X7YFCiUDZcksyk/Wf/frHb3waU="; })
    (fetchCwtPatch { name = "linux-04-fix-timer-ky_x1-conflict-types.patch"; hash = "sha256-wtUTGfisAzacPlN76lZTLgU8biTicTZMLtCDxgcLV40="; })
    (fetchKernelPatchArchive { name = "patch-6.6.63-64.xz"; hash = "sha256-9H7xASKq8vpPPh8FtL7BmtaYp5BpLbmTDQv01CERZNA="; })
    (fetchKernelPatchArchive { name = "patch-6.6.64-65.xz"; hash = "sha256-/b9VPAOIteUQ4jA5RqbP0mvNA7xiOJ+WdaipB5E2Ue4="; })
    (fetchKernelPatchArchive { name = "patch-6.6.65-66.xz"; hash = "sha256-TP282k+l0TxQbWfqxw1kvhQyRMlAEuBM/dQ0gCzhTec="; })
    (fetchKernelPatchArchive { name = "patch-6.6.66-67.xz"; hash = "sha256-TaJu/j5TfiKqXujeUnllefD6iwSb/n/BjtONdatqnno="; })
    (fetchKernelPatchArchive { name = "patch-6.6.67-68.xz"; hash = "sha256-GgpZNXWV1jLdj8h+0P79EUOUmW9qbHjRoGf/QopALtE="; })
    (fetchKernelPatchArchive { name = "patch-6.6.68-69.xz"; hash = "sha256-mj6pH5xUpuclNC3Fy0aV5CPXzSczoo+lgmDDsf9tL5M="; })
    (fetchKernelPatchArchive { name = "patch-6.6.69-70.xz"; hash = "sha256-fOXrgcCxbRlDA8k0s1s7VS670jIVEw1j+8Rle0ah5+w="; })
    (fetchKernelPatchArchive { name = "patch-6.6.70-71.xz"; hash = "sha256-CA6ft0Q9MQnDMye6tQ8TvgrnS1HpGOx1XTIGdeAmCC4="; })
    (fetchKernelPatchArchive { name = "patch-6.6.71-72.xz"; hash = "sha256-dF7BZ4ltcU6l6+3hMGzKehkLiEXE+zeBZTqMsvtRCmg="; })
    (fetchKernelPatchArchive { name = "patch-6.6.72-73.xz"; hash = "sha256-Dx5bXfDOPX/UCBOqCMYMYM/s4DH0nR/JxaIXlfYW0gw="; })
    (fetchKernelPatchArchive { name = "patch-6.6.73-74.xz"; hash = "sha256-b8zNPBFe3c+L7gBinhY71KzaNkKSnOL5pGJFimZHxPg="; })
    (fetchKernelPatchArchive { name = "patch-6.6.74-75.xz"; hash = "sha256-viHS2I8Z9N2iUs0AIXUsF8EC+7z8QlbtvQKyUAoalN4="; })
  ];

  extraMeta = {
    branch = lib.versions.major modDirVersion;
    platforms = [ "riscv64-linux" ];
  };
} // (args.argsOverride or { }))).overrideAttrs (old: {
  nativeBuildInputs = old.nativeBuildInputs or [ ] ++ (with buildPackages; [ ubootTools ]);
  # https://github.com/NixOS/nixpkgs/pull/438688
  # https://stackoverflow.com/questions/40442218/how-to-pass-compiler-options-during-linux-kernel-compilation
  env.KCFLAGS = toString [
    "-Wno-error=incompatible-pointer-types"
    "-Wno-error=implicit-function-declaration"
    "-Wno-error=int-conversion"
  ];
})
