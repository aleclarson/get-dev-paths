# get-dev-paths

Search `node_modules` for symlinks that resolve to a package outside any `node_modules` directories.

Returns an array of symlink paths that match the following criteria:
- they live in `node_modules`
- their real paths are *not* in `node_modules`
- they exist in `package.json` (but not `devDependencies`)

Every matched package also has its `node_modules` searched.

Scoped packages are supported.

**New in v0.1.1:** Up to 50x faster!

```js
import getDevPaths from 'get-dev-paths';

// When called with one argument, an array is returned which contains symlink
// paths that match the required criteria.
let paths = getDevPaths(process.cwd());

// When you want an array of resolved symlinks, set `preserveLinks` to false:
paths = getDevPaths(__dirname, {
  preserveLinks: false,
});

// When the returned array is missing an expected package, you can use the
// `onError` option to inspect why a symlink was skipped.
paths = getDevPaths(__dirname, {
  onError: console.error,
});
```
