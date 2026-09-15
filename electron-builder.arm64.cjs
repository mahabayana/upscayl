const baseBuild = require("./package.json").build;

const arm64Payload = process.env.UPSHIFT64_ARM64_PAYLOAD_DIR
  || ".upshift64/staging/win-arm64/bin";

module.exports = {
  ...baseBuild,
  artifactName: "${name}-${version}-${os}-${arch}.${ext}",
  asarUnpack: [
    ...baseBuild.asarUnpack,
    "**/node_modules/@img/**/*",
    "**/node_modules/exiftool-vendored.exe/**/*",
  ],
  extraFiles: baseBuild.extraFiles.map((fileSet) =>
    fileSet.to === "resources/bin"
      ? { ...fileSet, from: arm64Payload }
      : fileSet,
  ),
  win: {
    ...baseBuild.win,
    target: [
      {
        target: "zip",
        arch: ["arm64"],
      },
    ],
  },
};
