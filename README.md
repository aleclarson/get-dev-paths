# get-dev-paths

Search `node_modules` for symlinks that resolve to a package outside any `node_modules` directories.

Returns an array of symlink paths that match the following criteria:
- they live in `node_modules`
- their real paths are *not* in `node_modules`
- they are non-dev dependencies (as defined in `package.json`)

Every matched package also has its `node_modules` searched.

Scoped packages are supported.

```js
import getDevPaths from 'get-dev-paths';

const paths = getDevPaths(process.cwd()); // => string[]
```
