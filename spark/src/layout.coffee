{bc, teh} = env
{px} = teh

isFunction = (obj) -> obj instanceof Function

console.log isFunction env.teh.Box(10, 10, 10)

fsz = 16

textbox = (bc, text, color='black') ->
    font = "#{fsz}px sans-serif"
    bc.font = font
    offsets = [0]
    for i in [1...text.length+1]
        offsets.push bc.measureText(text[0...i]).width
    width = bc.measureText(text).width
    box = teh.Box(width, 3/4*fsz, 1/4*fsz)
    box.paint = (bc) ->
        bc.fillStyle = color
        bc.font = font
        bc.fillText(text, @x, @y+@shift)
    box.offsets = offsets
    return box

black = () ->
    box = teh.Box(fsz, 3/4*fsz, 1/4*fsz)
    box.paint = (bc) ->
        bc.fillRect @x, @y-@height, @width, @height+@depth
    return box

vspace = () ->
    glue = teh.Glue(fsz * 0.2)
    return glue

hrule = () ->
    glue = teh.Glue(fsz * 0.5)
    glue.paint = (bc, vertical) ->
        {width, height, depth} = @getsize(vertical)
        bc.fillRect @x, @y-height+3, width, 1
    return glue

shifted = (box) ->
    box.shift += fsz * 0.25
    box.width -= 2
    return box

narrowed = (box) ->
    box.width -= 2
    return box

sample = env.readBlipFile "samples/stdlib.blip"

console.log sample
console.log sample.constructor.name

vbox_context = (indent=false, align=teh.alignTop) ->
    return {
        vlist: []
        hlist: []
        hpush: (item) ->
            if @hlist.length > 0
                @hlist.push teh.Glue(5)
            @hlist.push item
        vpush: (item) ->
            if @vlist.length > 0
                @vlist.push vspace()
            @vlist.push item
        newline: () ->
            @vlist.push teh.hbox(@hlist)
            @hlist = []
            if indent
                @hlist.push teh.Glue(10)
            @vlist.push vspace()
        freeze: () ->
            if @hlist.length == 0
                @hlist.push teh.Box(10, 10, 10)
            @vlist.push teh.hbox(@hlist)
            return teh.vbox(@vlist, align)
    }

build_layout = (context, node, inline=false) ->
    if env.isMark(node, 'cr')
        return context.newline()
    if env.isList(node, "let") and node.length == 2
        context2 = vbox_context(true, teh.alignFirst)
        build_layout context2, node.list[0]
        context2.hpush textbox(bc, "←", 'purple')
        build_layout context2, node.list[1], true
        return context.hpush context2.freeze()
    if env.isList(node, "let") and node.length > 1
        context2 = vbox_context(true, teh.alignFirst)
        build_layout context2, node.list[0]
        context2.hpush textbox(bc, "←", 'purple')
        for subnode in node.list[1...]
            build_layout context2, subnode, true
        return context.hpush context2.freeze()
    if env.isList(node, "infix")
        context2 = vbox_context(true, teh.alignFirst)
        for subnode in node.list
            build_layout context2, subnode
        return context.hpush context2.freeze()
    if env.isList(node, "cond") and node.length > 0
        context2 = vbox_context(false, teh.alignFirst)
        label = 'if'
        for subnode in node.list
            if env.isList(subnode, 'else')
                build_layout context2, subnode
            else if env.isList(subnode)
                context3 = vbox_context(true, teh.alignFirst)
                context3.hpush textbox(bc, label, 'purple')
                for subsubnode in subnode.list
                    build_layout context3, subsubnode
                label = 'elif'
                context2.vpush context3.freeze()
            else
                build_layout context2, subnode
        return context.hpush context2.freeze()
    switch node.constructor.name
        when "List"
            if inline
                if node.label != ""
                    context.hpush textbox(bc, node.label, 'purple')
                for subnode in node.list
                    build_layout context, subnode
            else
                context2 = vbox_context(true, teh.alignFirst)
                if node.label != ""
                    context2.hpush textbox(bc, node.label, 'purple')
                for subnode in node.list
                    build_layout context2, subnode
                context.hpush context2.freeze()
        when "Text"
            if node.label == "string"
                context.hpush teh.hbox([
                    textbox(bc, '"', 'green')
                    k = textbox(bc, node.text, 'green')
                    textbox(bc, '"', 'green')
                ])
            else if node.label != ""
                context.hpush teh.hbox([
                    textbox(bc, node.label + '"', 'gray')
                    k = textbox(bc, node.text, 'gray')
                    textbox(bc, '"', 'gray')
                ])
            else
                context.hpush k = textbox(bc, node.text)
            k.source = node
        else
            context.hpush textbox(bc, node.label)
    return

#env.draw()
env.draw = () ->
    env.clearScreen()

    scope = {
        font_size: 16
        font_family: "sans-serif"
    }
    context = vbox_context()
    root  = sample

    for node in root.list
        build_layout(context, node)
    box = context.freeze()

#    switch root.constructor.name
#        when "List"
#            console.log 'root'
#        else
#            console.log 'weird'

    #build(sample, scope)


    #[ vbox
    #    [
    #        hbox
    #        text("The power of")
    #        text("T")
    #        text("E")
    #        text("X-style layouting")
    #    ]
    #    vspace()
    #    [
    #        hbox
    #        textbox("Inside the")
    #        [
    #            vbox
    #            text("visual")
    #            text("pisual")
    #            text("programming")
    #            text("editor")
    #        ]
    #    ]
    #    vspace()
    #    [
    #        hbox
    #        black()
    #        hspace()
    #        text("hubbbububub")
    #        hspace()
    #        align_by [
    #            vbox
    #            text("bakabaka")
    #            hline = hrule()
    #            text("bak")
    #        ], hline
    #    ]
    #]

    #list = [
    #    teh.hbox [
    #        textbox(bc, "The power of ")
    #        narrowed textbox(bc, "T")
    #        shifted textbox(bc, "E")
    #        textbox(bc, "X-style layouting.")
    #    ]
    #    vspace()
    #    teh.hbox [
    #        textbox(bc, "Inside the ")
    #        teh.vbox [
    #            textbox(bc, "visual")
    #            textbox(bc, "pisual")
    #            textbox(bc, "programming")
    #            textbox(bc, "editor")
    #        ]
    #    ]
    #    vspace()
    #    teh.hbox [
    #        black()
    #        teh.Glue(10)
    #        textbox(bc, "hubbbububub")
    #        teh.Glue(10)
    #        teh.vbox [
    #            textbox(bc, "bakabaka")
    #            hline = hrule()
    #            textbox(bc, "bak")
    #        ], () -> hline.y + fsz*0.5
    #    ]
    #]
    #box = teh.vbox(list, teh.alignTop)

    box.x = 10
    box.y = 10

    #box.paintMetrics(bc)
    box.paint(bc)

    {x, y} = env.mouse
    bc.fillRect(x-3, y-3, 5, 5)

    best = {node:null, x:0, y:0, i:0, low:100}
    traverse box, (node) ->
        {x:p_x, y:p_y} = node.absolutePosition(node.x, node.y)
        {width, height, depth} = node.getsize()
        d_x = (x - p_x) - clamp(x - p_x, 0, width)
        d_y = (y - p_y) - clamp(y - p_y, -height, depth)
        cd = d_x*d_x + d_y*d_y
        return unless node.offsets? and node.source?
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
    if best.node?
        bc.fillStyle = 'blue'
        bc.fillStyle = 'red'
        bc.fillRect(best.x, best.y-best.height, 1, best.height+best.depth)
        bc.fillStyle = 'black'

        for node in aboveCarets(best.node)
            {x, y} = node.absolutePosition(0)
            bc.save()
            bc.translate(x, y)
            node.paintMetrics(bc)
            bc.restore()

        for node in belowCarets(best.node)
            {x, y} = node.absolutePosition(0)
            bc.save()
            bc.translate(x, y)
            node.paintMetrics(bc)
            bc.restore()

    window.requestAnimationFrame env.draw

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
