window.Environment = {
    "print": (args...) ->
        console.log args...
}

window.evaluateDocument = (doc) ->
    console.log "attempting to evaluate document", doc
    scope = new Scope()
    compileList(scope, doc.node.list)

    for variable in scope.upscope
        variable.slot = 'Environment["'+variable.name+'"]'
    console.log scope.build()

compileList = (scope, exprs) ->
    vars = []
    for node in exprs
        continue if isCr(node)
        vars.push compileExpr(scope, node)
    return vars

compileExpr = (scope, expr) ->
    if isText(expr)
        return {name:null, slot:expr.text} if /^\d+$/.test(expr.text)
        return scope.lookup(expr.text)
    else if isList(expr) and expr.label == null
        args = compileList(scope, expr.list)
        callee = args.shift()
        retvar = scope.tempvar()
        scope.push -> "#{slot retvar} = #{slot callee}(#{(slots args).join ', '});"
        return retvar
    else if isMacro(expr, "let") and expr.length == 2 and isText(expr.get(0))
        retvar = scope.define(expr.get(0).text)
        argvar = compileExpr(scope, expr.get(1))
        scope.push -> "#{slot retvar} = #{slot argvar};"
        return retvar
    else if isMacro(expr, "set") and expr.length == 2 and isText(expr.get(0))
        retvar = scope.lookup(expr.get(0).text)
        argvar = compileExpr(scope, expr.get(1))
        scope.push -> "#{slot retvar} = #{slot argvar};"
        return retvar
    #else if isMacro(expr, "cond")
    #else if isMacro(expr, "while")
    else
        console.log expr
        throw "blah"

isMacro = (expr, name) ->
    isList(expr) and expr.label == name

class Scope
    constructor: (@parent=null) ->
        @locals = []
        @upscope = []
        @block = []

    define: (name) ->
        for local in @locals
            if local.name == name
                return local
        @locals.push local = {name, slot:genSym()}
        return local

    lookup: (name) ->
        for local in @locals
            if local.name == name
                return local
        return @parent.lookup(name) if @parent?
        @upscope.push up = {name, slot:null}
        return up

    tempvar: () ->
        @locals.push local = {name:null, slot:genSym()}
        return local

    push: (string) ->
        @block.push string

    build: () ->
        out = "var #{(slots @locals).join ', '};"
        for block in @block
            out += block()
        return out

lastTmp = 1
genSym = () -> "__t#{lastTmp += 1}"

slot  = (variable) -> variable.slot
slots = (variables) -> (variable.slot for variable in variables)
