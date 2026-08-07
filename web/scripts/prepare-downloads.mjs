import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync } from "node:fs"
import { execFileSync } from "node:child_process"
import { join, relative } from "node:path"

const root = join(process.cwd(), "..", "practices")
const out = join(process.cwd(), "public", "downloads")
const formal = JSON.parse(readFileSync(join(process.cwd(), "..", "project.config.json"))).formal.practices
rmSync(out, { recursive: true, force: true })
mkdirSync(out, { recursive: true })

for (const slug of formal) {
  const source = join(root, slug)
  const target = join(out, slug)
  const copy = (dir, bucket, predicate) => {
    if (!existsSync(dir)) return
    for (const name of readdirSync(dir)) {
      const file = join(dir, name)
      if (statSync(file).isDirectory()) copy(file, bucket, predicate)
      else if (predicate(name)) {
        const destination = join(target, bucket, relative(source, file))
        mkdirSync(join(destination, ".."), { recursive: true })
        cpSync(file, destination)
      }
    }
  }
  copy(source, "terraform", name => name.endsWith(".tf") || name.endsWith(".tf.json"))
  copy(source, "docs", name => /\.(md|mdx)$/i.test(name))
  for (const bucket of ["terraform", "docs"]) {
    const dir = join(target, bucket)
    if (existsSync(dir) && readdirSync(dir).length) execFileSync("zip", ["-qr", join(target, `${bucket}.zip`), bucket], { cwd: target })
  }
}
