import fs from 'node:fs';

const [jsonPath, label] = process.argv.slice(2);
if (!jsonPath || !label) {
  console.error('usage: node check-json.mjs <design.json> <label>');
  process.exit(2);
}

const design = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
const top = design.modules.top;

function decimalParameter(cell, name) {
  const bits =
    cell.parameters[name] ??
    design.modules[cell.type].parameter_default_values?.[name] ??
    design.modules.child.parameter_default_values[name];
  if (typeof bits !== 'string') {
    throw new Error(`${cell.name || label}: missing parameter ${name}`);
  }
  return Number.parseInt(bits, 2);
}

function checkInstance(name, expectedWidth) {
  const cell = top.cells[name];
  if (!cell) throw new Error(`missing cell ${name}`);
  const expectedOutWidth = expectedWidth + 1;
  const width = decimalParameter(cell, 'WIDTH');
  const connectionWidth = cell.connections.y.length;
  const child = design.modules[cell.type];
  if (!child) throw new Error(`missing derived module ${cell.type}`);
  const portWidth = child.ports.y.bits.length;

  console.log(
    `${label}: ${name} type=${cell.type} WIDTH=${width} ` +
      `OUT_WIDTH=${portWidth} connection_y=${connectionWidth}`,
  );

  if (width !== expectedWidth) {
    throw new Error(`${name}: WIDTH=${width}, expected ${expectedWidth}`);
  }
  if (connectionWidth !== expectedOutWidth || portWidth !== expectedOutWidth) {
    throw new Error(
      `${name}: derived width mismatch, expected OUT_WIDTH=${expectedOutWidth}`,
    );
  }
}

checkInstance('u_default', 4);
checkInstance('u_override', 8);
console.log(`PASS: ${label} keeps default WIDTH=4 and applies override WIDTH=8; derived OUT_WIDTH=5/9`);
