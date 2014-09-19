if require?
    {TextEncoder, TextDecoder} = require 'text-encoding'
else
    {TextEncoder, TextDecoder} = window

class StreamReader
    constructor: (@buffer) ->
        @view = new DataView(@buffer)
        @pos = 0

    byte: () ->
        v = @view.getUint8(@pos)
        @pos += 1
        return v

    bytes: (count) ->
        u8 = new Uint8Array(@buffer, @pos, count)
        @pos += count
        return u8

    integer: () ->
        a = @byte()
        b = @byte()
        c = @byte()
        d = @byte()
        v = (a << 0) | (b << 8) | (c << 16) | (d << 24)
        return v

    string: (count) ->
        return TextDecoder().decode(@bytes(count))

header_magic = [137,66,76,73,80,40,97,108,112,104,97,41,13,10,26,10]
readHeader = (stream) ->
    u8 = stream.bytes(16)
    valid = true
    for i in [0...16]
        valid |= (header_magic[i] == u8[i])
    return valid

readNode = (stream) ->
    info = stream.integer()
    tyid = info >> 0 & 3
    uidlen = info >> 2 & 127
    lablen = info >> 9 & 127
    datlen = info >> 16 & 0xffff
    uid = stream.string(uidlen)
    lab = stream.string(lablen)
    return [readList, readText, readData, readMark][tyid](stream, lab, uid, datlen)

readList = (stream, label, uid, length) ->
    list = (readNode(stream) for i in [0...length])
    return env.List(list, label, uid)

readText = (stream, label, uid, length) ->
    return env.Text(stream.string(length), label, uid)

readData = (stream, label, uid, length) ->
    stream.bytes(length)
    throw "not implemented"

readMark = (stream, label, uid, length) ->
    return env.Mark(label, uid)

env.readBlip = (buffer) ->
    stream = new StreamReader(buffer)
    if readHeader(stream)
        return readNode(stream)

# for testing, can be removed later
env.readBlipFile = (path) ->
    fs = require 'fs'
    toArrayBuffer = (buffer) ->
        ab = new ArrayBuffer(buffer.length)
        view = new Uint8Array(ab)
        for i in [0...buffer.length]
            view[i] = buffer[i]
        return ab
    buffer = toArrayBuffer fs.readFileSync path
    return env.readBlip(buffer)

# once the layout and input works we need the write -functions.
# the pythonboot/blip.py in the snakelisp shows the structure.
# node.constructor.name will be useful.
