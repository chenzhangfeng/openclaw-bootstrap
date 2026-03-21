const fs = require('fs');
const path = require('path');
const readline = require('readline');

// 从 stdin 读取密钥，不走命令行参数（避免进程列表泄露）
const providerName = process.argv[2] || 'default';
const baseUrl = process.argv[3] || '';

const rl = readline.createInterface({ input: process.stdin, terminal: false });
let apiKey = '';

rl.on('line', (line) => { apiKey = line.trim(); });
rl.on('close', () => {
  if (!apiKey) {
    console.error('[错误] 未能从输入中获取到 API Key');
    process.exit(1);
  }

  const configPath = path.join(__dirname, '..', 'data', 'openclaw.json');

  let config = {};
  if (fs.existsSync(configPath)) {
    try {
      const raw = fs.readFileSync(configPath, 'utf8');
      config = JSON.parse(raw);
    } catch (e) {
      console.error('[警告] 读取现有配置失败，将创建一份新配置。');
    }
  }

  // OpenClaw 真实配置路径: models.providers.{providerName}.apiKey / baseUrl
  if (!config.models) config.models = {};
  if (!config.models.providers) config.models.providers = {};
  if (!config.models.providers[providerName]) {
    config.models.providers[providerName] = {
      baseUrl: baseUrl,
      apiKey: apiKey,
      models: []
    };
  } else {
    config.models.providers[providerName].apiKey = apiKey;
    if (baseUrl) config.models.providers[providerName].baseUrl = baseUrl;
  }

  try {
    fs.mkdirSync(path.dirname(configPath), { recursive: true });
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf8');
    console.log('[成功] API 密钥已成功注入到配置文件中。');
    console.log('[厂商]', providerName);
    console.log('[路径]', configPath);
  } catch (e) {
    console.error('[错误] 写入配置文件失败：', e.message);
    process.exit(1);
  }
});
