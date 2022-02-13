module.exports = {
   constructName: (name, type) => {
    return type === "LONG" ? `${name} Synth` : `${name} Reversed Synth`
  },
  constructSymbol: (symbol, type) => {
    return type === "LONG" ? `d${symbol}` : `r${symbol}`
  },
  constructVersion: (major, minor) => {
    return `v${major}.${minor}`
  }
}
