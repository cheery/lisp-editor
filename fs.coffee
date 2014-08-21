window.requestFileSystem ?= window.webkitRequestFileSystem

class window.LispFS
    constructor: (callback) ->
        @entries = []
        requestFileSystem(PERSISTENT, 1024*1024,
            (@fs) =>
                @running = true
                @updateList()
                callback() if callback?

        )
        @documents = []

    updateList: () ->
        ls = @fs.root.createReader()
        ls.readEntries (@entries) =>

    load: (path, callback) ->
        failure = (error) =>
            for doc in @documents
                continue if doc.ent?
                if path == doc.name
                    return callback(doc)
            @documents.push doc = new Document(null, path, list())
            return callback(doc)
        success = (ent) =>
            for doc in @documents
                continue unless doc.ent?
                if ent.fullPath == doc.ent.fullPath
                    return callback(doc)
            readFile = (file) =>
                reader = new FileReader()
                reader.onload = () =>
                    try
                        node = importJson JSON.parse reader.result
                    catch e
                        console.log "error at read: #{e}"
                        node = list()
                    @documents.push doc = new Document(ent, path, node)
                    return callback doc
                reader.readAsText(file)
            ent.file readFile, failure
        @fs.root.getFile path, {}, success, failure

    store: (doc, callback) ->
        writeToFile = (ent) =>
            ent.createWriter (writer) =>
                writer.truncate 0
                ent.createWriter (writer) =>
                    writer.onwriteend = () =>
                        doc.wasSaved()
                        @updateList()
                        callback() if callback?
                    data = JSON.stringify exportJson doc.node
                    blob = new Blob([data], {type:"text/plain"})
                    writer.write blob
        if doc.ent?
            writeToFile doc.ent
        else
            success = (ent) =>
                writeToFile doc.ent = ent
            @fs.root.getFile doc.name, {create: true}, success

class Document
    constructor: (@ent, @name, @node) ->
        @node.document = @
        @lastsave   = Date.now() / 1000
        @lastchange = Date.now() / 1000

    replace: (@node) ->
        @node.document = @

    isModified: () ->
        return @lastsave < @lastchange

    wasSaved: () ->
        @lastsave   = Date.now() / 1000

    wasChanged: () ->
        console.log 'was changed!'
        @lastchange = Date.now() / 1000
