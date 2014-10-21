class Box
    constructor: (@width, @height, @depth, @shift) ->
        @parent = null
        @x = 0
        @y = 0
        @screenX = 0
        @screenY = 0
        @vertical = false
        @guide = false

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
            width:  @trueWidth(@vertical)
            height: @trueHeight(@vertical)
            depth:  @trueDepth(@vertical)
        }

    reflow: (x, y) ->
        @screenX = @x+x
        @screenY = @y+y

    paintMetrics: (bc) ->
        {width, height, depth} = @getsize()
        bc.fillStyle = 'black'
        bc.strokeStyle = 'black'
        bc.fillRect(@screenX, @screenY, width, 1)
        bc.strokeRect(@screenX, @screenY-height, width, height+depth)

    paint: (bc) ->

class Glue
    constructor: (@size, @shrink, @stretch) ->
        @parent = null
        @x = 0
        @y = 0
        @screenX = 0
        @screenY = 0
        @strain = 0
        @computedSize = @size
        @vertical = false
        @guide = true

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

    reflow: (x, y) ->
        @screenX = @x+x
        @screenY = @y+y

    paintMetrics: (bc) ->
        if @strain <= 0
            w = -@strain
            bc.strokeStyle = rgb(w, 1-w, 0)
        else
            w = @strain
            bc.strokeStyle = rgb(0, 1-w, w)
        bc.beginPath()
        bc.arc(@screenX, @screenY, 2, 0, 2*Math.PI, true)
        bc.stroke()
        bc.beginPath()
        bc.moveTo(@screenX, @screenY)
        unless @vertical
            bc.lineTo(@screenX+@computedSize, @screenY)
        else
            bc.lineTo(@screenX, @screenY+@computedSize)
        bc.stroke()

    paint: (bc) ->

class Caret
    constructor: (@source, @index) ->
        @parent = null
        @x = 0
        @y = 0
        @screenX = 0
        @screenY = 0
        @vertical = false
        @guide = true

    trueWidth: (vertical) ->
        return 0

    trueHeight: (vertical) ->
        return 0

    trueDepth: (vertical) ->
        return 0

    getsize: () ->
        if @vertical
            return {
                width:  @parent.width
                height: 0
                depth:  1
            }
        else
            return {
                width:  1
                height: @parent.height
                depth:  @parent.depth
            }

    reflow: (x, y) ->
        @screenX = @x+x
        @screenY = @y+y

    paintMetrics: (bc) ->
        {width, height, depth} = @getsize()
        bc.fillStyle = "#ff0000"
        bc.fillRect(@screenX, @screenY-height, width, height+depth)

    paint: (bc) ->

class HBox
    constructor: (@contents, @glue, @width, @height, @depth, @shift) ->
        attachNodes(@, false)
        @parent = null
        @x = 0
        @y = 0
        @screenX = 0
        @screenY = 0
        @vertical = false
        @guide = false

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

    reflow: (x, y) ->
        @screenX = @x+x
        @screenY = @y+y
        sx = if @vertical then 0 else @shift
        sy = if @vertical then @shift else 0
        for box in @contents
            box.reflow(@screenX+sx, @screenY+sy)

    paintMetrics: (bc) ->
        {width, height, depth} = @getsize()
        bc.strokeStyle = "gray"
        bc.strokeRect(@screenX, @screenY-height, width, height+depth)
        for box in @contents
            box.paintMetrics(bc)

    paintBackground: (bc, vertical) ->

    paint: (bc) ->
        @paintBackground(bc)
        for box in @contents
            box.paint(bc)

class VBox
    constructor: (@contents, @glue, @width, @vsize, @anchor, @shift) ->
        attachNodes(@, true)
        @parent = null
        @x = 0
        @y = 0
        @screenX = 0
        @screenY = 0
        @vertical = false
        @guide = false

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

    reflow: (x, y) ->
        @screenX = @x+x
        @screenY = @y+y
        sx = if @vertical then 0 else @shift
        sy = if @vertical then @shift else 0
        for box in @contents
            box.reflow(@screenX+sx, @screenY+sy-@anchor)

    paintMetrics: (bc) ->
        {width, height, depth} = @getsize()
        bc.strokeStyle = "gray"
        bc.strokeRect(@screenX, @screenY-height, width, height+depth)
        for box in @contents
            box.paintMetrics(bc)

    paintBackground: (bc, vertical) ->

    paint: (bc, vertical) ->
        @paintBackground(bc, vertical)
        for box in @contents
            box.paint(bc)

attachNodes = (container, vertical) ->
    container.boxes = []
    for node in container.contents
        if node.parent?
            throw "you should not reuse box nodes"
        node.parent = container
        node.vertical = vertical
        unless node.guide
            container.boxes.push node

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

alignTop    = ((vbox) -> 0)
alignBottom = ((vbox) -> vbox.vsize)
alignFirst  = ((vbox) -> vbox.boxes[0].y)
alignLast   = ((vbox) -> vbox.boxes[vbox.boxes.length-1].y)
alignMiddle = ((vbox) -> vbox.boxes[Math.floor vbox.boxes.length/2].y)

hbox = (nodes, to=null) ->
    width  = nativeWidth(nodes)
    height = nativeHeight(nodes)
    depth  = nativeDepth(nodes)
    if to?
        pc = adjustGlue(nodes, to - width)
        width = to
    else
        pc = dimen(0)
    x = 0
    y = 0
    for node in nodes
        node.computeSize(pc) if node.computeSize?
        node.x = x
        node.y = y
        x += node.trueWidth(false)
    return new HBox(nodes, pc, width, height, depth, 0)


vbox = (nodes, valign=alignFirst, to=null) ->
    width = nativeVWidth(nodes)
    vsize = nativeVSize(nodes)
    if to?
        pc = adjustGlue(nodes, to - vsize)
        vsize = to
    else
        pc = dimen(0)
    x = 0
    y = 0
    for node in nodes
        node.computeSize(pc) if node.computeSize?
        height = node.trueHeight(true)
        depth  = node.trueDepth(true)
        node.x = x
        node.y = y + height
        y += height + depth
    box = new VBox(nodes, pc, width, vsize, 0, 0)
    box.anchor = valign(box)
    return box

adjustGlue = (nodes, x) ->
    pc = dimen(0)
    mode = if x < 0 then 'shrink' else 'stretch'
    for node in nodes
        dimenAccum(pc, node[mode]) if node[mode]?
    if pc.x != 0
        pc.x = x / pc.x
        pc.e = pc.x
        pc.x = clamp(pc.x, -1, +1) if pc.fill == 0
    else
        pc.x = 0
        pc.e = x
    pc.badness = Math.abs(pc.e - pc.x)
    return pc

dimenAccum = (accum, dim) ->
    if accum.fill == dim.fill
        accum.x += dim.x
    else if accum.fill < dim.fill
        accum.fill = dim.fill
        accum.x    = dim.x

dimen = (x, fill=0) -> {x, fill}

rgb = (r, g, b) ->
    return '#' + hexchannel(r) + hexchannel(g) + hexchannel(b)

hexchannel = (x) ->
    x = clamp(x, 0, 1)
    x = Math.floor(x*255).toString(16)
    x = "0" + x if x.length == 1
    return x

clamp = (x, min, max) -> Math.max(min, Math.min(max, x))

env.teh = teh = {
    box: (width, height, depth, shift=0) -> new Box(width, height, depth, shift)
    glue: (size, shrink=dimen(0), stretch=dimen(0)) -> new Glue(size, shrink, stretch)
    caret: (source, index=0) -> new Caret(source, index)
    vbox
    hbox
    nativeWidth
    nativeHeight
    nativeDepth
    nativeVWidth
    nativeVSize
    adjustGlue
    alignTop
    alignBottom
    alignFirst
    alignLast
    alignMiddle
    dimen
}

if false
    env.draw = () ->
        env.clearScreen()

        if Math.sin(Date.now()/1000*2) < 0
            env.bc.fillStyle = 'black'
            env.bc.fillRect 10+0,40, 5, 10

        box = teh.hbox([
            teh.caret(null)
            teh.box(10, 10, 10)
            teh.caret(null)
            teh.caret(null)
            teh.glue(10, dimen(0), dimen(1, 1))
            teh.caret(null)
            teh.caret(null)
            teh.vbox([
                teh.caret(null)
                teh.box(10, 10, 10)
                teh.caret(null)
                teh.glue(10, dimen(0), dimen(0, 0))
                teh.caret(null)
                teh.box(20, 10, 10)
                teh.caret(null)
            ], teh.alignLast, 110)
            teh.caret(null)
        ], 150)

        box.reflow(50, 50 + box.height)
        box.paintMetrics(env.bc)

        window.requestAnimationFrame(env.draw)
