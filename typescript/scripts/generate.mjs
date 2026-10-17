import { execFileSync } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const expected = "25.12.19";
const flatc = process.env.FLATC ?? "flatc";
const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const schema = resolve(root, "schema/docktopus.fbs");
const outDir = resolve(root, "typescript/src");

function fail(message) {
  console.error(message);
  process.exit(1);
}

let versionText;
try {
  versionText = execFileSync(flatc, ["--version"], { encoding: "utf8" });
} catch (error) {
  fail(`flatc ${expected} is required to build docktopus-messages: ${error.message}`);
}

const found = versionText.trim().split(/\s+/).at(-1);
if (found !== expected) {
  fail(`flatc ${expected} is required to build docktopus-messages, found ${found}`);
}

execFileSync(
  flatc,
  [
    "--ts",
    "--gen-all",
    "--gen-mutable",
    "--gen-name-strings",
    "--require-explicit-ids",
    "-o",
    outDir,
    schema,
  ],
  { stdio: "inherit" },
);
