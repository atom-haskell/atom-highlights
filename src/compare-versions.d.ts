declare module 'compare-versions' {
  function compareVersions(v1: string, v2: string): -1 | 0 | 1
  export = compareVersions
}
