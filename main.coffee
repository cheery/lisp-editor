defaultStyle = {
    fontName: "sans-serif"
    fontSize: 16
    topPadding: 0
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0
    spacing: 5
    indent: 10
    verticalSpacing: 0
    color: "black"
    selection: "blue"
    #background: "green"
    #border: "red"
}

buildStyle = (parent, style) ->
    for name, value of parent
        style[name] ?= value
    return style

labelStyle = buildStyle defaultStyle, {
    color: "purple"
    fontSize: 12
}

condStyle = buildStyle defaultStyle, {
    indent: 0
    selection: "yellow"
}

keyNames = {
     8: "backspace"
     9: "tab"
    13: "ret"
    16: "shift"
    17: "ctrl"
    18: "alt"
    27: "esc"
    46: "del"
}

addFrame = (container, node) ->
    if isMark(node, 'cr')
        return container.newline(node)
    #    container.push frame = newFrame node, container.style
    if isList(node, 'cond')
        container.push frame = newFrame node, condStyle
        first = true
        for item in node.list
            frame.newline() unless first
            if isList(item, 'else')
                row = newFrame item, defaultStyle
                row.push newDeco("else", labelStyle)
                for subitem in item.list
                    addFrame row, subitem
            else if isList(item)
                row = newFrame item, defaultStyle
                row.push newDeco("else", labelStyle) unless first
                row.push newDeco("if", labelStyle)
                for subitem in item.list
                    addFrame row, subitem
            else
                addFrame frame, item
            frame.push row
            first = false
    else if isList(node, 'infix')
        container.push frame = newFrame node, buildStyle defaultStyle, {
            selection: "green"
        }
        #frame.push newDeco("{", labelStyle)
        addFrame frame, item for item in node.list
        #frame.push newDeco("}", labelStyle)
    else if isList(node)
        container.push frame = newFrame node, buildStyle defaultStyle, {
            selection: "blue"
        }
        if node.label?
            frame.push newDeco(node.label, labelStyle)
        for item in node.list
            addFrame(frame, item)
    else if isText(node, 'int')
        container.push frame = newFrame node, buildStyle container.style, {
            color: "blue"
        }
    else if isText(node, 'string')
        container.push frame = newFrame node, buildStyle container.style, {
            background: "yellow"
        }
    else
        container.push frame = newFrame node, container.style
    return null

window.addEventListener 'load', () ->
    fs = null
    path = "index.json"
    root = newList([])
    command_root = null#newList([])
    cursor = liftRight {index:0, node:root}
    copybuffer = null
    trail  = null
    frame = null

    if chrome? and chrome.fileSystem?
        help = document.getElementById("help")
        help.style.display = "none"
        editor = document.getElementById("editor")
        editor.style.width = "100%"

        boot_filesystem = (fs_root) ->
            fs = new EditorFileSystem(fs_root)
            fs.open path, (node) ->
                node = newList([]) unless node?
                root = node
                cursor = liftRight {index:0, node:root}

        filesystem_must_open = () ->
            chrome.fileSystem.chooseEntry {
                type: 'openDirectory'
                accepts: [extensions: ['html']]
            }, (root) ->
                window.close() unless root?
                chrome.storage.local.set project_directory: chrome.fileSystem.retainEntry root
                boot_filesystem(root)

        chrome.storage.local.get "project_directory", ({project_directory}) ->
            if project_directory?
                chrome.fileSystem.restoreEntry project_directory, (root) ->
                    filesystem_must_open() unless root?
                    boot_filesystem(root)
            else
                filesystem_must_open()

    canvas = autoResize document.getElementById('editor')
    bc = canvas.getContext '2d'
    mouse = mouseInput(canvas)

    #root = newList([ newList([ newList([ newText("square"), newText("x") ]), newMark('cr'), newList([ newText("x"), newText("*"), newText("x") ], 'infix') ], 'define'), newMark('cr'), newList([ newList([ newText("factorial"), newText("n") ]), newMark('cr'), newList([ newList([ newList([ newText("n"), newText("="), newText("1", "int") ], 'infix'), newMark("cr"), newText("1", "int") ]) newList([ newList([ newText("n"), newText("="), newText("0", "int") ], 'infix'), newMark("cr"), newText("1", "int") ]), newList([ newMark("cr"), newList([ newText("n"), newText("*"), newList([ newText("factorial"), newList([ newText("n"), newText("-"), newText("1", "int") ], 'infix') ]) ], 'infix') ], 'else') ], 'cond') ], 'define') ])

    canvas.addEventListener 'click', (ev) ->
        ev.preventDefault()
        mode = modeReset()
        if (near = frame.nearest(mouse.point...))?
            cursor = {index:near.index, node:near.frame.node}

    modeReset = () ->
        trail = null
        command_root = null
        return selectMode

    selectMode = (code) ->
        if code == 27
            return modeReset()
        if code == "i"
            return insertMode
        if code == ":"
            command_root = newList([])
            cursor  = {node:command_root, index:0}
            return insertMode
        if code == "v"
            trail = cursor
            trail.index -= 1 if trail.index == trail.node.length
            return visualMode
        modeMotion(code)
        if code == "<" and cursor.node.parent?
            shifting = cursor.node
            dst = travelLeft deleteUnder indexBefore shifting
            if isText(dst.node)
                dst = indexBefore dst.node
            dst.node.put dst.index, newList([shifting]), false
        if code == ">" and cursor.node.parent?
            shifting = cursor.node
            dst = travelRight deleteUnder indexBefore shifting
            if isText(dst.node)
                dst = indexAfter dst.node
            dst.node.put dst.index, newList([shifting]), false
        if code == " " and isText(cursor.node)
            if cursor.index == 0
                cursor = indexBefore cursor.node
            if cursor.index == cursor.node.length
                cursor = indexAfter cursor.node
        if code == "p" and copybuffer?
            if isText(cursor.node) and isList(copybuffer)
                cursor = splitNode splitNode cursor
            if isList(cursor.node) and isText(copybuffer)
                cursor.node.put cursor.index, newList([copybuffer])
                cursor.index += 1
            else
                cursor.node.put cursor.index, copybuffer
                cursor.index += copybuffer.length
        if code == "x" and cursor.index < cursor.node.length
            deleteUnder cursor
            if isText(cursor.node) and cursor.node.length == 0 and cursor.node.parent?
                cursor = deleteUnder indexBefore cursor.node
        if code == "X"
            {node, index} = cursor
            if isText(node) and node.parent?
                node = node.parent
            if node.parent?
                bulldoze = indexBefore node
                deleteUnder bulldoze
                bulldoze.node.put bulldoze.index, node, false
                if cursor.node == node
                    cursor.index += bulldoze.index
        return selectMode
    selectMode.tag = "select"

#        if txt == '%'
#            window.evaluateDocument(currentdoc)

    modeMotion = (code) ->
        if code == "h"
            cursor = stepLeft cursor
        if code == "l"
            cursor = stepRight cursor
        if code == "j"
            cursor = flowLeft cursor
        if code == "k"
            cursor = flowRight cursor
        if code == "w" or code == 9
            cursor = tabRight cursor
        if code == "e"
            if isText(cursor.node) and cursor.index < cursor.node.length
                cursor = indexBottom cursor.node
            else
                cursor = tabRight cursor
                cursor = indexBottom cursor.node if isText(cursor.node)
        if code == "b"
            if isText(cursor.node) and 0 < cursor.index
                cursor = indexTop cursor.node
            else
                cursor = tabLeft cursor
                cursor = indexTop cursor.node if isText(cursor.node)

    insertMode = (code) ->
        if code == 27
            return modeReset()
        else if code == 13 and outerList(cursor).node == command_root
            submitCommand(command_root)
            return modeReset()
        else if code == ","
            return insertNodeMode
        else if code == 9
            cursor = tabRight cursor
        else if code == " "
            cursor = splitNode cursor
        else if code == 13
            cursor = splitNode splitNode cursor
            cursor.node.put cursor.index, newList([newMark('cr')]), false
            cursor.index += 1
        else if code == "("
            cursor = splitNode splitNode cursor
            cursor.node.put cursor.index, newList([node=newList([])]), false
            cursor.node  = node
            cursor.index = 0
        else if code == ")"
            if isText(cursor.node)
                cursor = indexAfter cursor.node
            cursor = indexAfter cursor.node
        else if code == ";"
            if isText(cursor.node)
                newlabel = cursor.node.text
                cursor = indexBefore cursor.node
                cursor.node.kill cursor.index, cursor.index+1
                cursor.node.relabel newlabel
            else
                cursor.node.relabel null
        else if code == '"'
            if isText(cursor.node, "string")
                return stringMode
            cursor = splitNode splitNode cursor
            cursor.node.put cursor.index, newList([node=newText('', 'string')]), false
            cursor = {node, index:0}
            return stringMode
        else if code == 8
            cursor = deleteLeft(cursor)
        else if code == 46
            cursor = deleteRight(cursor)
        else if typeof code == 'string'
            insertChar(code)
        return insertMode
    insertMode.tag = "insert"

    stringMode = (code) ->
        if typeof code == 'string'
            insertChar(code)
        else if code == 13
            insertChar('\n')
        else if code == 27
            cursor = indexAfter(cursor.node) if cursor.node.parent?
            return insertMode
        return stringMode
    stringMode.tag = "insert string"

    insertChar = (code) ->
        if isText(cursor.node)
            cursor.node.put cursor.index, newText(code), false
            cursor.index += 1
        else if isList(cursor.node)
            cursor.node.put cursor.index, newList([node = newText(code)]), false
            cursor.node  = node
            cursor.index = 1

    insertNodeMode = (code) ->
        if code == "k"
            cursor = popList cursor, 1
            cursor.block.relabel 'idx'
            cursor.node.put(cursor.index, newList([cursor.block]), false)
            cursor.index += 1
        if code == "."
            cursor = popList cursor, 2
            cursor.block.relabel 'attr'
            cursor.node.put(cursor.index, newList([cursor.block]), false)
            cursor.index += 1
        if code == "i"
            cursor = popList cursor, 3
            cursor.block.relabel 'infix'
            cursor.node.put(cursor.index, newList([cursor.block]), false)
            cursor.index += 1
        if code == "c"
            cursor = popList cursor, 1
            cursor.block.relabel null
            cursor.node.put(cursor.index, newList([cursor.block]), false)
            cursor = {node:cursor.block, index:cursor.block.length}
        if code == "l"
            cursor = popList cursor, 1
            cursor.block.relabel 'let'
            cursor.node.put(cursor.index, newList([cursor.block]), false)
            cursor = {node:cursor.block, index:cursor.block.length}
        if code == "s"
            cursor = popList cursor, 1
            cursor.block.relabel 'set'
            cursor.node.put(cursor.index, newList([cursor.block]), false)
            cursor = {node:cursor.block, index:cursor.block.length}
        if code == "b"
            cursor = splitNode splitNode cursor
            block = newList([cond = newList([])], 'cond')
            cursor.node.put(cursor.index, newList([block]), false)
            cursor = {node:cond, index:0}
        if code == "w"
            cursor = splitNode splitNode cursor
            block = newList([], 'while')
            cursor.node.put(cursor.index, newList([block]), false)
            cursor = {node:block, index:block.length}
        if code == "f"
            cursor = splitNode splitNode cursor
            block = newList([newList([]), newMark('cr')], 'func')
            cursor.node.put(cursor.index, newList([block]), false)
            cursor = {node:block, index:block.length}
        if code == "a" and isText(cursor.node)
            argument = cursor.node
            current = cursor.node.parent
            while current? and not isList(current, 'func')?
                current = current.parent
            if isList(current, 'func')
                unless isList(current.list[0])
                    current.put(0, newList([argument]))
                else
                    arglist = current.list[0]
                    arglist.put(arglist.length, newList([argument]))
        return insertMode
    insertNodeMode.tag = "insert node"

    popList = (cursor, count) ->
        cursor = splitNode splitNode cursor
        start = Math.max(0, cursor.index - count)
        block = cursor.node.kill(start, cursor.index)
        return {node:cursor.node, index:start, block}

    submitCommand = (node) ->
        return if node.length < 1 or not isList(node)
        head = node.list[0]
        if isSymbol(head, "edit") or isSymbol(head, "e")
            arg = node.list[1]
            if isText(arg)
                return loadFile(arg.text)
        if isSymbol(head, "write") or isSymbol(head, "w")
            return storeFile()
        if isSymbol(head, "directory")
            return filesystem_must_open()
        console.log 'unrecognised command', head

    loadFile = (npath) ->
        fs.open npath, (node) ->
            path = npath
            node = newList([]) unless node?
            root = node
            cursor = liftRight {index:0, node:root}

    storeFile = () ->
        fs.save path, root, (success) ->
            console.log "write failed" unless success
            console.log "write success"

    isSymbol = (node, text) ->
        return isText(node) and node.text == text

    visualMode = (code) ->
        if code == 27
            return modeReset()
        if code == "h" or code == "j"
            {node, index} = cursor
            if 0 < index
                cursor = {node, index:index-1}
            else if node.parent?
                trail = cursor = indexBefore node
        if code == "l" or code == "k"
            {node, index} = cursor
            if index < node.length - 1
                cursor = {node, index:index+1}
            else if node.parent?
                trail = cursor = indexBefore node
        if code == "v" and cursor.node.parent?
            trail = cursor = indexBefore cursor.node
        if code == "d" and trail.node == cursor.node
            {start, stop} = selectionRange trail, cursor
            copybuffer = cursor.node.kill(start, stop)
            return modeReset()
        if code == "y" and trail.node == cursor.node
            {start, stop} = selectionRange trail, cursor
            copybuffer = cursor.node.yank(start, stop)
            return modeReset()
        if code == "<" and trail.node == cursor.node and isList(cursor.node)
            {start, stop} = selectionRange trail, cursor
            block = cursor.node.kill(start, stop)
            dst = flowLeft {node:cursor.node, index:start}
            if isText(dst.node)
                dst = indexBefore dst.node
            dst.node.put dst.index, block, false
            cursor = {node:dst.node, index: dst.index + cursor.index - start}
            trail  = {node:dst.node, index: dst.index + trail.index  - start}
        if code == ">" and trail.node == cursor.node and isList(cursor.node)
            {start, stop} = selectionRange trail, cursor
            block = cursor.node.kill(start, stop)
            dst = flowRight {node:cursor.node, index:start}
            if isText(dst.node)
                dst = indexAfter dst.node
            dst.node.put dst.index, block, false
            cursor = {node:dst.node, index: dst.index + cursor.index - start}
            trail  = {node:dst.node, index: dst.index + trail.index  - start}
#       else if code == ","
#           go to nodeinsert mode
        return mode
    visualMode.tag = "visual"

    pressedKeys = []

    mode = selectMode
    keyboardEvents canvas, (keyCode, text) ->
        code = if text == "" then keyCode else text
        mode = mode(code)
        now = Date.now()/1000
        pressedKeys.push {time:now, code}
        pressedKeys = pressedKeys.filter (item) ->
            return item.time >= now - 2.0

    buildFrame = (root) ->
        aframe = newFrame root, buildStyle defaultStyle, {
            indent: 0
            verticalSpacing: 25
        }
        for node in aframe.node.list
            addFrame(aframe, node)
        aframe.layout(bc)
        return aframe

    draw = () ->
        bc.fillStyle = "#ccc"
        bc.fillRect(0, 0, canvas.width, canvas.height)

        frame = buildFrame(root)
        frame.x = 50
        frame.y = 50
        frame.paint(bc)

        comm_frame = null
        if command_root?
            comm_frame = buildFrame(command_root)
            comm_frame.x = 50
            comm_frame.y = canvas.height - comm_frame.height - 16 - 30
            bc.fillStyle = "#aaa"
            bc.fillRect(0, comm_frame.y, canvas.width, comm_frame.height)
            comm_frame.paint(bc)

        if (near = frame.nearest(mouse.point...))? and near.dist < 100
            drawSelection(bc, near.frame, near.index, near.index, "black")

        if cursor? and trail? and cursor.node == trail.node
            if (cframe = frame.find cursor.node)?
                {start, stop} = selectionRange trail, cursor
                drawSelection(bc, cframe, start, stop, "blue")
        else if cursor?
            cframe = frame.find cursor.node
            if cframe?
                drawSelection(bc, cframe, cursor.index, cursor.index, "blue")
            if comm_frame?
                cframe = comm_frame.find cursor.node
                if cframe?
                    drawSelection(bc, cframe, cursor.index, cursor.index, "blue")

        bc.font = "12px sans-serif"
        bc.fillStyle = 'black'
        bc.fillRect(0, 0, canvas.width, 16)
        bc.fillStyle = 'white'
        bc.fillText " #{path}", 0, 11

        bc.fillStyle = 'black'
        bc.fillRect(0, canvas.height-16, canvas.width, 16)
        bc.fillStyle = 'white'
        bc.fillText " -- #{mode.tag} --", 0, canvas.height - 5


        bc.strokeStyle = 'black'
        x = 10
        for item in pressedKeys
            if typeof item.code == 'string'
                name = item.code
            else
                name = keyNames[item.code] or item.code

            w = bc.measureText(name).width
            bc.fillStyle = 'white'
            bc.fillRect x, canvas.height-40, w + 20, 15
            bc.strokeRect x, canvas.height-40, w + 20, 20
            bc.fillStyle = 'black'
            bc.fillText name, x+10, canvas.height-30
            x += w + 30

        requestAnimationFrame draw
    draw()

outerList = (cursor) ->
    cursor = indexBefore(cursor.node) if isText(cursor.node)
    return cursor

deleteUnder = (cursor) ->
    cursor.node.kill cursor.index, cursor.index+1
    return cursor

deleteLeft = (cursor) ->
    {node, index} = cursor = cursor
    if isText(node)
        if index > 0
            cursor = deleteUnder {node, index:index-1}
            if node.length == 0 and node.parent?
                cursor = deleteUnder indexBefore node
        else if node.parent?
            {node, index} = cursor = indexBefore cursor
            child = node.list[index-1]
            if isText(child)
                postfix = node.kill(index, index+1).list[0]
                cursor = indexBottom child
                cursor.node.put(cursor.index, postfix, false)
            else
                cursor = deleteLeft(cursor)
    else if isList(node)
        child = node.list[index-1]
        if index == 0 and node.parent?
            cursor = indexBefore node
            if node.length == 0
                deleteUnder cursor
        else if isList(child)
            cursor = indexBottom child
        else if isText(child)
            cursor = deleteLeft indexBottom child
        else
            cursor = deleteUnder {node, index:index-1}
    return cursor

deleteRight = (cursor) ->
    {node, index} = cursor = cursor
    if isText(node)
        if index < node.length
            cursor = deleteUnder {node, index:index}
            if node.length == 0 and node.parent?
                cursor = deleteUnder indexBefore node
        else if node.parent?
            {node, index} = cursor = indexAfter cursor
            child = node.list[index]
            if isText(child)
                postfix = node.kill(index, index+1).list[0]
                cursor = indexBottom node.list[index-1]
                cursor.node.put(cursor.index, postfix, false)
            else
                cursor = deleteRight(cursor)
    else if isList(node)
        child = node.list[index]
        if index == node.length and node.parent?
            if node.length == 0
                cursor = deleteUnder indexBefore node
            else
                cursor = indexAfter node
        else if isList(child)
            cursor = indexTop child
        else if isText(child)
            cursor = deleteRight indexTop child
        else
            cursor = deleteUnder {node, index:index}
    return cursor

splitNode = (cursor) ->
    {node, index} = cursor
    if isText(node) and node.parent?
        if index == 0
            return indexBefore node
        if index == node.length
            return indexAfter node
        prefix = newList([node.kill(0, index)])
        ins = indexBefore(node)
        ins.node.put ins.index, prefix, false
        return {node, index:0}
    return cursor

flowLeft = (cursor) ->
    {node, index} = cursor
    if isText(node) and node.parent?
        cursor = liftLeft indexBefore node
    else if isList(node)
        if index > 0
            cursor = {node:node, index:index-1}
        else if node.parent?
            cursor = indexBefore node
    return cursor

flowRight = (cursor) ->
    {node, index} = cursor
    if isText(node) and node.parent?
        cursor = liftRight indexAfter node
    else if isList(node)
        if index < node.length
            cursor = {node:node, index:index+1}
        else if node.parent?
            cursor = indexAfter node
    return cursor

tabLeft = (cursor) ->
    {node, index} = cursor = travelLeft cursor
    if index == 0 and not node.parent?
        return cursor
    if isList(node) and node.length > 0
        return tabLeft(cursor)
    return cursor

tabRight = (cursor) ->
    {node, index} = cursor = travelRight cursor
    if index == node.length and not node.parent?
        return cursor
    if isList(node) and node.length > 0
        return tabRight(cursor)
    return cursor

stepLeft = (cursor) ->
    {node, index} = cursor
    if isText(node) and 0 < index
        cursor = {node, index:index - 1}
    else
        cursor = travelLeft cursor
    return cursor

stepRight = (cursor) ->
    {node, index} = cursor
    if isText(node) and index < node.length
        cursor = {node, index:index + 1}
    else
        cursor = travelRight cursor
    return cursor

travelLeft = (cursor) ->
    {node, index} = cursor
    if isText(node) and node.parent?
        cursor = travelLeft indexBefore node
    else if isList(node)
        if 0 < index
            child = node.list[index-1]
            if isList(child) or isText(child)
                cursor = indexBottom child
            else
                cursor = {node, index:index-1}
        else if node.parent?
            cursor = indexBefore node
    return liftLeft cursor

travelRight = (cursor) ->
    {node, index} = cursor
    if isText(node) and node.parent?
        cursor = travelRight indexAfter node
    else if isList(node)
        if index < node.length
            child = node.list[index]
            if isList(child) or isText(child)
                cursor = indexTop child
            else
                cursor = {node, index:index+1}
        else if node.parent?
            cursor = indexAfter node
    return liftRight cursor

liftLeft = (cursor) ->
    {node, index} = cursor
    if isList(node)
        child = node.list[index-1]
        cursor = indexBottom child if isText(child)
    return cursor

liftRight = (cursor) ->
    {node, index} = cursor
    if isList(node)
        child = node.list[index]
        cursor = indexTop child if isText(child)
    return cursor

indexTop = (node) ->
    return {node:node, index:0}

indexBottom = (node) ->
    return {node:node, index:node.length}

indexBefore = (node) ->
    return {node:node.parent, index:node.parent.indexOf(node)}

indexAfter = (node) ->
    return {node:node.parent, index:node.parent.indexOf(node)+1}


selectionRange = (trail, cursor) ->
    start = Math.min(trail.index, cursor.index)
    stop  = Math.max(trail.index+1, cursor.index+1)
    return {start, stop}

drawSelection = (bc, frame, start, stop, style) ->
    bc.globalAlpha = 1.0
    parent = frame.parent
    while parent?
        bc.strokeStyle = parent.style.selection
        {x, y} = parent.getPosition()
        bc.strokeRect(x, y, parent.width, parent.height)
        parent = parent.parent
    bc.globalAlpha = 0.5
    bc.strokeStyle = style
    bc.fillStyle = style
    frame.paintSelection(bc, start, stop)
    bc.globalAlpha = 1.0

#    inString = (selection) ->
#        return selection.target.type == "text" and selection.target.label == "string"
#
#    insertString = () ->
#        switch nodeType(selection.target)
#            when 'text'
#                if selection.target.label == "string"
#                    {start, stop, target} = selection.target.getRange()
#                    selection = new Selection(target, stop, stop)
#                else
#                    labelled "string", selection.target
#            when 'list'
#                tnode = labelled "string", text("")
#                lb = listbuffer(tnode)
#                selection.target.put selection.head, lb
#                selection = new Selection(tnode, 0, 0)
