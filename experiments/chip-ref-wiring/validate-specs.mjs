import { readdirSync, readFileSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = dirname(fileURLToPath(import.meta.url))
const files = readdirSync(join(root, 'circuits')).filter((file) => file.endsWith('.json'))
let failed = false

for (const file of files) {
  const spec = JSON.parse(readFileSync(join(root, 'circuits', file), 'utf8'))
  const errors = []
  if (!spec.slug) errors.push('missing slug')
  if (!Array.isArray(spec.components) || spec.components.length === 0) errors.push('components must be non-empty')
  if (!Array.isArray(spec.links) || spec.links.length === 0) errors.push('links must be non-empty')

  const componentKeys = new Set()
  const refs = new Map()
  for (const component of spec.components ?? []) {
    const key = `${component.ref}:${component.unit ?? 1}`
    if (componentKeys.has(key)) errors.push(`duplicate component ${key}`)
    componentKeys.add(key)
    if (!component.lib_id || !component.lib_file) errors.push(`component ${component.ref} misses lib metadata`)
    refs.set(component.ref, (refs.get(component.ref) ?? 0) + 1)
  }

  const linkKeys = new Set()
  const nets = new Set()
  for (const link of spec.links ?? []) {
    if (!refs.has(link.ref)) errors.push(`link references unknown component ${link.ref}`)
    const key = `${link.ref}:${link.pin}`
    if (linkKeys.has(key)) errors.push(`duplicate link ${key}`)
    linkKeys.add(key)
    nets.add(link.net)
  }

  for (const nc of spec.no_connect ?? []) {
    if (!refs.has(nc.ref)) errors.push(`no_connect references unknown component ${nc.ref}`)
    const key = `${nc.ref}:${nc.pin}`
    if (linkKeys.has(key)) errors.push(`pin ${key} is both linked and marked no_connect`)
  }

  if (!nets.has('GND')) errors.push('missing GND net')
  if (![...nets].some((net) => net.startsWith('+'))) errors.push('missing positive supply net')
  const hasConnectorPower = (spec.components ?? []).some((component) => component.lib_file === 'Connector.kicad_sym' || component.lib_file === 'Connector_Generic.kicad_sym') &&
    nets.has('GND') &&
    [...nets].some((net) => net.startsWith('+'))
  if (!hasConnectorPower && !(spec.components ?? []).some((component) => component.lib_id === 'power:PWR_FLAG')) {
    errors.push('missing power:PWR_FLAG')
  }

  if (errors.length) {
    failed = true
    console.error(`${file}: ${errors.join('; ')}`)
  } else {
    console.log(`${file}: ok (${spec.components.length} components, ${spec.links.length} links, ${(spec.no_connect ?? []).length} no-connect)`)
  }
}

if (failed) process.exit(1)
