# Lini
ini parsing library implemented by pure lua.

## guide

### load ini file
```lua
Lini = require 'Lini'
ini = Lini.load_from_file('test.ini')
```

### load ini from string
```lua
Lini = require 'Lini'
ini = Lini.load_from_string('[section]\nabc=111')
```

### write table in ini file
```lua
Lini = require 'Lini'

a = {}
a['section'] = {}
a['section']['test'] = 111

Lini.write_to_file('a.ini', a)
```

### write table in ini string
```lua
...
ini_str = Lini.write(a)
```

### subsectiron
`[section.subsection]` will be prased into:
```lua
ini = {
  section = {
    subsection = {
      ...
    }
  }
}
```

### ini format
Lines, keys and values' starting and ending Spaces will be removed in praser. If an ini file don't start with a section like `[section name]`, it will be prased into:
```lua
ini = {
  k = v,
  k2 = v2,
  ...
}
```

The format of the comments is `;comments`, so you can't use `;` in section name, key or value.
