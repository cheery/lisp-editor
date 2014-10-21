{teh}   = env

env.keyboard = (code) ->
    console.log code

vbox_context = (scope, indent=false, align=teh.alignTop) ->
    return {
        scope: scope
        vlist: []
        hlist: []
        hpush: (item) ->
            if @hlist.length > 0
                @hlist.push teh.glue(5)
            @hlist.push item
        vpush: (item) ->
            if @vlist.length > 0
                @vlist.push @scope.vspace()
            @vlist.push item
        newline: () ->
            @vlist.push teh.hbox(@hlist)
            @hlist = []
            if indent
                @hlist.push teh.glue(10)
            @vlist.push @scope.vspace()
        freeze: () ->
            if @hlist.length == 0
                @hlist.push teh.box(10, 10, 10)
            @vlist.push teh.hbox(@hlist)
            return teh.vbox(@vlist, align)
    }

build_layout = (ctx, node, inline=false) ->
    scope = ctx.scope
    if env.isMark(node, 'cr')
        return ctx.newline()
    if env.isList(node, "let") and node.length == 2
        stx = vbox_context(scope, true, teh.alignFirst)
        build_layout stx, node.list[0]
        stx.hpush scope.text("←", 'purple')
        build_layout stx, node.list[1], true
        return ctx.hpush stx.freeze()
    if env.isList(node, "let") and node.length > 1
        stx = vbox_context(scope, true, teh.alignFirst)
        build_layout stx, node.list[0]
        stx.hpush scope.text("←", 'purple')
        for subnode in node.list[1...]
            build_layout stx, subnode, true
        return ctx.hpush stx.freeze()
    if env.isList(node, "infix")
        stx = vbox_context(scope, true, teh.alignFirst)
        for subnode in node.list
            build_layout stx, subnode
        return ctx.hpush stx.freeze()
    if env.isList(node, "cond") and node.length > 0
        stx = vbox_context(scope, true, teh.alignFirst)
        label = 'if'
        for subnode in node.list
            if env.isList(subnode, 'else')
                build_layout stx, subnode
            else if env.isList(subnode)
                rtx = vbox_context(scope, true, teh.alignFirst)
                rtx.hpush scope.text(label, 'purple')
                for subsubnode in subnode.list
                    build_layout rtx, subsubnode
                label = 'elif'
                stx.vpush rtx.freeze()
            else
                build_layout stx, subnode
        return ctx.hpush stx.freeze()
    switch node.constructor.name
        when "List"
            if inline
                if node.label != ""
                    ctx.hpush scope.text(node.label, 'purple')
                for subnode in node.list
                    build_layout ctx, subnode
            else
                context2 = vbox_context(scope, true, teh.alignFirst)
                if node.label != ""
                    context2.hpush scope.text(node.label, 'purple')
                for subnode in node.list
                    build_layout context2, subnode
                ctx.hpush context2.freeze()
        when "Text"
            if node.label == "string"
                ctx.hpush teh.hbox([
                    scope.text('"', 'green')
                    k = scope.text(node.text, 'green')
                    scope.text('"', 'green')
                ])
            else if node.label != ""
                ctx.hpush teh.hbox([
                    scope.text(node.label + '"', 'gray')
                    k = scope.text(node.text, 'gray')
                    scope.text('"', 'gray')
                ])
            else
                ctx.hpush k = scope.text(node.text)
            k.source = node
        else
            ctx.hpush scope.text(node.label)
    return null

env.draw = () ->
    env.clearScreen()
    scope = {
        font_size: 14
        font_family: "sans-serif"
        bc: env.bc
        vspace: () -> teh.glue(@font_size * 0.2)
        text: (text, color='black') ->
            font = "#{@font_size}px sans-serif"
            @bc.font = font
            offsets = [0]
            for i in [1...text.length+1]
                offsets.push @bc.measureText(text[0...i]).width
            width = @bc.measureText(text).width
            box = teh.box(width, 3/4*@font_size, 1/4*@font_size)
            box.paint = (bc) ->
                bc.fillStyle = color
                bc.font = font
                bc.fillText(text, @screenX, @screenY)
            box.offsets = offsets
            return box
    }
    ctx = vbox_context(scope)
    root = env.document

    for node in root.list
        build_layout(ctx, node)
    box = ctx.freeze()

    if Math.sin(Date.now()/1000*2) < 0
        env.bc.fillStyle = 'black'
        env.bc.fillRect 10+0,40, 5, 10

#    box = teh.hbox([
#        teh.caret(null)
#        teh.box(10, 10, 10)
#        teh.caret(null)
#        teh.caret(null)
#        teh.glue(10, teh.dimen(0), teh.dimen(1, 1))
#        teh.caret(null)
#        teh.caret(null)
#        teh.vbox([
#            teh.caret(null)
#            teh.box(10, 10, 10)
#            teh.caret(null)
#            teh.glue(10, teh.dimen(0), teh.dimen(0, 0))
#            teh.caret(null)
#            teh.box(20, 10, 10)
#            teh.caret(null)
#        ], teh.alignLast)
#        teh.caret(null)
#    ])

    box.reflow(50, 50 + box.trueHeight(box.vertical))
    #box.paintMetrics(env.bc)
    box.paint(env.bc)

    {x, y} = env.mouse
    best = {node:null, x:0, y:0, i:0, low:100}
    traverse box, (node) ->
        return unless node.offsets? and node.source?
        {width, height, depth} = node.getsize()
        p_x = node.screenX
        p_y = node.screenY
        d_x = (x - p_x) - clamp(x - p_x, 0, width)
        d_y = (y - p_y) - clamp(y - p_y, -height, depth)
        cd = d_x*d_x + d_y*d_y
        for i in [0...node.offsets.length]
            k = x - node.offsets[i] - p_x
            if k*k + cd <= best.low
                best.source = node.source
                best.node = node
                best.x = p_x + node.offsets[i]
                best.y = p_y
                best.height = height
                best.depth = depth
                best.i = i
                best.low = cd + k*k
        return null

    bc = env.bc
    if best.node?
        bc.fillStyle = 'blue'
        bc.fillStyle = 'red'
        bc.fillRect(best.x, best.y-best.height, 1, best.height+best.depth)
        bc.fillStyle = 'black'

        for node in aboveCarets(best.node)
            node.paintMetrics(bc)
        for node in belowCarets(best.node)
            node.paintMetrics(bc)

    window.requestAnimationFrame(env.draw)
#isFunction = (obj) -> obj instanceof Function
#
#
#black = () ->
#    box = teh.Box(fsz, 3/4*fsz, 1/4*fsz)
#    box.paint = (bc) ->
#        bc.fillRect @x, @y-@height, @width, @height+@depth
#    return box
#
#
#hrule = () ->
#    glue = teh.Glue(fsz * 0.5)
#    glue.paint = (bc, vertical) ->
#        {width, height, depth} = @getsize(vertical)
#        bc.fillRect @x, @y-height+3, width, 1
#    return glue
#
#shifted = (box) ->
#    box.shift += fsz * 0.25
#    box.width -= 2
#    return box
#
#narrowed = (box) ->
#    box.width -= 2
#    return box

aboveCarets = (node) ->
    while node.parent?
        m = node
        node = node.parent
        while node? and (node.constructor.name != 'VBox' or node.contents.indexOf(m) == 0)
            m = node
            node = node.parent
        return [] unless node?
        getBottoms = (u) ->
            if u.constructor.name == 'VBox'
                i = u.contents.length-1
                while i >= 0
                    bottoms = getBottoms u.contents[i]
                    return bottoms if bottoms.length > 0
                    i -= 1
                return []
            else if u.constructor.name == 'HBox'
                bottoms = []
                for o in u.contents
                    bottoms = bottoms.concat(getBottoms o)
                return bottoms
            else if u.offsets? and u.source?
                return [u]
            else
                return []
        i = node.contents.indexOf(m) - 1
        while i >= 0
            u = node.contents[i]
            bottoms = getBottoms u
            return bottoms if bottoms.length > 0
            i -= 1
    return []

belowCarets = (node) ->
    while node.parent?
        m = node
        node = node.parent
        while node? and (node.constructor.name != 'VBox' or node.contents.indexOf(m) == node.contents.length - 1)
            m = node
            node = node.parent
        return [] unless node?
        getBottoms = (u) ->
            if u.constructor.name == 'VBox'
                i = 0
                while i <= u.contents.length-1
                    bottoms = getBottoms u.contents[i]
                    return bottoms if bottoms.length > 0
                    i += 1
                return []
            else if u.constructor.name == 'HBox'
                bottoms = []
                for o in u.contents
                    bottoms = bottoms.concat(getBottoms o)
                return bottoms
            else if u.offsets and u.source?
                return [u]
            else
                return []
        i = node.contents.indexOf(m) + 1
        while i <= node.contents.length-1
            u = node.contents[i]
            bottoms = getBottoms u
            return bottoms if bottoms.length > 0
            i += 1
    return []

traverse = (node, fn) ->
    fn(node)
    return unless node.contents?
    for subnode in node.contents
        traverse(subnode, fn)
    return null

clamp = (x, low, high) -> return Math.min(Math.max(x, low), high)
