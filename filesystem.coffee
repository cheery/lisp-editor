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
        failure = (error) =>
            callback false, null
        write = (entry) =>
            entry.createWriter (writer) =>
                writer.truncate 0
                entry.createWriter (writer) =>
                    writer.onwriteend = () =>
                        callback true
                    data = JSON.stringify exportJson node
                    blob = new Blob([data], {type:"text/plain"})
                    writer.write blob
        @root.getFile path, {create: true}, write, failure
