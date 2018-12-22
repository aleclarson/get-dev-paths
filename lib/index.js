// Generated by CoffeeScript 2.3.2
var TypeError, fs, getDevPaths, nodeModulesRE, path, realpath;

TypeError = require('type-error');

realpath = require('realpath-native');

path = require('path');

fs = require('fs');

nodeModulesRE = /\/node_modules\//;

getDevPaths = function(root, opts = {}) {
  var next, paths, queue, search, visited;
  if (typeof root !== 'string') {
    throw TypeError(String, root);
  }
  if (!path.isAbsolute(root)) {
    throw Error('`root` argument must be an absolute path');
  }
  // Default options
  if (opts.preserveLinks == null) {
    opts.preserveLinks = true;
  }
  if (opts.onError == null) {
    opts.onError = null;
  }
  paths = [];
  queue = [root];
  visited = new Set(queue);
  // Search the "node_modules" of the given package.
  search = function(root) {
    var addPath, deps, depsDir, err, pack;
    depsDir = path.join(root, 'node_modules');
    if (!fs.existsSync(depsDir)) {
      return;
    }
    pack = path.join(root, 'package.json');
    try {
      pack = require(pack);
    } catch (error) {
      err = error;
      return typeof opts.onError === "function" ? opts.onError(err) : void 0;
    }
    // We only care about non-dev dependencies.
    if (deps = pack.dependencies) {
      addPath = function(dep) {
        var target;
        if (!fs.lstatSync(dep).isSymbolicLink()) {
          return;
        }
        try {
          target = realpath.sync(dep);
        } catch (error) {
          err = error;
          return typeof opts.onError === "function" ? opts.onError(err) : void 0;
        }
        // Skip target paths with "/node_modules/" in them.
        if (nodeModulesRE.test(target)) {
          return typeof opts.onError === "function" ? opts.onError(new Error(`Symlink leads to nothing: '${dep}'`)) : void 0;
        }
        if (opts.preserveLinks) {
          paths.push(dep);
        }
        if (!visited.has(target)) {
          visited.add(target);
          if (!opts.preserveLinks) {
            paths.push(target);
          }
          queue.push(dep);
        }
      };
      // Search the "node_modules" directory.
      return fs.readdirSync(depsDir).forEach(function(name) {
        var scope;
        if (name[0] === '.') { // Skip hidden directories.
          return;
        }
        if (name[0] === '@') {
          scope = name;
          fs.readdirSync(path.join(depsDir, name)).forEach(function(name) {
            if (deps[name = scope + '/' + name]) {
              return addPath(path.join(depsDir, name));
            }
          });
        } else if (deps[name]) {
          addPath(path.join(depsDir, name));
        }
      });
    }
  };
  // Perform a breadth-first search.
  while (queue.length) {
    next = queue;
    queue = [];
    next.forEach(search);
  }
  return paths;
};

module.exports = getDevPaths;