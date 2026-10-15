#!/usr/bin/env bash
# SAP Domain Models MCP — service-binding credential writer.
#
# Usage:
#   bash sap-domain-models-set-credentials.sh [--force]
#   bash sap-domain-models-set-credentials.sh [--force] <sap-domain-models-dev.json> <ias-dev.json>
#
# Reads the target cluster from the SAP Domain Models service binding
# (sap-domain-models-dev.json) and the
# client_credentials values from the IAS service binding. It writes a chmod 600
# per-environment credentials file under ~/.config/sap-domain-models/ without
# printing any secret values. Existing credentials are replaced only with
# --force.

set -euo pipefail

usage() {
  echo "Usage: $0 [--force] [<sap-domain-models-dev.json> <ias-dev.json>]" >&2
}

# Workshop binding files ship in the repository's credentials/ directory;
# pressing Enter at a prompt uses these. Run the wizard from the repository
# root so the defaults resolve.
default_binding_dir="$PWD/credentials"
default_domain_models_binding="$default_binding_dir/sap-domain-models-dev.json"
default_ias_binding="$default_binding_dir/ias-dev.json"

expand_user_path() {
  case "$1" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s/%s' "$HOME" "${1#\~/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

force=false
if [[ "${1:-}" == "--force" ]]; then
  force=true
  shift
fi

case "$#" in
  0)
    if [[ ! -t 0 ]]; then
      echo "Error: provide both service binding file paths or run this script in an interactive terminal." >&2
      usage
      exit 1
    fi
    printf 'Location of sap-domain-models-dev.json [%s]: ' "$default_domain_models_binding"
    if ! IFS= read -r domain_models_binding; then
      echo "Error: SAP Domain Models service binding path is required." >&2
      exit 1
    fi
    domain_models_binding="${domain_models_binding:-$default_domain_models_binding}"
    printf 'Location of ias-dev.json [%s]: ' "$default_ias_binding"
    if ! IFS= read -r ias_binding; then
      echo "Error: IAS service binding path is required." >&2
      exit 1
    fi
    ias_binding="${ias_binding:-$default_ias_binding}"
    ;;
  2)
    domain_models_binding="$1"
    ias_binding="$2"
    ;;
  *)
    usage
    exit 1
    ;;
esac

domain_models_binding="$(expand_user_path "$domain_models_binding")"
ias_binding="$(expand_user_path "$ias_binding")"

for binding_file in "$domain_models_binding" "$ias_binding"; do
  if [[ ! -f "$binding_file" || ! -r "$binding_file" ]]; then
    echo "Error: service binding is not a readable regular file: $binding_file" >&2
    exit 1
  fi
done

node_bin="$(command -v node 2>/dev/null || true)"
if [[ -z "$node_bin" ]]; then
  echo "Error: Node.js is required to read the service bindings." >&2
  exit 1
fi

dir="$HOME/.config/sap-domain-models"
mkdir -p "$dir"
chmod 700 "$dir"

"$node_bin" - "$domain_models_binding" "$ias_binding" "$dir" "$force" <<'NODE'
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const [domainModelsBindingPath, iasBindingPath, outputDirectory, forceValue] = process.argv.slice(2);
const force = forceValue === 'true';
let temporary;

function cleanup() {
  if (!temporary) return;
  try {
    fs.unlinkSync(temporary);
  } catch {
    // Cleanup must not hide the original validation or write failure.
  }
}

for (const [signal, exitCode] of [
  ['SIGINT', 130],
  ['SIGTERM', 143],
  ['SIGHUP', 129],
]) {
  process.once(signal, () => {
    cleanup();
    process.exit(exitCode);
  });
}

function readBinding(filePath, label) {
  let content;
  try {
    content = fs.readFileSync(filePath, 'utf8').replace(/^\uFEFF/, '');
  } catch (error) {
    throw new Error(`${label} could not be read: ${filePath} (${error.message})`);
  }

  let value;
  try {
    value = JSON.parse(content);
  } catch (error) {
    throw new Error(`${label} contains invalid JSON: ${filePath} (${error.message})`);
  }
  if (!value || Array.isArray(value) || typeof value !== 'object') {
    throw new Error(`${label} must contain a JSON object: ${filePath}`);
  }

  if (Object.hasOwn(value, 'credentials')) {
    const credentials = value.credentials;
    if (!credentials || Array.isArray(credentials) || typeof credentials !== 'object') {
      throw new Error(`${label} field "credentials" must contain a JSON object.`);
    }
    return credentials;
  }
  return value;
}

function requiredString(binding, field, label) {
  const value = binding[field];
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`${label} is missing required string field "${field}".`);
  }
  if (/[\u0000-\u001F\u007F]/u.test(value)) {
    throw new Error(`${label} field "${field}" contains an unsupported control character.`);
  }
  return value;
}

function httpsOrigin(value, label) {
  value = value.trim();
  let parsed;
  try {
    parsed = new URL(value);
  } catch {
    throw new Error(`${label} field "url" is not a valid URL.`);
  }
  if (
    parsed.protocol !== 'https:' ||
    parsed.username ||
    parsed.password ||
    (parsed.pathname !== '/' && parsed.pathname !== '') ||
    parsed.search ||
    parsed.hash
  ) {
    throw new Error(`${label} field "url" must be an HTTPS origin without a path, query, or fragment.`);
  }
  return parsed.origin;
}

const targets = new Map([
  [
    'https://nova-service-prod-dewc.appai.cloud.sap',
    {
      label: 'Prod DEWC',
      endpoint: 'https://sap-domain-models-mcp-prod-dewc.appai.cloud.sap/mcp',
      credentialsFile: 'mcp-prod-dewc-credentials.env',
      serverName: 'prod_dewc_sap_domain_models_mcp',
    },
  ],
  [
    'https://nova-service-prod-usea.appai.cloud.sap',
    {
      label: 'Prod USEA',
      endpoint: 'https://sap-domain-models-mcp-prod-usea.appai.cloud.sap/mcp',
      credentialsFile: 'mcp-prod-usea-credentials.env',
      serverName: 'prod_usea_sap_domain_models_mcp',
    },
  ],
]);

function escapeEnv(value) {
  return value.replace(/[\\"$`]/gu, '\\$&');
}

function main() {
  const domainModelsBinding = readBinding(
    domainModelsBindingPath,
    'SAP Domain Models service binding',
  );
  const serviceOrigin = httpsOrigin(
    requiredString(domainModelsBinding, 'url', 'SAP Domain Models service binding'),
    'SAP Domain Models service binding',
  );
  const target = targets.get(serviceOrigin);
  if (!target) {
    throw new Error(`Unsupported SAP Domain Models service binding URL: ${serviceOrigin}`);
  }

  const iasBinding = readBinding(iasBindingPath, 'IAS service binding');
  const tenant = httpsOrigin(
    requiredString(iasBinding, 'url', 'IAS service binding'),
    'IAS service binding',
  );
  const tenantHost = new URL(tenant).hostname;
  if (
    !tenantHost.endsWith('.accounts.ondemand.com') &&
    !tenantHost.endsWith('.accounts400.ondemand.com')
  ) {
    throw new Error('IAS service binding field "url" is not an SAP IAS tenant URL.');
  }
  const clientId = requiredString(iasBinding, 'clientid', 'IAS service binding');
  const clientSecret = requiredString(iasBinding, 'clientsecret', 'IAS service binding');

  const destination = path.join(outputDirectory, target.credentialsFile);
  let replaced = false;
  try {
    const destinationStat = fs.lstatSync(destination);
    if (!destinationStat.isFile()) {
      throw new Error(`Credentials destination exists but is not a regular file: ${destination}`);
    }
    replaced = true;
  } catch (error) {
    if (error?.code !== 'ENOENT') throw error;
  }
  if (replaced && !force) {
    throw new Error(`Credentials file already exists: ${destination}. Re-run with --force to replace it.`);
  }

  temporary = path.join(
    outputDirectory,
    `.mcp-credentials.${process.pid}.${crypto.randomBytes(8).toString('hex')}`,
  );
  const content = [
    `export SAP_DOMAIN_MODELS_IAS_TENANT="${escapeEnv(tenant)}"`,
    `export SAP_DOMAIN_MODELS_IAS_CLIENT_ID="${escapeEnv(clientId)}"`,
    `export SAP_DOMAIN_MODELS_IAS_CLIENT_SECRET="${escapeEnv(clientSecret)}"`,
    '',
  ].join('\n');

  fs.writeFileSync(temporary, content, { encoding: 'utf8', flag: 'wx', mode: 0o600 });
  fs.chmodSync(temporary, 0o600);
  fs.renameSync(temporary, destination);
  temporary = undefined;

  console.log(`Detected environment: ${target.label}`);
  console.log(`MCP endpoint: ${target.endpoint}`);
  console.log(`MCP server name: ${target.serverName}`);
  console.log(`${replaced ? 'Replaced' : 'Wrote'} ${destination}`);
}

try {
  main();
} catch (error) {
  cleanup();
  console.error(`Error: ${error.message}`);
  process.exitCode = 1;
}
NODE
