export function constructName(name, type) {
  return type === "LONG" ? `${name} Synth` : `${name} Reversed Synth`
}

export function constructSymbol(symbol, type) {
  return type === "LONG" ? `d${symbol}` : `r${symbol}`
}

export function constructVersion(major, minor) {
  return `v${major}.${minor}`
}
