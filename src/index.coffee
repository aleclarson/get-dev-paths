TypeError = require 'type-error'
path = require 'path'
fs = require 'fs'

getDevPaths = (root, opts = {}) ->
  if typeof root != 'string'
    throw TypeError String, root
  if !path.isAbsolute root
    throw Error '`root` argument must be an absolute path'

  paths = []
  search = (root) ->

    pack = path.join root, 'package.json'
    return if !fs.existsSync pack

    try pack = JSON.parse fs.readFileSync pack, 'utf8'
    catch err
      return opts.onError? new Error """
        Failed to parse: #{pack}
        #{err.message}
      """

    # We only care about non-dev dependencies.
    deps = pack.dependencies
    return if !deps

    root = path.join root, 'node_modules'
    fs.existsSync(root) and
      getDependencyPaths(root, deps).forEach (dep) ->
        if !isNodeModules dep, opts
          paths.push dep
          search dep
        return

  search root
  paths

module.exports = getDevPaths

#
# Internal
#

nodeModulesRE = /\/node_modules\//

isNodeModules = (dep, opts) ->
  try nodeModulesRE.test fs.realpathSync(dep)
  catch err
    opts.onError? new Error """
      Symlink leads to nowhere: #{dep}
    """
    true

getDependencyPaths = (root, deps) ->
  paths = []

  fs.readdirSync(root).forEach (name) ->
    return if name[0] == '.'
    dep = path.join root, name

    if name[0] == '@'
      scope = name
      fs.readdirSync(dep).forEach (name) ->
        if deps[scope + '/' + name]
          paths.push path.join dep, name

    else if deps[name]
      paths.push dep
      return

  paths
