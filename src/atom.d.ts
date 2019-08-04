export {}
declare module 'atom' {
  interface GrammarRegistry {
    textmateRegistry?: GrammarRegistry
  }
}
