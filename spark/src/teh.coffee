class Box
    constructor: (@width, @height, @depth, @shift) ->
        @parent = null
        @x = 0
        @y = 0
        @vertical = false

    trueWidth: (vertical) ->
        return @width + @shift if vertical
        return @width

    trueHeight: (vertical) ->
        return @height if vertical
        return @height - @shift

    trueDepth: (vertical) ->
        return @depth if vertical
        return @depth + @shift

    paintMetrics: (bc) ->
        {width, height, depth} = @getsize()
        bc.strokeStyle = 'black'
        paintCircle(bc, @x, @y, 2)
        bc.beginPath()
        bc.moveTo(@x, @y)
        bc.lineTo(@x+width, @y)
        bc.stroke()
        bc.strokeRect(@x, @y-height, width, height+depth)

    paint: (bc) ->
        # an example, not used
        #bc.fillStyle = 'black'
        #{width, height, depth} = @getsize()
        #bc.fillRect(@x, @y-height, width, height+depth)

    getsize: () ->
        return {
            width: @trueWidth(@vertical)
            height: @trueHeight(@vertical)
            depth: @trueDepth(@vertical)
        }

    absolutePosition: (x=@x, y=@y) ->
        return @parent.absoluteChildPosition(x, y) if @parent?
        return {x, y}

class Glue
    constructor: (@size, @shrink, @stretch) ->
        @parent = null
        @x = 0
        @y = 0
        @strain = 0
        @computedSize = @size
        @vertical = false

    trueWidth: (vertical) ->
        return 0 if vertical
        return @computedSize

    trueHeight: (vertical) ->
        return 0

    trueDepth: (vertical) ->
        return @computedSize if vertical
        return 0

    computeSize: (pc) ->
        @strain = 0
        @computedSize = @size
        if pc.x < 0 and @shrink.fill == pc.fill
            @computedSize = @size + @shrink.x * pc.x
            @strain = pc.x
        if pc.x > 0 and @stretch.fill == pc.fill
            @computedSize = @size + @stretch.x * pc.x
            @strain = pc.x

    getsize: () ->
        if @vertical
            return {
                width:  @parent.width
                height: 0
                depth:  @computedSize
            }
        else
            return {
                width:  @computedSize
                height: @parent.height
                depth:  @parent.depth
            }

    paintMetrics: (bc) ->
        if @strain <= 0
            w = -@strain
            bc.strokeStyle = rgb(w, 1-w, 0)
        else
            w = @strain
            bc.strokeStyle = rgb(0, 1-w, w)
        paintCircle(bc, @x, @y, 2)
        bc.beginPath()
        bc.moveTo(@x, @y)
        unless @vertical
            bc.lineTo(@x+@computedSize, @y)
        else
            bc.lineTo(@x, @y+@computedSize)
        bc.stroke()

    paint: (bc) ->
        # an example, not used.
        #        {width, height, depth} = @getsize()
        #        if vertical
        #            bc.fillStyle = '#eea'
        #            bc.fillRect @x, @y-height, width, height+depth
        #        else
        #            bc.fillStyle = '#aea'
        #            bc.fillRect @x, @y-height, width, height+depth

    absolutePosition: (x=0, y=0) ->
        return @parent.absoluteChildPosition(x, y) if @parent?
        return {x, y}

class HBox
    constructor: (@contents, @glue, @width, @height, @depth, @shift) ->
        attachNodes(@, false)
        @parent = null
        @x = 0
        @y = 0
        @vertical = false

    trueWidth: (vertical) ->
        return @width + @shift if vertical
        return @width

    trueHeight: (vertical) ->
        return @height if vertical
        return @height - @shift

    trueDepth: (vertical) ->
        return @depth if vertical
        return @depth + @shift

    getsize: () ->
        return {
            width: @trueWidth(@vertical)
            height: @trueHeight(@vertical)
            depth: @trueDepth(@vertical)
        }

    paintMetrics: (bc) ->
        {width, height, depth} = @getsize()
        bc.strokeStyle = "gray"
        bc.strokeRect(@x, @y-height, width, height+depth)
        bc.save()
        bc.translate(@x, @y)
        for box in @contents
            box.paintMetrics(bc)
        bc.restore()

    paintBackground: (bc) ->

    paint: (bc) ->
        @paintBackground(bc)
        bc.save()
        bc.translate(@x, @y)
        for box in @contents
            box.paint(bc, false)
        bc.restore()

    absolutePosition: (x=0, y=0) ->
        return @parent.absoluteChildPosition(x, y) if @parent?
        return {x, y}

    absoluteChildPosition: (x=0, y=0) ->
        x += @x
        y += @y
        return @parent.absoluteChildPosition(x, y) if @parent?
        return {x, y}

class VBox
    constructor: (@contents, @glue, @width, @vsize, @anchor, @shift) ->
        attachNodes(@, true)
        @parent = null
        @x = 0
        @y = 0
        @vertical = false

    trueWidth: (vertical) ->
        return @width + @shift if vertical
        return @width

    trueHeight: (vertical) ->
        return @anchor if vertical
        return @anchor - @shift

    trueDepth: (vertical) ->
        return @vsize - @anchor if vertical
        return @vsize - @anchor + @shift

    getsize: () ->
        return {
            width: @trueWidth(@vertical)
            height: @trueHeight(@vertical)
            depth: @trueDepth(@vertical)
        }

    paintMetrics: (bc) ->
        {width, height, depth} = @getsize()
        bc.strokeStyle = "gray"
        bc.strokeRect(@x, @y-height, width, height+depth)
        bc.save()
        bc.translate(@x, @y-@anchor)
        for box in @contents
            box.paintMetrics(bc)
        bc.restore()

    paintBackground: (bc, vertical) ->

    paint: (bc, vertical) ->
        @paintBackground(bc, vertical)
        bc.save()
        bc.translate(@x, @y-@anchor)
        for box in @contents
            box.paint(bc)
        bc.restore()

    absolutePosition: (x=0, y=0) ->
        return @parent.absoluteChildPosition(x, y) if @parent?
        return {x, y}

    absoluteChildPosition: (x=0, y=0) ->
        x += @x
        y += @y - @trueHeight(@vertical)
        return @parent.absoluteChildPosition(x, y) if @parent?
        return {x, y}

attachNodes = (container, vertical) ->
    for node in container.contents
        attachNode(container, node, vertical)

attachNode = (container, node, vertical) ->
    if node.parent?
        throw "you should not reuse box nodes"
    node.parent = container
    node.vertical = vertical

nativeWidth  = (nodes) ->
    width = 0
    width += a.trueWidth(false) for a in nodes
    return width

nativeHeight = (nodes) ->
    height = 0
    height = Math.max(height, a.trueHeight(false)) for a in nodes
    return height

nativeDepth  = (nodes) ->
    depth = 0
    depth = Math.max(depth, a.trueDepth(false)) for a in nodes
    return depth

nativeVWidth = (nodes) ->
    width = 0
    width = Math.max(width, a.trueWidth(true)) for a in nodes
    return width

nativeVSize  = (nodes) ->
    vsize = 0
    vsize += a.trueHeight(true) + a.trueDepth(true) for a in nodes
    return vsize

packHBox = (nodes, to=null) ->
    width  = nativeWidth(nodes)
    height = nativeHeight(nodes)
    depth  = nativeDepth(nodes)
    if to?
        glue  = glueSum(nodes, to - width)
        width = to
    else
        glue = px(0)
    horizontalLayout(nodes, glue)
    return new HBox(nodes, glue, width, height, depth, 0)

horizontalLayout = (nodes, pc) ->
    x = 0
    y = 0
    for node in nodes
        node.computeSize(pc) if node.computeSize?
        node.x = x
        node.y = y
        x += node.trueWidth(false)
    return null

alignTop    = ((vbox) -> 0)
alignBottom = ((vbox) -> vbox.vsize)
alignFirst  = ((vbox) -> vbox.contents[0].y)
alignLast   = ((vbox) -> vbox.contents[vbox.contents.length-1].y)
alignMiddle = ((vbox) -> vbox.contents[Math.floor vbox.contents.length/2].y)

packVBox = (nodes, valign=alignFirst, to=null) ->
    width = nativeVWidth(nodes)
    vsize = nativeVSize(nodes)
    if to?
        glue  = glueSum(nodes, to - vsize)
        vsize = to
    else
        glue = px(0)
    verticalLayout(nodes, glue)
    vbox = new VBox(nodes, glue, width, vsize, 0, 0)
    vbox.anchor = valign(vbox)
    return vbox

verticalLayout = (nodes, pc) ->
    x = 0
    y = 0
    for node in nodes
        node.computeSize(pc) if node.computeSize?
        height = node.trueHeight(true)
        depth  = node.trueDepth(true)
        node.x = x
        node.y = y + height
        y += height + depth
    return null

glueSum = (nodes, x) ->
    stretch = px(0)
    shrink  = px(0)
    for node in nodes
        dimAccum(stretch, node.stretch) if node.stretch?
        dimAccum(shrink, node.shrink)   if node.shrink?
    pc = stretch
    pc = shrink if x < 0
    if pc.x != 0
        pc.x = x / pc.x
        pc.y = pc.x
        pc.x = clamp(pc.x, -1, +1) if pc.fill == 0
    else
        pc.x = 0
        pc.y = x
    return pc

dimAccum = (accum, dim) ->
    if accum.fill == dim.fill
        accum.x += dim.x
    else if accum.fill < dim.fill
        accum.fill = dim.fill
        accum.x    = dim.x

px = (x, fill=0) -> {x, fill}

env.teh = {
    Box:  (width, height, depth, shift=0) -> new Box(width, height, depth, shift)
    Glue: (size, shrink=px(0), stretch=px(0)) -> new Glue(size, shrink, stretch)
    vbox: packVBox
    hbox: packHBox
    nativeWidth
    nativeHeight
    nativeDepth
    nativeVWidth
    nativeVSize
    glueSum
    alignTop
    alignBottom
    alignFirst
    alignLast
    alignMiddle
    px
}

rgb = (r, g, b) ->
    return '#' + hexchannel(r) + hexchannel(g) + hexchannel(b)

hexchannel = (x) ->
    x = clamp(x, 0, 1)
    x = Math.floor(x*255).toString(16)
    x = "0" + x if x.length == 1
    return x

clamp = (x, min, max) -> Math.max(min, Math.min(max, x))

paintCircle = (bc, x, y, radius) ->
    bc.beginPath()
    bc.arc(x, y, radius, 0, 2*Math.PI, true)
    bc.stroke()

if false
    env.relayout = () ->
        teh  = {px} = env.teh
        root = teh.hbox [
            teh.Box(200, 100, 100)
            teh.Glue(10, px(5), px(5))
            teh.Box(20, 10, 10)
            teh.Glue(20, px(20), px(5))
            teh.vbox [
                teh.Glue(10, px(0), px(1, 1))
                teh.hbox [
                    teh.Glue(10, px(0), px(1, 1))
                    teh.Box(5, 10, 10, 0)
                ], 30
                teh.Glue(10, px(2), px(2))
                mid = teh.Box(30, 2, 2)
                teh.Glue(10, px(2), px(2))
                teh.Box(30, 10, 10)
                teh.Glue(10, px(0), px(1, 1))
                teh.Box(30, 10, 10)
            ], ((vbox) -> mid.y), 150
            teh.Glue(10, px(1), px(5))
            teh.Box(20, 10, 10)
        ], 300 + Math.sin(Date.now()/1000)*30
        return root

    env.draw = () ->
        env.clearScreen()

        root = env.relayout()
        root.x = 150
        root.y = 150
        root.paint(env.bc)
        root.paintMetrics(env.bc)
        window.requestAnimationFrame(env.draw)
