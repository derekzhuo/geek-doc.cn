#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { spawnSync } from 'node:child_process'

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const EXPERIMENTS = path.join(ROOT, 'experiments')
const errors = []
const dirs = fs.readdirSync(EXPERIMENTS, { withFileTypes: true }).filter((x) => x.isDirectory()).map((x) => x.name)

for (const slug of dirs) {
  const file = path.join(EXPERIMENTS, slug, 'README.md')
  if (!fs.existsSync(file)) {
    errors.push(`${slug}: 缺 README.md`)
    continue
  }
  const text = fs.readFileSync(file, 'utf8')
  if (!/https:\/\/geek-doc\.cn\/[^\s)>）(（]+/.test(text)) errors.push(`${slug}: 缺中文教程 URL 回链`)
}

for (const file of ['README.md', 'experiments/README.md']) {
  const full = path.join(ROOT, file)
  if (!fs.existsSync(full)) {
    errors.push(`${file}: 文件不存在`)
    continue
  }
  const text = fs.readFileSync(full, 'utf8')
  const links = [...text.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)].map((m) => m[1])
  for (const link of links) {
    if (/^(https?:|mailto:|#)/.test(link)) continue
    const clean = decodeURIComponent(link.split('#')[0].split('?')[0])
    if (clean && !fs.existsSync(path.resolve(ROOT, file, '..', clean))) errors.push(`${file}: 本地链接失效 ${link}`)
  }
}

if (errors.length) {
  console.error(errors.join('\n'))
  process.exit(1)
}

const generated = spawnSync(process.execPath, ['scripts/gen-experiment-index.mjs', '--check'], {
  cwd: ROOT,
  stdio: 'inherit',
})
if (generated.status !== 0) process.exit(generated.status || 1)
console.log(`文档检查通过：${dirs.length} 个实验均有 README 和教程回链，本地链接有效`)
