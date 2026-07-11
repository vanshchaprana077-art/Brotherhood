{pkgs}: {
  deps = [
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.unzip
    pkgs.jdk17_headless
  ];
}
