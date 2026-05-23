{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  kernel,
}:
stdenv.mkDerivation rec {
  pname = "tp-link-aic8800";
  version = "1.0.8";
  compressFirmware = false;

  src = fetchurl {
    url = "https://linux.brostrend.com/aic8800-dkms.deb";
    hash = "sha256-lSFS863U7CT+5K9aZ3tAE17sd1mUUmjIU5vMi42mVes=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [ dpkg ];
  hardeningDisable = [
    "pic"
    "format"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  sourceRoot = ".";

  patchPhase = ''
    runHook prePatch

    substituteInPlace usr/src/aic8800-${version}/aic8800_fdrv/aicwf_usb.h \
      --replace-fail '#define USB_VENDOR_ID_TENDA              0x2604' '#define USB_VENDOR_ID_TENDA              0x2604
#define USB_VENDOR_ID_TPLINK             0x3625' \
      --replace-fail '#define USB_PRODUCT_ID_AIC8800FC_CUS6   0x88E5' '#define USB_PRODUCT_ID_AIC8800FC_CUS6   0x88E5
#define USB_PRODUCT_ID_TPLINK_TX1U_NANO  0x0110'

    substituteInPlace usr/src/aic8800-${version}/aic8800_fdrv/aicwf_usb.c \
      --replace-fail '|| pid == USB_PRODUCT_ID_AIC8800FC_CUS6){' '|| pid == USB_PRODUCT_ID_AIC8800FC_CUS6
		|| pid == USB_PRODUCT_ID_TPLINK_TX1U_NANO){' \
      --replace-fail '{USB_DEVICE_AND_INTERFACE_INFO(USB_VENDOR_ID_AIC, USB_PRODUCT_ID_AIC8800DC, 0xff, 0xff, 0xff)},' '{USB_DEVICE_AND_INTERFACE_INFO(USB_VENDOR_ID_AIC, USB_PRODUCT_ID_AIC8800DC, 0xff, 0xff, 0xff)},
    {USB_DEVICE_AND_INTERFACE_INFO(USB_VENDOR_ID_TPLINK, USB_PRODUCT_ID_TPLINK_TX1U_NANO, 0xff, 0xff, 0xff)},'

    runHook postPatch
  '';

  buildPhase = ''
    runHook preBuild

    cd "$NIX_BUILD_TOP/usr/src/aic8800-${version}"
    make \
      KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      KVER=${kernel.modDirVersion}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cd "$NIX_BUILD_TOP/usr/src/aic8800-${version}"

    modDir="$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/aic8800"
    mkdir -p "$modDir"
    install -Dm644 aic_load_fw/aic_load_fw.ko "$modDir/aic_load_fw.ko"
    install -Dm644 aic8800_fdrv/aic8800_fdrv.ko "$modDir/aic8800_fdrv.ko"

    mkdir -p "$out/lib/firmware"
    cp -r "$NIX_BUILD_TOP/lib/firmware/aic8800D80" "$out/lib/firmware/"
    cp -r "$NIX_BUILD_TOP/lib/firmware/aic8800DC" "$out/lib/firmware/"

    find "$modDir" -name '*.ko' -exec xz -f {} \;

    runHook postInstall
  '';

  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  meta = {
    description = "AIC8800 USB Wi-Fi driver for the TP-Link Archer TX1U Nano/A";
    homepage = "https://www.tp-link.com/us/support/download/archer-tx1u-nano/";
    license = with lib.licenses; [
      gpl2Only
      unfreeRedistributableFirmware
    ];
    platforms = lib.platforms.linux;
  };
}
