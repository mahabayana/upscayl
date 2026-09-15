const fs = require("fs");
const path = require("path");

if (process.platform !== "win32" || process.arch !== "arm64") {
  throw new Error(
    `Sharp ARM64 verification requires native Windows ARM64, found ${process.platform}-${process.arch}.`,
  );
}

const sharp = require("sharp");
const nativeModule = require.resolve(
  "@img/sharp-win32-arm64/sharp.node",
);

function readPeMachine(filePath) {
  const file = fs.readFileSync(filePath);
  if (file.readUInt16LE(0) !== 0x5a4d) {
    throw new Error(`${filePath} is missing the MZ signature.`);
  }

  const peOffset = file.readUInt32LE(0x3c);
  if (file.readUInt32LE(peOffset) !== 0x00004550) {
    throw new Error(`${filePath} is missing the PE signature.`);
  }

  return file.readUInt16LE(peOffset + 4);
}

const machine = readPeMachine(nativeModule);
if (machine !== 0xaa64) {
  throw new Error(
    `${nativeModule} is not ARM64: PE machine is 0x${machine.toString(16).padStart(4, "0")}.`,
  );
}

const reportPath = path.resolve(
  process.argv[2] || ".upshift64/evidence/sharp-arm64.json",
);
const report = {
  generatedUtc: new Date().toISOString(),
  platform: process.platform,
  architecture: process.arch,
  sharpVersion: sharp.versions.sharp,
  libvipsVersion: sharp.versions.vips,
  nativeModule,
  peMachine: "0xAA64",
};

fs.mkdirSync(path.dirname(reportPath), { recursive: true });
fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
console.log(JSON.stringify(report, null, 2));
