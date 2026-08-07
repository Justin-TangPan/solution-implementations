import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import test from "node:test"

const config = JSON.parse(readFileSync("project.config.json", "utf8"))
const index = JSON.parse(readFileSync("web/src/lib/practices-index.json", "utf8"))

test("web index contains exactly the formal practices", () => {
  assert.deepEqual(index.practices.map(({ slug }) => slug).sort(), [...config.formal.practices].sort())
})

test("web editorial data cannot define formal scope or deployment structure", () => {
  const source = readFileSync("web/src/lib/data.ts", "utf8").split("export const evaluations", 1)[0]
  const editorialSlugs = [...source.matchAll(/slug:\s*"([^"]+)"/g)].map(match => match[1])
  assert.ok(editorialSlugs.every(slug => config.formal.practices.includes(slug)))
  assert.doesNotMatch(source, /\b(?:regions|hasHA)\s*:/)
})
