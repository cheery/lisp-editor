window.Environment = {
    "print": (args...) ->
        console.log args...
    "+":  (a, b) -> a + b
    "-":  (a, b) -> a - b
    "*":  (a, b) -> a * b
    "%":  (a, b) -> a % b
    "/":  (a, b) -> a / b
    "<":  (a, b) -> a < b
    "<=": (a, b) -> a <= b
    ">=": (a, b) -> a >= b
    ">":  (a, b) -> a > b
    "=":  (a, b) -> a == b
    "!=": (a, b) -> a != b
}

window.evaluateDocument = (doc) ->
    scope = new Scope()
    compileList(scope, doc.node.list)

    for variable in scope.upscope
        variable.slot = 'Environment["'+variable.name+'"]'
    text = scope.build()
    func = new Function(text)
    func()

compileList = (scope, exprs) ->
    vars = []
    for node in exprs
        continue if isCr(node)
        vars.push compileExpr(scope, node)
    return vars

compileBlock = (scope, exprs) ->
    retvar = {name:null, slot:"null"}
    for node in exprs
        continue if isCr(node)
        retvar = compileExpr(scope, node)
    return retvar

compileExpr = (scope, expr) ->
    if isText(expr)
        retrun {name:null, slot:JSON.stringify(expr.text)} if expr.label == 'string'
        return {name:null, slot:"true"} if expr.text == 'true'
        return {name:null, slot:"false"} if expr.text == 'false'
        return {name:null, slot:"null"} if expr.text == 'null'
        return {name:null, slot:expr.text} if /^\d+$/.test(expr.text)
        return scope.lookup(expr.text)
    else if isList(expr) and expr.label == null
        args = compileList(scope, expr.list)
        callee = args.shift()
        retvar = scope.tempvar()
        scope.push -> "#{slot retvar} = #{slot callee}(#{(slots args).join ', '});"
        return retvar
    else if isMacro(expr, "let") and expr.length == 2 and isText(expr.get(0))
        argvar = compileExpr(scope, expr.get(1))
        retvar = scope.define(expr.get(0).text)
        scope.push -> "#{slot retvar} = #{slot argvar};"
        return retvar
    else if isMacro(expr, "set") and expr.length == 2 and isText(expr.get(0))
        argvar = compileExpr(scope, expr.get(1))
        retvar = scope.lookup(expr.get(0).text)
        scope.push -> "#{slot retvar} = #{slot argvar};"
        return retvar
    else if isMacro(expr, "return")
        retvar = compileBlock(scope, expr.list)
        scope.push -> "return #{slot retvar};"
        return retvar
    else if isMacro(expr, "func") and isList(expr.get(0))
        retfunc = scope.tempvar()
        scope = new Scope(scope)
        for arg in expr.get(0).list
            scope.args.push {name:arg.text, slot:genSym()}
        retval = compileBlock(scope, expr.list[1...])
        scope.push -> "return #{slot retval};"
        scope.close()
        scope.parent.push -> "#{slot retfunc} = function(#{(slots scope.args).join ","}){" + scope.build() + "};"
        return retfunc
    else if isMacro(expr, "cond")
        return compileCond(scope, expr.list)
    else if isMacro(expr, "while")
        scope.push -> "while(true){"
        cond = compileExpr(scope, expr.get(0))
        scope.push -> "if(!(#{slot cond})) break;"
        compileBlock(scope, expr.list[1...])
        scope.push -> "}"
        return {name:null, slot:"null"}
    else
        console.log expr
        throw "blah"

compileCond = (scope, list) ->
    if list.length == 0
        return {name:null, slot:"null"}
    expr = list[0]
    if isCr(expr)
        return compileCond(scope, list[1...])
    if isMacro(expr, "else")
        return compileBlock(scope, expr.list)
    cond = compileExpr(scope, expr.get(0))
    scope.push -> "if(#{slot cond}) {"
    retvar = compileBlock(scope, expr.list[1...])
    scope.push -> "} else {"
    elsevar = compileCond(scope, list[1...])
    scope.push -> "#{slot retvar} = #{slot elsevar};"
    scope.push -> "}"
    return retvar

isMacro = (expr, name) ->
    isList(expr) and expr.label == name

class Scope
    constructor: (@parent=null) ->
        @args = []
        @locals = []
        @upscope = []
        @block = []
        @closures = []
        @parent.closures.push @ if @parent?

    close: () ->
        for closure in @closures
            for up in closure.upscope
                local = @find up.name
                if local?
                    up.slot = local.slot
                else
                    @upscope.push up

    find: (name) ->
        for local in @args
            if local.name == name
                return local
        for local in @locals
            if local.name == name
                return local
        return null

    define: (name) ->
        local = @find name
        return local if local?
        @locals.push local = {name, slot:genSym()}
        return local

    lookup: (name) ->
        local = @find name
        return local if local?
        return @parent.lookup(name) if @parent?
        @upscope.push up = {name, slot:null}
        return up

    tempvar: () ->
        @locals.push local = {name:null, slot:genSym()}
        return local

    push: (string) ->
        @block.push string

    build: () ->
        out = ""
        out += "var #{(slots @locals).join ', '};" if @locals.length > 0
        for block in @block
            out += block()
        return out

lastTmp = 1
genSym = () -> "v#{lastTmp += 1}"

slot  = (variable) -> variable.slot
slots = (variables) -> (variable.slot for variable in variables)
