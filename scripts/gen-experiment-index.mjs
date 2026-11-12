#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { spawnSync } from 'node:child_process'

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const EXPERIMENTS = path.join(ROOT, 'experiments')
const OUTPUT = path.join(EXPERIMENTS, 'README.md')
const ROOT_README = path.join(ROOT, 'README.md')
const CHECK = process.argv.includes('--check')

// 索引必须在任何克隆里逐字节一致：只统计 git 跟踪的文件，本地未跟踪的
// output/、sim_build 等运行残留不得影响生成结果；非 git 环境（发布 tarball）回退到文件系统扫描。
function listTrackedExperiments() {
  const git = spawnSync('git', ['ls-files', 'experiments'], { cwd: ROOT, encoding: 'utf8' })
  if (git.status !== 0) return null
  return new Set(git.stdout.split(/\r?\n/).filter(Boolean))
}

const TRACKED = listTrackedExperiments()
const CATEGORY_RULES = [
  ['开源 EDA 入门', (s) => s.startsWith('eda-lab-')],
  ['EDA 流程实操', (s) => s.startsWith('flow-')],
  ['数字设计实验', (s) => s.startsWith('exp-')],
  ['排错案例', (s) => s.startsWith('ts-')],
  ['可运行模板', (s) => s.startsWith('tpl-')],
  ['OpenSTA / 时序分析', (s) => /^(opensta|sta)-/.test(s)],
  ['Vivado / XSim / XDC', (s) => /^(vivado|xsim|xdc)-/.test(s)],
  ['芯片参考与器件实验', (s) => s.startsWith('chip-ref-')],
  ['验证方法学', (s) => /^(sby|sva|sv-|cocotb)-/.test(s)],
  ['性能剖析', (s) => /^(numa|busy|spsc|cache|perf)-/.test(s)],
]
const categoryOf = (slug) => CATEGORY_RULES.find(([, match]) => match(slug))?.[0] || '综合实验'

function firstHeading(text, slug) {
  const line = text.split(/\r?\n/).find((x) => x.startsWith('# '))
  return line ? line.slice(2).trim() : slug
}

function tutorialOf(text) {
  const match = text.match(/https:\/\/geek-doc\.cn\/[^\s)>）(（]+/)
  return match ? match[0].replace(/[。，、]+$/, '') : ''
}

function evidenceFromNames(names) {
  const evidence = new Set()
  for (const name of names) {
    const base = path.basename(name)
    if (/(^|\/)(output|out)\//.test(name)) evidence.add('output/')
    else if (/\.(log|txt|csv|rpt|json)$/i.test(base)) evidence.add('日志/数据')
    else if (/\.(png|svg|vcd|fst)$/i.test(base)) evidence.add('图/波形')
  }
  return [...evidence].join(' + ') || '见 README'
}

function hasEvidenceFallback(dir) {
  const stack = [dir]
  const names = []
  while (stack.length) {
    const current = stack.pop()
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const full = path.join(current, entry.name)
      if (entry.isDirectory()) {
        if (entry.name === 'output' || entry.name === 'out') names.push(path.relative(EXPERIMENTS, full) + '/')
        else if (!['.git', 'sim_build', 'node_modules', '__pycache__'].includes(entry.name)) stack.push(full)
      } else {
        names.push(path.relative(EXPERIMENTS, full))
      }
    }
  }
  return evidenceFromNames(names)
}

const dirs = (TRACKED
  ? [...new Set([...TRACKED].filter((p) => p.split('/').length >= 3).map((p) => p.split('/')[1]))]
  : fs.readdirSync(EXPERIMENTS, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
).sort()
const rows = dirs.map((slug) => {
  const dir = path.join(EXPERIMENTS, slug)
  const readme = path.join(dir, 'README.md')
  const text = fs.existsSync(readme) ? fs.readFileSync(readme, 'utf8') : ''
  const evidence = TRACKED
    ? evidenceFromNames([...TRACKED].filter((p) => p.startsWith(`experiments/${slug}/`)))
    : hasEvidenceFallback(dir)
  return {
    slug,
    category: categoryOf(slug),
    title: firstHeading(text, slug),
    tutorial: tutorialOf(text),
    evidence,
  }
}).sort((a, b) => a.category.localeCompare(b.category, 'zh-CN') || a.slug.localeCompare(b.slug))

const counts = new Map()
for (const row of rows) counts.set(row.category, (counts.get(row.category) || 0) + 1)
const summary = [...counts.entries()].map(([name, count]) => `| ${name} | ${count} |`).join('\n')
const table = rows.map((row) => {
  const tutorial = row.tutorial ? `[教程](${row.tutorial})` : '待补链接'
  return `| ${row.category} | [${row.title}](./${row.slug}/) | ${tutorial} | ${row.evidence} |`
}).join('\n')
const content = `# 实验索引\n\n> 本文件由 \`node scripts/gen-experiment-index.mjs\` 生成，请勿手工编辑。当前共 **${rows.length} 个实验目录**。\n\n每个实验都有独立目录和 README。教程链接指向中文讲解；“实验材料”列出目录内可见的日志、数据、图或波形，具体复现方式以各实验 README 为准。\n\n## 分类统计\n\n| 分类 | 数量 |\n|---|---:|\n${summary}\n\n## 全部实验\n\n| 分类 | 实验 | 中文教程 | 实验材料 |\n|---|---|---|---|\n${table}\n`

const rootBefore = fs.readFileSync(ROOT_README, 'utf8')
const rootAfter = rootBefore
  .replace(/experiments\/` 当前收录 \*\*\d+ 个实验\*\*/, `experiments/\` 当前收录 **${rows.length} 个实验**`)
  .replace(/查看全部 \d+ 个实验/, `查看全部 ${rows.length} 个实验`)

if (CHECK) {
  if (!fs.existsSync(OUTPUT) || fs.readFileSync(OUTPUT, 'utf8') !== content || rootAfter !== rootBefore) {
    console.error('实验索引或首页计数已过期，请运行 node scripts/gen-experiment-index.mjs')
    process.exit(1)
  }
  console.log(`实验索引为最新：${rows.length} 个实验`)
} else {
  fs.writeFileSync(OUTPUT, content)
  if (rootAfter !== rootBefore) fs.writeFileSync(ROOT_README, rootAfter)
  console.log(`已生成 experiments/README.md：${rows.length} 个实验`)
}
