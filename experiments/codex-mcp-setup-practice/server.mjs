#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';

const allowed = process.argv.slice(2).map((entry) => fs.realpathSync(path.resolve(entry)));
if (allowed.length === 0) {
  console.error('[filesystem-mcp] usage: node server.mjs <allowed-directory>...');
  process.exit(2);
}

function send(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function insideAllowed(candidate) {
  return allowed.some((root) => {
    const relative = path.relative(root, candidate);
    return relative === '' || (!relative.startsWith('..') && !path.isAbsolute(relative));
  });
}

const tools = [
  {
    name: 'list_allowed_directories',
    description: 'List directories this server allows file operations on.',
    inputSchema: { type: 'object', properties: {}, additionalProperties: false },
  },
  {
    name: 'read_text_file',
    description: 'Read the complete contents of a UTF-8 text file.',
    inputSchema: {
      type: 'object',
      properties: { path: { type: 'string', description: 'Absolute file path' } },
      required: ['path'],
      additionalProperties: false,
    },
  },
];

if (process.env.MCP_STDIO_POLLUTE === '1') {
  process.stdout.write('filesystem MCP server starting\n');
}

const rl = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
rl.on('line', (line) => {
  if (!line.trim()) return;
  let request;
  try {
    request = JSON.parse(line);
  } catch (error) {
    console.error(`[filesystem-mcp] invalid request: ${error.message}`);
    return;
  }

  const { id, method, params = {} } = request;
  console.error(`[filesystem-mcp] method=${method} id=${id ?? 'notification'}`);
  if (method === 'notifications/initialized') return;

  if (method === 'initialize') {
    send({
      jsonrpc: '2.0', id,
      result: {
        protocolVersion: '2025-03-26',
        capabilities: { tools: { listChanged: false } },
        serverInfo: { name: 'minimal-filesystem', version: '1.0.0' },
      },
    });
    return;
  }

  if (method === 'tools/list') {
    send({ jsonrpc: '2.0', id, result: { tools } });
    return;
  }

  if (method === 'tools/call') {
    if (params.name === 'list_allowed_directories') {
      send({ jsonrpc: '2.0', id, result: { content: [{ type: 'text', text: allowed.join('\n') }] } });
      return;
    }
    if (params.name === 'read_text_file') {
      try {
        const requested = fs.realpathSync(path.resolve(params.arguments?.path ?? ''));
        if (!insideAllowed(requested)) {
          send({
            jsonrpc: '2.0', id,
            result: {
              isError: true,
              content: [{ type: 'text', text: `Access denied - path outside allowed directories: ${requested}` }],
            },
          });
          return;
        }
        const text = fs.readFileSync(requested, 'utf8');
        send({ jsonrpc: '2.0', id, result: { content: [{ type: 'text', text }] } });
      } catch (error) {
        send({
          jsonrpc: '2.0', id,
          result: { isError: true, content: [{ type: 'text', text: error.message }] },
        });
      }
      return;
    }
    send({ jsonrpc: '2.0', id, error: { code: -32601, message: `Unknown tool: ${params.name}` } });
    return;
  }

  if (id !== undefined) {
    send({ jsonrpc: '2.0', id, error: { code: -32601, message: `Method not found: ${method}` } });
  }
});
