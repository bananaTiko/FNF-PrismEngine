// Fails fast when a hand-edited asset file is not valid JSON, instead of letting a
// twenty-minute C++ build finish and ship a chart the game cannot load.
const fs = require("fs");
const path = require("path");

const files = [];

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (entry.name.endsWith(".json")) files.push(full);
  }
}

walk("assets");

const bad = [];

for (const file of files) {
  // Some of the upstream spritemaps were saved with a UTF-8 BOM, which the game's
  // parser accepts; strip it so only real syntax errors fail the build.
  const text = fs.readFileSync(file, "utf8").replace(/^\uFEFF/, "");
  try {
    JSON.parse(text);
  } catch (error) {
    bad.push(`${file}: ${error.message}`);
  }
}

if (bad.length) {
  console.error(`Invalid JSON in ${bad.length} file(s):`);
  for (const line of bad) console.error(line);
  process.exit(1);
}

console.log(`Checked ${files.length} JSON files.`);
