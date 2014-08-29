window.requestFileSystem = window.requestFileSystem or window.webkitRequestFileSystem

class window.EditorFileSystem
    constructor: (@root) ->

    open: (path, callback) ->
        failure = (error) =>
            callback null, null
        success = (ent) =>
            ent.file read, failure
        read = (file) =>
            reader = new FileReader()
            reader.onload = () =>
                try
                    node = importJson JSON.parse reader.result
                catch err
                    callback null, "error at read: #{err}"
                    return null
                callback node
            reader.readAsText(file)
        @root.getFile path, {}, success, failure

    save: (path, node, callback) ->
        failure = (error) ->
            callback false, null if callback?
        write = (entry) ->
            entry.createWriter (writer) ->
                try
                    trunc = false
                    writer.onwriteend = () ->
                        unless trunc
                            trunc = true
                            writer.truncate this.position
                            return
                        callback true if callback?
                    writer.onerror = (e) ->
                        console.log "write fail", e
                        callback false if callback?
                    json = exportJson node
                    data = JSON.stringify json
                    blob = new Blob([data], {type:"text/plain"})
                    writer.write(blob)
                catch err
                    console.log err
                    callback false if callback?
        @root.getFile path, {create: true}, write, failure
