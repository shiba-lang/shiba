# Shiba
Shiba is a compiled, simple, type-safe programming language. Written in Swift

## Building and Using
Open Xcode project and build the `Shiba` scheme.
Then, symlink the shiba runtime and headers:

```bash
ln -s /path/to/Shiba_DerivedData/libshibaRuntime.a /usr/local/lib/libshibaRuntime.a
mkdir /usr/local/include/shiba
ln -s /path/to/Shiba/Sources/Runtime/*.h /usr/local/include/shiba/.

```
## TODO

### Main
- [x] Lexical analysis
- [x] Parser
- [x] AST
- [x] Sema
- [ ] LLVM IR Gen
- [x] Diagnostics
- [x] Runtime
- [x] Driver

### Standard library
- [ ] Array
- [ ] Dictionary
- [ ] Higher order function

### Misc.
- [ ] Example
- [ ] Documents
- [ ] Build

### Editor support
- [x] VSCode theme
- [ ] Vim theme
