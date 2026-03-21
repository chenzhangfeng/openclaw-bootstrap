const fs = require('fs');
const path = require('path');

// 平台关键词匹配规则
const PLATFORM_KEYWORDS = {
  win32:  ['win32', 'win-x64', 'win-x86', 'win-arm64', 'windows'],
  darwin: ['darwin', 'macos', 'osx'],
  linux:  ['linux', 'linuxmusl'],
};

const ARCH_KEYWORDS = {
  x64:   ['x64', 'x86_64', 'amd64'],
  arm64: ['arm64', 'aarch64'],
  ia32:  ['ia32', 'x86', 'i686'],
};

function isPlatformSpecificPkg(pkgName) {
  const lower = pkgName.toLowerCase();
  for (const keywords of Object.values(PLATFORM_KEYWORDS)) {
    for (const kw of keywords) {
      if (lower.includes(kw)) return true;
    }
  }
  for (const keywords of Object.values(ARCH_KEYWORDS)) {
    for (const kw of keywords) {
      if (lower.includes(kw)) return true;
    }
  }
  return false;
}

function matchesTarget(pkgName, targetPlatform, targetArch) {
  const lower = pkgName.toLowerCase();
  const platformKws = PLATFORM_KEYWORDS[targetPlatform] || [];
  const archKws = ARCH_KEYWORDS[targetArch] || [];
  const hasPlatform = platformKws.some(kw => lower.includes(kw));
  const hasArch = archKws.some(kw => lower.includes(kw));
  // 有平台关键词且匹配目标 → 保留
  // 有平台关键词但不匹配 → 删除
  // 没有平台关键词 → 保留（通用包）
  if (hasPlatform && hasArch) return true;
  if (hasPlatform && !hasArch) return false;
  return !isPlatformSpecificPkg(pkgName);
}

function pruneDir(dir, targetPlatform, targetArch, stats) {
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir);
  for (const entry of entries) {
    const fullPath = path.join(dir, entry);
    if (!fs.statSync(fullPath).isDirectory()) continue;

    // 检查所有 scope 和顶层包
    if (entry.startsWith('@')) {
      // scope 包, 检查子目录
      const scopeEntries = fs.readdirSync(fullPath);
      for (const sub of scopeEntries) {
        const scopedName = `${entry}/${sub}`;
        const subPath = path.join(fullPath, sub);
        if (!fs.statSync(subPath).isDirectory()) continue;
        if (isPlatformSpecificPkg(scopedName) && !matchesTarget(scopedName, targetPlatform, targetArch)) {
          fs.rmSync(subPath, { recursive: true, force: true });
          stats.removed.push(scopedName);
        } else {
          stats.kept.push(scopedName);
        }
      }
    } else {
      if (isPlatformSpecificPkg(entry) && !matchesTarget(entry, targetPlatform, targetArch)) {
        fs.rmSync(fullPath, { recursive: true, force: true });
        stats.removed.push(entry);
      }
    }
  }
}

// 解析命令行参数
const args = process.argv.slice(2);
let targetPlatform = 'win32';
let targetArch = 'x64';
let nodeModulesPath = '';

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--platform' && args[i + 1]) targetPlatform = args[++i];
  if (args[i] === '--arch' && args[i + 1]) targetArch = args[++i];
  if (args[i] === '--path' && args[i + 1]) nodeModulesPath = args[++i];
}

if (!nodeModulesPath) {
  console.error('Usage: node prune-platform.js --platform win32 --arch x64 --path ./openclaw/node_modules');
  process.exit(1);
}

console.log(`[prune] Target: ${targetPlatform}-${targetArch}`);
console.log(`[prune] Scanning: ${nodeModulesPath}`);

const stats = { removed: [], kept: [] };
pruneDir(nodeModulesPath, targetPlatform, targetArch, stats);

// 也扫描 .pnpm 内的实际包目录
const pnpmDir = path.join(nodeModulesPath, '.pnpm');
if (fs.existsSync(pnpmDir)) {
  const pnpmEntries = fs.readdirSync(pnpmDir);
  for (const entry of pnpmEntries) {
    const fullPath = path.join(pnpmDir, entry);
    if (!fs.statSync(fullPath).isDirectory()) continue;
    if (isPlatformSpecificPkg(entry) && !matchesTarget(entry, targetPlatform, targetArch)) {
      fs.rmSync(fullPath, { recursive: true, force: true });
      stats.removed.push(`.pnpm/${entry}`);
    }
  }
}

console.log(`[prune] Removed ${stats.removed.length} non-target packages`);
if (stats.removed.length > 0) {
  console.log('[prune] Removed packages:');
  stats.removed.forEach(p => console.log(`  - ${p}`));
}
