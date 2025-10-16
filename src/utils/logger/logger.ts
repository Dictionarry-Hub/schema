// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  grey: '\x1b[90m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
}

type LogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR'

const levelColors: Record<LogLevel, string> = {
  DEBUG: colors.cyan,
  INFO: colors.green,
  WARN: colors.yellow,
  ERROR: colors.red,
}

function getTimestamp(): string {
  const now = new Date()
  return now.toISOString()
}

function formatLevel(level: LogLevel): string {
  const color = levelColors[level]
  const paddedLevel = level.padEnd(5, ' ')
  return `${color}${paddedLevel}${colors.reset}`
}

function log(level: LogLevel, message: string, ...additional: unknown[]) {
  const timestamp = `${colors.grey}${getTimestamp()}${colors.reset}`
  const separator = `${colors.grey}|${colors.reset}`
  const formattedLevel = formatLevel(level)
  const additionalInfo = additional.length > 0
    ? ' ' + additional.map(item =>
        typeof item === 'object' ? JSON.stringify(item) : String(item)
      ).join(' ')
    : ''

  console.log(`${timestamp} ${separator} ${formattedLevel} ${separator} ${message}${additionalInfo}`)
}

export const logger = {
  debug: (message: string, ...additional: unknown[]) => log('DEBUG', message, ...additional),
  info: (message: string, ...additional: unknown[]) => log('INFO', message, ...additional),
  warn: (message: string, ...additional: unknown[]) => log('WARN', message, ...additional),
  error: (message: string, ...additional: unknown[]) => log('ERROR', message, ...additional),
  separator: () => console.log(`${colors.grey}${'─'.repeat(80)}${colors.reset}`),
}
