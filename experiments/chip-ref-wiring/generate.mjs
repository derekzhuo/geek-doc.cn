import { mkdirSync, readFileSync, writeFileSync, readdirSync } from 'node:fs'
import { join, basename, dirname } from 'node:path'
import { randomUUID } from 'node:crypto'
import { fileURLToPath } from 'node:url'

const rootDir = dirname(fileURLToPath(import.meta.url))
const symbolDir = process.env.KICAD_SYMBOL_DIR
if (!symbolDir) throw new Error('KICAD_SYMBOL_DIR is required')

function tokenize(text) {
  return text.match(/"(?:\\.|[^"\\])*"|\(|\)|[^\s()]+/g) ?? []
}

function parseSexpr(text) {
  const tokens = tokenize(text)
  let i = 0
  function parse() {
    if (tokens[i] !== '(') throw new Error(`expected ( at token ${i}: ${tokens[i]}`)
    const node = []
    i++
    while (tokens[i] !== ')') {
      if (tokens[i] === '(') node.push(parse())
      else node.push(parseAtom(tokens[i++]))
    }
    i++
    return node
  }
  return parse()
}

class S {
  constructor(value) { this.value = value }
}

function revive(value) {
  if (Array.isArray(value)) return value.map(revive)
  if (value && typeof value === 'object' && Object.hasOwn(value, 'value') && Object.keys(value).length === 1) return new S(value.value)
  return value
}

function parseAtom(token) {
  return token.startsWith('"') ? new S(JSON.parse(token)) : token
}

function atom(value) {
  if (value instanceof S) return JSON.stringify(value.value)
  if (/^-?\d+(?:\.\d+)?$/.test(value)) return value
  if (/^[a-z]+(?: [a-z]+)*$/.test(value)) return value
  return /^[A-Za-z0-9_.~+]+$/.test(value) ? value : JSON.stringify(value)
}

function sexpr(node, depth = 0) {
  if (!Array.isArray(node)) return atom(node)
  if (node.length === 0) return '()'
  const pad = '\t'.repeat(depth)
  const head = node[0]
  const simple = node.slice(1).every((x) => !Array.isArray(x))
  if (simple) return `${pad}(${node.map(atom).join(' ')})`
  const firstArray = node.findIndex((child, index) => index > 0 && Array.isArray(child))
  const leading = node.slice(1, firstArray === -1 ? node.length : firstArray).map(atom)
  const lines = [pad + '(' + [head, ...leading].join(' ')]
  for (const child of node.slice(1 + leading.length)) {
    if (Array.isArray(child)) lines.push(sexpr(child, depth + 1))
    else lines.push('\t'.repeat(depth + 1) + atom(child))
  }
  lines.push(pad + ')')
  return lines.join('\n')
}

function get(node, name) {
  return node.find((x) => Array.isArray(x) && x[0] === name)
}

function symbolName(node) {
  return node[1] instanceof S ? node[1].value : node[1]
}

const libCache = new Map()
function readLibrary(file) {
  if (!libCache.has(file)) libCache.set(file, parseSexpr(readFileSync(join(symbolDir, file), 'utf8')))
  return libCache.get(file)
}

function resolveBaseSymbol(libNode, symbolNameWanted, libFile) {
  let currentName = symbolNameWanted
  const visited = new Set([currentName])
  while (true) {
    const current = libNode.find((n) => n[0] === 'symbol' && symbolName(n) === currentName)
    if (!current) throw new Error(`symbol not found: ${libFile}:${currentName}`)
    const extendsNode = get(current, 'extends')
    if (!extendsNode) return { source: libNode.find((n) => n[0] === 'symbol' && symbolName(n) === symbolNameWanted), baseName: currentName, base: current }
    const parentName = symbolName(extendsNode)
    if (visited.has(parentName)) throw new Error(`circular symbol inheritance: ${symbolNameWanted}`)
    visited.add(parentName)
    currentName = parentName
  }
}

function overlayProperties(target, source) {
  for (const sourceProp of source.filter((n) => Array.isArray(n) && n[0] === 'property')) {
    const name = symbolName(sourceProp)
    const index = target.findIndex((n) => Array.isArray(n) && n[0] === 'property' && symbolName(n) === name)
    const replacement = revive(structuredClone(sourceProp))
    if (index === -1) target.push(replacement)
    else target[index] = replacement
  }
}

function renameDerivedSymbols(node, baseName, wantedName) {
  if (node[0] === 'symbol') {
    const current = symbolName(node)
    if (current === baseName || current.startsWith(`${baseName}_`)) node[1] = new S(current.replace(baseName, wantedName))
  }
  for (const child of node) if (Array.isArray(child)) renameDerivedSymbols(child, baseName, wantedName)
}

function extractSymbol(libFile, symbolNameWanted) {
  const libNode = readLibrary(libFile)
  const { source, baseName, base } = resolveBaseSymbol(libNode, symbolNameWanted, libFile)
  const copy = revive(structuredClone(base))
  overlayProperties(copy, source)
  const nickname = basename(libFile, '.kicad_sym')
  renameDerivedSymbols(copy, baseName, symbolNameWanted)
  copy[1] = new S(`${nickname}:${symbolNameWanted}`)
  const value = copy.find((n) => Array.isArray(n) && n[0] === 'property' && symbolName(n) === 'Value')
  if (value) value[2] = new S(symbolNameWanted)
  return { libId: `${nickname}:${symbolNameWanted}`, node: copy }
}

function pinUnit(nodeName) {
  const m = nodeName.match(/_(\d+)_\d+$/)
  return m ? Number(m[1]) : null
}

function collectPins(symbolRoot, preferredUnit = 1) {
  const found = []
  function walk(node, unit = 0) {
    if (node[0] === 'symbol') {
      const nextUnit = pinUnit(symbolName(node)) ?? unit
      for (const child of node.slice(1)) if (Array.isArray(child)) walk(child, nextUnit)
      return
    }
    if (node[0] === 'pin') {
      const at = get(node, 'at')
      const num = get(node, 'number')
      found.push({
        number: num[1] instanceof S ? num[1].value : num[1],
        x: Number(at[1]),
        y: Number(at[2]),
        angle: Number(at[3] ?? 0),
        unit
      })
    }
    for (const child of node) if (Array.isArray(child)) walk(child, unit)
  }
  walk(symbolRoot)
  const pins = new Map()
  for (const pin of found) {
    if (pin.unit !== 0 && pin.unit !== preferredUnit) continue
    pins.set(pin.number, pin)
  }
  return pins
}

function transformPoint(pin, component) {
  const rot = component.rot ?? 0
  const sx = rot === 180 ? -pin.x : pin.x
  const sy = rot === 180 ? pin.y : -pin.y
  return { x: round2(component.x + sx), y: round2(component.y + sy) }
}

function externalPoint(pin, component) {
  const p = transformPoint(pin, component)
  const rot = component.rot ?? 0
  let ex = -Math.cos((pin.angle * Math.PI) / 180)
  let ey = Math.sin((pin.angle * Math.PI) / 180)
  if (rot === 180) ex = -ex
  const len = 5.08
  return { x: round2(p.x + ex * len), y: round2(p.y + ey * len) }
}

function round2(n) {
  return Math.round(n * 100) / 100
}

function wire(a, b) {
  return ['wire', ['pts', ['xy', a.x, a.y], ['xy', b.x, b.y]], ['stroke', ['width', 0], ['type', 'default']], ['uuid', randomUUID()]]
}

function label(net, point, justify) {
  return ['label', new S(net), ['at', point.x, point.y, 0], ['effects', ['font', ['size', 1.27, 1.27]], ['justify', justify]], ['uuid', randomUUID()]]
}

function noConnect(point) {
  return ['no_connect', ['at', point.x, point.y], ['uuid', randomUUID()]]
}

function property(name, value, x, y, hidden = false) {
  const effects = ['effects', ['font', ['size', 1.27, 1.27]]]
  if (hidden) effects.push(['hide', 'yes'])
  return ['property', new S(name), value instanceof S ? value : new S(value), ['at', round2(x), round2(y), 0], effects]
}

function buildSchematic(spec) {
  const sheetUuid = randomUUID()
  const libs = new Map()
  const components = []
  for (const c of spec.components) {
    if (!libs.has(c.lib_id)) libs.set(c.lib_id, extractSymbol(c.lib_file, c.lib_id.split(':')[1]))
    const root = libs.get(c.lib_id).node
    components.push({ ...c, pins: collectPins(root, c.unit ?? 1) })
  }
  const items = []
  const symbolInstances = []
  const pinLookup = new Map()
  for (const c of components) {
    const libNode = libs.get(c.lib_id).node
    const descriptionValue = get(libNode, 'property') ? get(libNode, 'property')[2] : '~'
    const uuid = randomUUID()
    const pinEntries = []
    for (const number of c.pins.keys()) pinEntries.push(['pin', new S(number), ['uuid', randomUUID()]])
    const instance = ['symbol', ['lib_id', new S(c.lib_id)], ['at', c.x, c.y, c.rot ?? 0], ['unit', c.unit ?? 1], ['exclude_from_sim', 'no'], ['in_bom', 'yes'], ['on_board', 'yes'], ['dnp', 'no'], ['fields_autoplaced', 'yes'], ['uuid', uuid],
      property('Reference', c.ref, c.x, c.y - 7.62),
      property('Value', c.value, c.x, c.y - 5.08),
      property('Footprint', '', c.x, c.y, true),
      property('Datasheet', '~', c.x, c.y, true),
      property('Description', descriptionValue, c.x, c.y, true),
      ...pinEntries,
      ['instances', ['project', new S(''), ['path', new S(`/${sheetUuid}`), ['reference', new S(c.ref)], ['unit', c.unit ?? 1]]]]
    ]
    symbolInstances.push(instance)
    for (const [number, pin] of c.pins) {
      const key = `${c.ref}:${number}`
      if (!pinLookup.has(key)) pinLookup.set(key, { pin, component: c })
    }
  }

  for (const link of spec.links) {
    const key = `${link.ref}:${link.pin}`
    const located = pinLookup.get(key)
    if (!located) {
      const component = components.find((x) => x.ref === link.ref)
      console.error(link.ref, [...(component?.pins?.keys() ?? [])])
      throw new Error(`missing pin ${key} in ${spec.slug}`)
    }
    const start = transformPoint(located.pin, located.component)
    const end = externalPoint(located.pin, located.component)
    items.push(wire(start, end))
    const justify = end.x < start.x ? 'right bottom' : end.x > start.x ? 'left bottom' : 'left bottom'
    items.push(label(link.net, end, justify))
  }
  for (const nc of spec.no_connect ?? []) {
    const located = pinLookup.get(`${nc.ref}:${nc.pin}`)
    if (!located) throw new Error(`missing pin ${nc.ref}:${nc.pin} in ${spec.slug}`)
    items.push(noConnect(transformPoint(located.pin, located.component)))
  }

  const root = ['kicad_sch', ['version', 20250114], ['generator', new S('eeschema')], ['generator_version', new S('10.0')], ['uuid', sheetUuid], ['paper', new S('A4')],
    ['lib_symbols', ...[...libs.values()].map((x) => x.node)],
    ...items,
    ...symbolInstances,
    ['sheet_instances', ['path', new S('/'), ['page', new S('1')]]],
    ['embedded_fonts', 'no']
  ]
  return sexpr(root)
}

function writeSchematic(specFile, outputFile) {
  const spec = JSON.parse(readFileSync(specFile, 'utf8'))
  writeFileSync(outputFile, buildSchematic(spec) + '\n')
  console.log(`generated ${outputFile}`)
}

if (process.env.CIRCUIT_FILE) {
  writeSchematic(process.env.CIRCUIT_FILE, process.env.OUTPUT_FILE)
} else {
  const files = readdirSync(join(rootDir, 'circuits')).filter((f) => f.endsWith('.json'))
  mkdirSync(join(rootDir, 'kicad'), { recursive: true })
  for (const file of files) {
    writeSchematic(join(rootDir, 'circuits', file), join(rootDir, 'kicad', `${JSON.parse(readFileSync(join(rootDir, 'circuits', file), 'utf8')).slug}.kicad_sch`))
  }
}
