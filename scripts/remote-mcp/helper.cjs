#!/usr/bin/env node
/* eslint-disable @typescript-eslint/no-require-imports */
/* global module, process, require */
const { Buffer } = require('node:buffer');
const { spawn } = require('node:child_process');
const { existsSync, readFileSync } = require('node:fs');
const http = require('node:http');
const os = require('node:os');
const path = require('node:path');
const { Readable } = require('node:stream');
const { pipeline } = require('node:stream/promises');

const DEFAULT_URL = 'https://sap-domain-models-mcp-prod-dewc.appai.cloud.sap/mcp';
const TEMPERATURE_HEADER = 'X-SAP-Domain-Models-Temperature';
const TEMPERATURE_ENV = 'SAP_DOMAIN_MODELS_TEMPERATURE';
const HOP_BY_HOP_HEADERS = new Set([
  'connection',
  'content-encoding',
  'content-length',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
]);

function defaultCredentialsFile(env = process.env) {
  const explicitFile = env.SAP_DOMAIN_MODELS_MCP_CREDS_FILE;
  if (explicitFile) return explicitFile;

  return path.join(os.homedir(), '.config', 'sap-domain-models', 'mcp-prod-dewc-credentials.env');
}

function parseCredentialsEnv(content) {
  const parsed = {};
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;

    const match = /^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$/.exec(line);
    if (!match) continue;

    let value = match[2].trim();
    const doubleQuoted = value.length >= 2 && value.startsWith('"') && value.endsWith('"');
    const singleQuoted = value.length >= 2 && value.startsWith("'") && value.endsWith("'");
    if (doubleQuoted || singleQuoted) {
      value = value.slice(1, -1);
      if (doubleQuoted) {
        value = value.replace(/\\([\\"$`])/g, '$1');
      }
    }
    parsed[match[1]] = value;
  }
  return parsed;
}

function loadCredentials(env = process.env, deps = {}) {
  const credsFile = deps.credsFile ?? defaultCredentialsFile(env, deps);
  const hasCredsFile = deps.existsSync?.(credsFile) ?? existsSync(credsFile);
  const fileValues = hasCredsFile
    ? parseCredentialsEnv((deps.readFileSync ?? readFileSync)(credsFile, 'utf8'))
    : {};
  const credentials = {
    tenant: fileValues.SAP_DOMAIN_MODELS_IAS_TENANT || env.SAP_DOMAIN_MODELS_IAS_TENANT,
    clientId: fileValues.SAP_DOMAIN_MODELS_IAS_CLIENT_ID || env.SAP_DOMAIN_MODELS_IAS_CLIENT_ID,
    clientSecret:
      fileValues.SAP_DOMAIN_MODELS_IAS_CLIENT_SECRET || env.SAP_DOMAIN_MODELS_IAS_CLIENT_SECRET,
  };

  const missing = [];
  if (!credentials.tenant) missing.push('SAP_DOMAIN_MODELS_IAS_TENANT');
  if (!credentials.clientId) missing.push('SAP_DOMAIN_MODELS_IAS_CLIENT_ID');
  if (!credentials.clientSecret) missing.push('SAP_DOMAIN_MODELS_IAS_CLIENT_SECRET');
  if (missing.length > 0) {
    throw new Error(
      `Missing ${missing.join(', ')}. Run the onboarding credential wizard or set the environment variables; expected credentials file: ${credsFile}.`,
    );
  }

  return credentials;
}

async function mintToken(options = {}) {
  const env = options.env ?? process.env;
  const credentials = options.credentials ?? loadCredentials(env, options);
  const tokenUrl = `${credentials.tenant.replace(/\/+$/, '')}/oauth2/token`;
  const body = new URLSearchParams({
    grant_type: 'client_credentials',
    client_id: credentials.clientId,
    client_secret: credentials.clientSecret,
  });
  const fetchImpl = options.fetchImpl ?? fetch;

  const response = await fetchImpl(tokenUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });

  const text = await response.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch (error) {
    throw new Error(`IAS token response was not valid JSON: ${error.message}`);
  }

  if (!response.ok || !data.access_token) {
    const message = data.error_description || data.error || `HTTP ${response.status}`;
    throw new Error(`IAS token response did not include access_token: ${message}`);
  }

  return data.access_token;
}

function parseTemperature(raw, source = TEMPERATURE_ENV) {
  const value = raw?.trim();
  if (!value) return undefined;
  const parsed = Number(value);
  if (
    !/^(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$/.test(value) ||
    !Number.isFinite(parsed) ||
    parsed < 0 ||
    parsed > 2
  ) {
    throw new Error(`${source} must be between 0 and 2; got ${JSON.stringify(raw)}`);
  }
  return parsed;
}

function configuredTemperature(env = process.env) {
  return parseTemperature(env[TEMPERATURE_ENV], TEMPERATURE_ENV);
}

function configuredTemperatureHeaders(env = process.env) {
  const temperature = configuredTemperature(env);
  return temperature === undefined ? {} : { [TEMPERATURE_HEADER]: String(temperature) };
}

async function headersJson(options = {}) {
  const token = await mintToken(options);
  return JSON.stringify({
    Authorization: `Bearer ${token}`,
    ...configuredTemperatureHeaders(options.env ?? process.env),
  });
}

function decodeJwtPayload(token) {
  try {
    const payload = token.split('.')[1];
    if (!payload) return {};
    return JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
  } catch {
    return {};
  }
}

function tokenExpiresSoon(token, nowSeconds = Math.floor(Date.now() / 1000), skewSeconds = 120) {
  const payload = decodeJwtPayload(token);
  return typeof payload.exp !== 'number' || payload.exp <= nowSeconds + skewSeconds;
}

function createRefreshingTokenProvider(options = {}) {
  let token;
  let refreshPromise;

  async function refresh() {
    token = await mintToken(options);
    return token;
  }

  async function getToken(forceRefresh = false) {
    if (!forceRefresh && token && !tokenExpiresSoon(token)) {
      return token;
    }
    if (!refreshPromise) {
      refreshPromise = refresh().finally(() => {
        refreshPromise = undefined;
      });
    }
    return refreshPromise;
  }

  return { getToken };
}

function readRequestBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (chunk) => chunks.push(chunk));
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

function connectionHeaderTokens(connectionHeader) {
  const values = Array.isArray(connectionHeader) ? connectionHeader : [connectionHeader];
  return new Set(
    values
      .filter(Boolean)
      .flatMap((value) => String(value).split(','))
      .map((value) => value.trim().toLowerCase())
      .filter(Boolean),
  );
}

function shouldStripHeader(name, connectionTokens = new Set()) {
  const lowerName = name.toLowerCase();
  return HOP_BY_HOP_HEADERS.has(lowerName) || connectionTokens.has(lowerName);
}

async function fetchWithBearer(
  req,
  targetUrl,
  body,
  tokenProvider,
  configuredHeaders,
  forceRefresh = false,
) {
  const token = await tokenProvider.getToken(forceRefresh);
  const connectionTokens = connectionHeaderTokens(req.headers.connection);
  const headers = { ...req.headers, authorization: `Bearer ${token}` };
  delete headers[TEMPERATURE_HEADER.toLowerCase()];
  for (const name of Object.keys(headers)) {
    if (name.toLowerCase() === 'host' || shouldStripHeader(name, connectionTokens)) {
      delete headers[name];
    }
  }
  Object.assign(headers, configuredHeaders);

  return fetch(targetUrl, {
    method: req.method,
    headers,
    body: body.length > 0 ? body : undefined,
  });
}

async function writeProxyResponse(res, response) {
  res.statusCode = response.status;
  const connectionTokens = connectionHeaderTokens(response.headers.get('connection'));
  response.headers.forEach((value, key) => {
    if (!shouldStripHeader(key, connectionTokens)) {
      res.setHeader(key, value);
    }
  });
  if (!response.body) {
    res.end();
    return;
  }
  await pipeline(Readable.fromWeb(response.body), res);
}

async function startRefreshingProxy(remoteUrl = DEFAULT_URL, options = {}) {
  const target = new URL(remoteUrl);
  const tokenProvider = options.tokenProvider ?? createRefreshingTokenProvider(options);
  const configuredHeaders = configuredTemperatureHeaders(options.env ?? process.env);
  const server = http.createServer(async (req, res) => {
    try {
      const requestUrl = new URL(req.url || '/', 'http://127.0.0.1');
      const targetUrl = new URL(target.href);
      targetUrl.pathname = requestUrl.pathname;
      targetUrl.search = requestUrl.search;

      const body = await readRequestBody(req);
      let response = await fetchWithBearer(req, targetUrl, body, tokenProvider, configuredHeaders);
      if (response.status === 401) {
        response = await fetchWithBearer(
          req,
          targetUrl,
          body,
          tokenProvider,
          configuredHeaders,
          true,
        );
      }
      if (response.status === 401) {
        res.statusCode = 502;
        res.setHeader('content-type', 'application/json');
        res.end(
          JSON.stringify({
            error: 'sap_domain_models_mcp_auth_failed',
            message: 'SAP Domain Models MCP authentication failed after refreshing the IAS token.',
          }),
        );
        return;
      }
      await writeProxyResponse(res, response);
    } catch (error) {
      if (!res.headersSent) {
        res.statusCode = 502;
        res.setHeader('content-type', 'application/json');
        res.end(
          JSON.stringify({
            error: 'sap_domain_models_mcp_proxy_error',
            message: error instanceof Error ? error.message : String(error),
          }),
        );
      } else {
        res.end();
      }
    }
  });

  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => {
      server.off('error', reject);
      resolve();
    });
  });

  const address = server.address();
  if (!address || typeof address === 'string') {
    server.close();
    throw new Error('Failed to start local refreshing proxy');
  }

  return {
    server,
    url: `http://127.0.0.1:${address.port}${target.pathname}${target.search}`,
  };
}

function getNpxCommand(platform = process.platform) {
  return platform === 'win32' ? 'npx.cmd' : 'npx';
}

function buildMcpRemoteInvocation(url = DEFAULT_URL, platform = process.platform, options = {}) {
  const npxCommand = getNpxCommand(platform);
  const args = ['-y', 'mcp-remote', url];
  if (options.allowHttp) args.push('--allow-http');
  if (options.staticAuthHeader) args.push('--header', 'Authorization:${AUTH_HEADER}');
  if (options.temperatureHeader) {
    args.push('--header', 'X-SAP-Domain-Models-Temperature:${TEMPERATURE_HEADER}');
  }
  if (platform === 'win32') {
    return {
      command: 'cmd.exe',
      args: ['/d', '/s', '/c', npxCommand, ...args],
    };
  }

  return {
    command: npxCommand,
    args,
  };
}

async function runMcpRemoteStatic(url = DEFAULT_URL, options = {}) {
  const token = await mintToken(options);
  const temperature = configuredTemperature(options.env ?? process.env);
  const invocation = buildMcpRemoteInvocation(url, options.platform ?? process.platform, {
    staticAuthHeader: true,
    temperatureHeader: temperature !== undefined,
  });
  const childEnv = { ...(options.env ?? process.env), AUTH_HEADER: `Bearer ${token}` };
  if (temperature !== undefined) {
    childEnv.TEMPERATURE_HEADER = String(temperature);
  }
  const spawnImpl = options.spawnImpl ?? spawn;

  const child = spawnImpl(invocation.command, invocation.args, {
    stdio: 'inherit',
    env: childEnv,
  });

  return new Promise((resolve, reject) => {
    child.on('error', reject);
    child.on('exit', (code, signal) => {
      if (signal) {
        resolve(0);
        return;
      }
      resolve(code ?? 0);
    });
  });
}

async function runMcpRemote(url = DEFAULT_URL, options = {}) {
  const proxy = await startRefreshingProxy(url, options);
  const invocation = buildMcpRemoteInvocation(proxy.url, options.platform ?? process.platform, {
    allowHttp: true,
  });
  const spawnImpl = options.spawnImpl ?? spawn;
  const child = spawnImpl(invocation.command, invocation.args, {
    stdio: 'inherit',
    env: options.env ?? process.env,
  });

  return new Promise((resolve, reject) => {
    child.on('error', (error) => {
      proxy.server.close();
      reject(error);
    });
    child.on('exit', (code, signal) => {
      proxy.server.close();
      if (signal) {
        resolve(0);
        return;
      }
      resolve(code ?? 0);
    });
  });
}

function resolveCommand(argv) {
  const invokedAs = path.basename(argv[1] || '');
  return invokedAs === 'sap-domain-models-mcp-headers' || invokedAs === 'nova-remote-headers'
    ? 'headers'
    : argv[2];
}

async function main(argv) {
  const command = resolveCommand(argv);
  if (command === 'mint-token') {
    process.stdout.write(`${await mintToken()}\n`);
    return 0;
  }
  if (command === 'headers') {
    process.stdout.write(`${await headersJson()}\n`);
    return 0;
  }
  if (command === 'mcp-remote') {
    return runMcpRemote(argv[3] || DEFAULT_URL);
  }
  if (command === 'mcp-remote-static') {
    return runMcpRemoteStatic(argv[3] || DEFAULT_URL);
  }

  process.stderr.write(
    'Usage: node helper.cjs <mint-token|headers|mcp-remote|mcp-remote-static> [mcp-url]\n',
  );
  return 2;
}

module.exports = {
  buildMcpRemoteInvocation,
  configuredTemperature,
  configuredTemperatureHeaders,
  createRefreshingTokenProvider,
  decodeJwtPayload,
  defaultCredentialsFile,
  getNpxCommand,
  headersJson,
  loadCredentials,
  mintToken,
  parseCredentialsEnv,
  parseTemperature,
  runMcpRemote,
  runMcpRemoteStatic,
  resolveCommand,
  startRefreshingProxy,
  tokenExpiresSoon,
};

if (require.main === module) {
  main(process.argv)
    .then((code) => {
      process.exitCode = code;
    })
    .catch((error) => {
      process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
      process.exitCode = 1;
    });
}
