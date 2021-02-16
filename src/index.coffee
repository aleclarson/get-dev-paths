TypeError = require 'type-error'
realpath = require 'realpath-native'
path = require 'path'
fs = require 'fs'

nodeModulesRE = /\/node_modules\//

getDevPaths = (root, opts = {}) ->
  if typeof root != 'string'
    throw TypeError String, root
  if !path.isAbsolute root
    throw Error '`root` argument must be an absolute path'

  opts.ignore ?= /^$/

  paths = []
  queue = [root]
  visited = new Set(queue)

  # Search the "node_modules" of the given package.
  search = (root) ->
    depsDir = path.join root, 'node_modules'
    return if !fs.existsSync depsDir

    pack = path.join root, 'package.json'
    try pack = require pack
    catch err
      return opts.onError? err

    # We only care about non-dev dependencies.
    if deps = pack.dependencies

      addPath = (dep) ->
        # We only care about linked dependencies.
        return if !fs.lstatSync(dep).isSymbolicLink()

        try target = realpath.sync dep
        catch err
          return opts.onError? err

        # Skip target paths with "/node_modules/" in them.
        if nodeModulesRE.test target
          return opts.onError? new Error "Target path cannot contain /node_modules/: '#{dep}'"

        if opts.preserveLinks
          paths.push dep

        # Avoid crawling the same directory twice.
        if !visited.has target
          visited.add target
          paths.push target if !opts.preserveLinks
          queue.push dep
        return

      # Search the "node_modules" directory.
      fs.readdirSync(depsDir).forEach (name) ->

        if name[0] == '.'
          return # Skip hidden directories.

        if name[0] == '@'
          scope = name
          fs.readdirSync(path.join depsDir, name).forEach (name) ->
            name = scope + '/' + name
            if deps[name] and !opts.ignore.test name
              addPath path.join depsDir, name

        else if deps[name] and !opts.ignore.test name
          addPath path.join depsDir, name
        return

  # Perform a breadth-first search.
  while queue.length
    next = queue
    queue = []
    next.forEach search
  paths

module.exports = getDevPaths
