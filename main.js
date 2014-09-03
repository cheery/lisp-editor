// Generated by CoffeeScript 1.6.3
(function() {
  var addFrame, buildStyle, condStyle, defaultStyle, deleteLeft, deleteRight, deleteUnder, drawSelection, flowLeft, flowRight, indexAfter, indexBefore, indexBottom, indexTop, keyNames, labelStyle, liftLeft, liftRight, outerList, selectionRange, splitNode, stepLeft, stepRight, tabLeft, tabRight, travelLeft, travelRight;

  defaultStyle = {
    fontName: "sans-serif",
    fontSize: 16,
    topPadding: 0,
    leftPadding: 0,
    rightPadding: 0,
    bottomPadding: 0,
    spacing: 5,
    indent: 10,
    verticalSpacing: 16 / 4,
    color: "black",
    selection: "blue"
  };

  buildStyle = function(parent, style) {
    var name, value;
    for (name in parent) {
      value = parent[name];
      if (style[name] == null) {
        style[name] = value;
      }
    }
    return style;
  };

  labelStyle = buildStyle(defaultStyle, {
    color: "purple",
    fontSize: 12
  });

  condStyle = buildStyle(defaultStyle, {
    indent: 0,
    selection: "yellow"
  });

  keyNames = {
    8: "backspace",
    9: "tab",
    13: "ret",
    16: "shift",
    17: "ctrl",
    18: "alt",
    27: "esc",
    46: "del"
  };

  addFrame = function(container, node) {
    var first, frame, item, row, subitem, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _len5, _len6, _m, _n, _o, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6;
    if (isMark(node, 'cr')) {
      return container.newline(node);
    }
    if (isList(node, 'cond')) {
      container.push(frame = newFrame(node, condStyle));
      first = true;
      _ref = node.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        if (!first) {
          frame.newline();
        }
        if (isList(item, 'else')) {
          row = newFrame(item, defaultStyle);
          row.push(newDeco("else", labelStyle));
          _ref1 = item.list;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            subitem = _ref1[_j];
            addFrame(row, subitem);
          }
        } else if (isList(item)) {
          row = newFrame(item, defaultStyle);
          if (!first) {
            row.push(newDeco("else", labelStyle));
          }
          row.push(newDeco("if", labelStyle));
          _ref2 = item.list;
          for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
            subitem = _ref2[_k];
            addFrame(row, subitem);
          }
        } else {
          addFrame(frame, item);
        }
        frame.push(row);
        first = false;
      }
    } else if (isList(node, 'infix')) {
      container.push(frame = newFrame(node, buildStyle(defaultStyle, {
        selection: "green"
      })));
      _ref3 = node.list;
      for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
        item = _ref3[_l];
        addFrame(frame, item);
      }
    } else if (isList(node, 'let') && node.length >= 2) {
      container.push(frame = newFrame(node, defaultStyle));
      addFrame(frame, node.list[0]);
      frame.push(newDeco("←", labelStyle));
      _ref4 = node.list.slice(1, node.length);
      for (_m = 0, _len4 = _ref4.length; _m < _len4; _m++) {
        item = _ref4[_m];
        addFrame(frame, item);
      }
    } else if (isList(node, 'set') && node.length >= 2) {
      container.push(frame = newFrame(node, defaultStyle));
      addFrame(frame, node.list[0]);
      frame.push(newDeco("←", buildStyle(labelStyle, {
        color: "black"
      })));
      _ref5 = node.list.slice(1, node.length);
      for (_n = 0, _len5 = _ref5.length; _n < _len5; _n++) {
        item = _ref5[_n];
        addFrame(frame, item);
      }
    } else if (isList(node)) {
      container.push(frame = newFrame(node, buildStyle(defaultStyle, {
        selection: "blue"
      })));
      if (node.label != null) {
        frame.push(newDeco(node.label, labelStyle));
      }
      _ref6 = node.list;
      for (_o = 0, _len6 = _ref6.length; _o < _len6; _o++) {
        item = _ref6[_o];
        addFrame(frame, item);
      }
    } else if (isText(node, 'int')) {
      container.push(frame = newFrame(node, buildStyle(container.style, {
        color: "blue"
      })));
    } else if (isText(node, 'string')) {
      container.push(frame = newFrame(node, buildStyle(container.style, {
        background: "yellow"
      })));
    } else {
      container.push(frame = newFrame(node, container.style));
    }
    return null;
  };

  window.addEventListener('load', function() {
    var bc, boot_filesystem, buildFrame, canvas, command_root, copybuffer, cursor, draw, editor, filesystem_must_open, frame, fs, help, insertChar, insertMode, insertNodeMode, isSymbol, loadFile, mode, modeMotion, modeReset, mouse, path, popList, pressedKeys, root, selectMode, storeFile, stringMode, submitCommand, trail, visualMode;
    fs = null;
    path = "index.json";
    root = newList([]);
    command_root = null;
    cursor = liftRight({
      index: 0,
      node: root
    });
    copybuffer = null;
    trail = null;
    frame = null;
    if ((typeof chrome !== "undefined" && chrome !== null) && (chrome.fileSystem != null)) {
      help = document.getElementById("help");
      help.style.display = "none";
      editor = document.getElementById("editor");
      editor.style.width = "100%";
      boot_filesystem = function(fs_root) {
        fs = new EditorFileSystem(fs_root);
        return fs.open(path, function(node) {
          if (node == null) {
            node = newList([]);
          }
          root = node;
          return cursor = liftRight({
            index: 0,
            node: root
          });
        });
      };
      filesystem_must_open = function() {
        return chrome.fileSystem.chooseEntry({
          type: 'openDirectory',
          accepts: [
            {
              extensions: ['html']
            }
          ]
        }, function(root) {
          if (root == null) {
            window.close();
          }
          chrome.storage.local.set({
            project_directory: chrome.fileSystem.retainEntry(root)
          });
          return boot_filesystem(root);
        });
      };
      chrome.storage.local.get("project_directory", function(_arg) {
        var project_directory;
        project_directory = _arg.project_directory;
        if (project_directory != null) {
          return chrome.fileSystem.restoreEntry(project_directory, function(root) {
            if (root == null) {
              filesystem_must_open();
            }
            return boot_filesystem(root);
          });
        } else {
          return filesystem_must_open();
        }
      });
    }
    canvas = autoResize(document.getElementById('editor'));
    bc = canvas.getContext('2d');
    mouse = mouseInput(canvas);
    canvas.addEventListener('click', function(ev) {
      var mode, near;
      ev.preventDefault();
      mode = modeReset();
      if ((near = frame.nearest.apply(frame, mouse.point)) != null) {
        return cursor = {
          index: near.index,
          node: near.frame.node
        };
      }
    });
    modeReset = function() {
      trail = null;
      command_root = null;
      return selectMode;
    };
    selectMode = function(code) {
      var bulldoze, dst, index, node, shifting;
      if (code === 27) {
        return modeReset();
      }
      if (code === "i") {
        return insertMode;
      }
      if (code === ":") {
        command_root = newList([]);
        cursor = {
          node: command_root,
          index: 0
        };
        return insertMode;
      }
      if (code === "v") {
        trail = cursor;
        if (trail.index === trail.node.length) {
          trail.index -= 1;
        }
        return visualMode;
      }
      modeMotion(code);
      if (code === "<" && (cursor.node.parent != null)) {
        shifting = cursor.node;
        dst = travelLeft(deleteUnder(indexBefore(shifting)));
        if (isText(dst.node)) {
          dst = indexBefore(dst.node);
        }
        dst.node.put(dst.index, newList([shifting]), false);
      }
      if (code === ">" && (cursor.node.parent != null)) {
        shifting = cursor.node;
        dst = travelRight(deleteUnder(indexBefore(shifting)));
        if (isText(dst.node)) {
          dst = indexAfter(dst.node);
        }
        dst.node.put(dst.index, newList([shifting]), false);
      }
      if (code === " " && isText(cursor.node)) {
        if (cursor.index === 0) {
          cursor = indexBefore(cursor.node);
        }
        if (cursor.index === cursor.node.length) {
          cursor = indexAfter(cursor.node);
        }
      }
      if (code === "p" && (copybuffer != null)) {
        if (isText(cursor.node) && isList(copybuffer)) {
          cursor = splitNode(splitNode(cursor));
        }
        if (isList(cursor.node) && isText(copybuffer)) {
          cursor.node.put(cursor.index, newList([copybuffer]));
          cursor.index += 1;
        } else {
          cursor.node.put(cursor.index, copybuffer);
          cursor.index += copybuffer.length;
        }
      }
      if (code === "x" && cursor.index < cursor.node.length) {
        deleteUnder(cursor);
        if (isText(cursor.node) && cursor.node.length === 0 && (cursor.node.parent != null)) {
          cursor = deleteUnder(indexBefore(cursor.node));
        }
      }
      if (code === "X") {
        node = cursor.node, index = cursor.index;
        if (isText(node) && (node.parent != null)) {
          node = node.parent;
        }
        if (node.parent != null) {
          bulldoze = indexBefore(node);
          deleteUnder(bulldoze);
          bulldoze.node.put(bulldoze.index, node, false);
          if (cursor.node === node) {
            cursor.index += bulldoze.index;
          }
        }
      }
      return selectMode;
    };
    selectMode.tag = "select";
    modeMotion = function(code) {
      if (code === "h") {
        cursor = stepLeft(cursor);
      }
      if (code === "l") {
        cursor = stepRight(cursor);
      }
      if (code === "k") {
        cursor = flowLeft(cursor);
      }
      if (code === "j") {
        cursor = flowRight(cursor);
      }
      if (code === "0") {
        if (isText(cursor.node) && (cursor.node.parent != null)) {
          cursor.node = cursor.node.parent;
        }
        cursor.index = 0;
      }
      if (code === "$") {
        if (isText(cursor.node) && (cursor.node.parent != null)) {
          cursor.node = cursor.node.parent;
        }
        cursor.index = cursor.node.length;
      }
      if (code === "w" || code === 9) {
        cursor = tabRight(cursor);
      }
      if (code === "e") {
        if (isText(cursor.node) && cursor.index < cursor.node.length) {
          cursor = indexBottom(cursor.node);
        } else {
          cursor = tabRight(cursor);
          if (isText(cursor.node)) {
            cursor = indexBottom(cursor.node);
          }
        }
      }
      if (code === "b") {
        if (isText(cursor.node) && 0 < cursor.index) {
          return cursor = indexTop(cursor.node);
        } else {
          cursor = tabLeft(cursor);
          if (isText(cursor.node)) {
            return cursor = indexTop(cursor.node);
          }
        }
      }
    };
    insertMode = function(code) {
      var newlabel, node;
      if (code === 27) {
        return modeReset();
      } else if (code === 13 && outerList(cursor).node === command_root) {
        submitCommand(command_root);
        return modeReset();
      } else if (code === ",") {
        return insertNodeMode;
      } else if (code === 9) {
        cursor = tabRight(cursor);
      } else if (code === " ") {
        cursor = splitNode(cursor);
      } else if (code === 13) {
        cursor = splitNode(splitNode(cursor));
        cursor.node.put(cursor.index, newList([newMark('cr')]), false);
        cursor.index += 1;
      } else if (code === "(") {
        cursor = splitNode(splitNode(cursor));
        cursor.node.put(cursor.index, newList([node = newList([])]), false);
        cursor.node = node;
        cursor.index = 0;
      } else if (code === ")") {
        if (isText(cursor.node)) {
          cursor = indexAfter(cursor.node);
        }
        cursor = indexAfter(cursor.node);
      } else if (code === ";") {
        if (isText(cursor.node)) {
          newlabel = cursor.node.text;
          cursor = indexBefore(cursor.node);
          cursor.node.kill(cursor.index, cursor.index + 1);
          cursor.node.relabel(newlabel);
        } else {
          cursor.node.relabel(null);
        }
      } else if (code === '"') {
        if (isText(cursor.node, "string")) {
          return stringMode;
        }
        cursor = splitNode(splitNode(cursor));
        cursor.node.put(cursor.index, newList([node = newText('', 'string')]), false);
        cursor = {
          node: node,
          index: 0
        };
        return stringMode;
      } else if (code === 8) {
        cursor = deleteLeft(cursor);
      } else if (code === 46) {
        cursor = deleteRight(cursor);
      } else if (typeof code === 'string') {
        insertChar(code);
      }
      return insertMode;
    };
    insertMode.tag = "insert";
    stringMode = function(code) {
      if (typeof code === 'string') {
        insertChar(code);
      } else if (code === 13) {
        insertChar('\n');
      } else if (code === 27) {
        if (cursor.node.parent != null) {
          cursor = indexAfter(cursor.node);
        }
        return insertMode;
      }
      return stringMode;
    };
    stringMode.tag = "insert string";
    insertChar = function(code) {
      var node;
      if (isText(cursor.node)) {
        cursor.node.put(cursor.index, newText(code), false);
        return cursor.index += 1;
      } else if (isList(cursor.node)) {
        cursor.node.put(cursor.index, newList([node = newText(code)]), false);
        cursor.node = node;
        return cursor.index = 1;
      }
    };
    insertNodeMode = function(code) {
      var arglist, argument, block, cond, current;
      if (code === "k") {
        cursor = popList(cursor, 1);
        cursor.block.relabel('idx');
        cursor.node.put(cursor.index, newList([cursor.block]), false);
        cursor.index += 1;
      }
      if (code === ".") {
        cursor = popList(cursor, 2);
        cursor.block.relabel('attr');
        cursor.node.put(cursor.index, newList([cursor.block]), false);
        cursor.index += 1;
      }
      if (code === "i") {
        cursor = popList(cursor, 3);
        cursor.block.relabel('infix');
        cursor.node.put(cursor.index, newList([cursor.block]), false);
        cursor.index += 1;
      }
      if (code === "c") {
        cursor = popList(cursor, 1);
        cursor.block.relabel(null);
        cursor.node.put(cursor.index, newList([cursor.block]), false);
        cursor = {
          node: cursor.block,
          index: cursor.block.length
        };
      }
      if (code === "l") {
        cursor = popList(cursor, 1);
        cursor.block.relabel('let');
        cursor.node.put(cursor.index, newList([cursor.block]), false);
        cursor = {
          node: cursor.block,
          index: cursor.block.length
        };
      }
      if (code === "s") {
        cursor = popList(cursor, 1);
        cursor.block.relabel('set');
        cursor.node.put(cursor.index, newList([cursor.block]), false);
        cursor = {
          node: cursor.block,
          index: cursor.block.length
        };
      }
      if (code === "b") {
        cursor = splitNode(splitNode(cursor));
        block = newList([cond = newList([])], 'cond');
        cursor.node.put(cursor.index, newList([block]), false);
        cursor = {
          node: cond,
          index: 0
        };
      }
      if (code === "w") {
        cursor = splitNode(splitNode(cursor));
        block = newList([], 'while');
        cursor.node.put(cursor.index, newList([block]), false);
        cursor = {
          node: block,
          index: block.length
        };
      }
      if (code === "f") {
        cursor = splitNode(splitNode(cursor));
        block = newList([newList([]), newMark('cr')], 'func');
        cursor.node.put(cursor.index, newList([block]), false);
        cursor = {
          node: block,
          index: block.length
        };
      }
      if (code === "a" && isText(cursor.node)) {
        argument = cursor.node;
        current = cursor.node.parent;
        while ((current != null) && (isList(current, 'func') == null)) {
          current = current.parent;
        }
        if (isList(current, 'func')) {
          if (!isList(current.list[0])) {
            current.put(0, newList([argument]));
          } else {
            arglist = current.list[0];
            arglist.put(arglist.length, newList([argument]));
          }
        }
      }
      return insertMode;
    };
    insertNodeMode.tag = "insert node";
    popList = function(cursor, count) {
      var block, start;
      cursor = splitNode(splitNode(cursor));
      start = Math.max(0, cursor.index - count);
      block = cursor.node.kill(start, cursor.index);
      return {
        node: cursor.node,
        index: start,
        block: block
      };
    };
    submitCommand = function(node) {
      var arg, head;
      if (node.length < 1 || !isList(node)) {
        return;
      }
      head = node.list[0];
      if (isSymbol(head, "edit") || isSymbol(head, "e")) {
        arg = node.list[1];
        if (isText(arg)) {
          return loadFile(arg.text);
        }
      }
      if (isSymbol(head, "write") || isSymbol(head, "w")) {
        return storeFile();
      }
      if (isSymbol(head, "directory")) {
        return filesystem_must_open();
      }
      return console.log('unrecognised command', head);
    };
    loadFile = function(npath) {
      return fs.open(npath, function(node) {
        path = npath;
        if (node == null) {
          node = newList([]);
        }
        root = node;
        return cursor = liftRight({
          index: 0,
          node: root
        });
      });
    };
    storeFile = function() {
      return fs.save(path, root, function(success) {
        if (!success) {
          console.log("write failed");
        }
        return console.log("write success");
      });
    };
    isSymbol = function(node, text) {
      return isText(node) && node.text === text;
    };
    visualMode = function(code) {
      var block, dst, index, node, start, stop, _ref, _ref1, _ref2, _ref3;
      if (code === 27) {
        return modeReset();
      }
      if (code === "h" || code === "k") {
        node = cursor.node, index = cursor.index;
        if (0 < index) {
          cursor = {
            node: node,
            index: index - 1
          };
        } else if (node.parent != null) {
          trail = cursor = indexBefore(node);
        }
      }
      if (code === "l" || code === "j") {
        node = cursor.node, index = cursor.index;
        if (index < node.length - 1) {
          cursor = {
            node: node,
            index: index + 1
          };
        } else if (node.parent != null) {
          trail = cursor = indexBefore(node);
        }
      }
      if (code === "v" && (cursor.node.parent != null)) {
        trail = cursor = indexBefore(cursor.node);
      }
      if (code === "d" && trail.node === cursor.node) {
        _ref = selectionRange(trail, cursor), start = _ref.start, stop = _ref.stop;
        copybuffer = cursor.node.kill(start, stop);
        return modeReset();
      }
      if (code === "y" && trail.node === cursor.node) {
        _ref1 = selectionRange(trail, cursor), start = _ref1.start, stop = _ref1.stop;
        copybuffer = cursor.node.yank(start, stop);
        return modeReset();
      }
      if (code === "<" && trail.node === cursor.node && isList(cursor.node)) {
        _ref2 = selectionRange(trail, cursor), start = _ref2.start, stop = _ref2.stop;
        block = cursor.node.kill(start, stop);
        dst = flowLeft({
          node: cursor.node,
          index: start
        });
        if (isText(dst.node)) {
          dst = indexBefore(dst.node);
        }
        dst.node.put(dst.index, block, false);
        cursor = {
          node: dst.node,
          index: dst.index + cursor.index - start
        };
        trail = {
          node: dst.node,
          index: dst.index + trail.index - start
        };
      }
      if (code === ">" && trail.node === cursor.node && isList(cursor.node)) {
        _ref3 = selectionRange(trail, cursor), start = _ref3.start, stop = _ref3.stop;
        block = cursor.node.kill(start, stop);
        dst = flowRight({
          node: cursor.node,
          index: start
        });
        if (isText(dst.node)) {
          dst = indexAfter(dst.node);
        }
        dst.node.put(dst.index, block, false);
        cursor = {
          node: dst.node,
          index: dst.index + cursor.index - start
        };
        trail = {
          node: dst.node,
          index: dst.index + trail.index - start
        };
      }
      return mode;
    };
    visualMode.tag = "visual";
    pressedKeys = [];
    mode = selectMode;
    keyboardEvents(canvas, function(keyCode, text) {
      var code, now;
      code = text === "" ? keyCode : text;
      mode = mode(code);
      now = Date.now() / 1000;
      pressedKeys.push({
        time: now,
        code: code
      });
      return pressedKeys = pressedKeys.filter(function(item) {
        return item.time >= now - 2.0;
      });
    });
    buildFrame = function(root) {
      var aframe, node, _i, _len, _ref;
      aframe = newFrame(root, buildStyle(defaultStyle, {
        indent: 0
      }));
      _ref = aframe.node.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        addFrame(aframe, node);
      }
      aframe.layout(bc);
      return aframe;
    };
    draw = function() {
      var cframe, comm_frame, item, name, near, start, stop, w, x, _i, _len, _ref;
      bc.fillStyle = "#ccc";
      bc.fillRect(0, 0, canvas.width, canvas.height);
      frame = buildFrame(root);
      frame.x = 50;
      frame.y = 50;
      frame.paint(bc);
      comm_frame = null;
      if (command_root != null) {
        comm_frame = buildFrame(command_root);
        comm_frame.x = 50;
        comm_frame.y = canvas.height - comm_frame.height - 16 - 30;
        bc.fillStyle = "#aaa";
        bc.fillRect(0, comm_frame.y, canvas.width, comm_frame.height);
        comm_frame.paint(bc);
      }
      if (((near = frame.nearest.apply(frame, mouse.point)) != null) && near.dist < 100) {
        drawSelection(bc, near.frame, near.index, near.index, "black", "white");
      }
      if ((cursor != null) && (trail != null) && cursor.node === trail.node) {
        if ((cframe = frame.find(cursor.node)) != null) {
          _ref = selectionRange(trail, cursor), start = _ref.start, stop = _ref.stop;
          drawSelection(bc, cframe, start, stop, "blue", "cyan");
        }
      } else if (cursor != null) {
        cframe = frame.find(cursor.node);
        if (cframe != null) {
          drawSelection(bc, cframe, cursor.index, cursor.index, "blue", "cyan");
        }
        if (comm_frame != null) {
          cframe = comm_frame.find(cursor.node);
          if (cframe != null) {
            drawSelection(bc, cframe, cursor.index, cursor.index, "blue", "cyan");
          }
        }
      }
      bc.font = "12px sans-serif";
      bc.fillStyle = 'black';
      bc.fillRect(0, 0, canvas.width, 16);
      bc.fillStyle = 'white';
      bc.fillText(" " + path, 0, 11);
      bc.fillStyle = 'black';
      bc.fillRect(0, canvas.height - 16, canvas.width, 16);
      bc.fillStyle = 'white';
      bc.fillText(" -- " + mode.tag + " --", 0, canvas.height - 5);
      bc.strokeStyle = 'black';
      x = 10;
      for (_i = 0, _len = pressedKeys.length; _i < _len; _i++) {
        item = pressedKeys[_i];
        if (typeof item.code === 'string') {
          name = item.code;
        } else {
          name = keyNames[item.code] || item.code;
        }
        w = bc.measureText(name).width;
        bc.fillStyle = 'white';
        bc.fillRect(x, canvas.height - 40, w + 20, 15);
        bc.strokeRect(x, canvas.height - 40, w + 20, 20);
        bc.fillStyle = 'black';
        bc.fillText(name, x + 10, canvas.height - 30);
        x += w + 30;
      }
      return requestAnimationFrame(draw);
    };
    return draw();
  });

  outerList = function(cursor) {
    if (isText(cursor.node)) {
      cursor = indexBefore(cursor.node);
    }
    return cursor;
  };

  deleteUnder = function(cursor) {
    cursor.node.kill(cursor.index, cursor.index + 1);
    return cursor;
  };

  deleteLeft = function(cursor) {
    var child, index, node, postfix, _ref, _ref1;
    _ref = cursor = cursor, node = _ref.node, index = _ref.index;
    if (isText(node)) {
      if (index > 0) {
        cursor = deleteUnder({
          node: node,
          index: index - 1
        });
        if (node.length === 0 && (node.parent != null)) {
          cursor = deleteUnder(indexBefore(node));
        }
      } else if (node.parent != null) {
        _ref1 = cursor = indexBefore(cursor), node = _ref1.node, index = _ref1.index;
        child = node.list[index - 1];
        if (isText(child)) {
          postfix = node.kill(index, index + 1).list[0];
          cursor = indexBottom(child);
          cursor.node.put(cursor.index, postfix, false);
        } else {
          cursor = deleteLeft(cursor);
        }
      }
    } else if (isList(node)) {
      child = node.list[index - 1];
      if (index === 0 && (node.parent != null)) {
        cursor = indexBefore(node);
        if (node.length === 0) {
          deleteUnder(cursor);
        }
      } else if (isList(child)) {
        cursor = indexBottom(child);
      } else if (isText(child)) {
        cursor = deleteLeft(indexBottom(child));
      } else {
        cursor = deleteUnder({
          node: node,
          index: index - 1
        });
      }
    }
    return cursor;
  };

  deleteRight = function(cursor) {
    var child, index, node, postfix, _ref, _ref1;
    _ref = cursor = cursor, node = _ref.node, index = _ref.index;
    if (isText(node)) {
      if (index < node.length) {
        cursor = deleteUnder({
          node: node,
          index: index
        });
        if (node.length === 0 && (node.parent != null)) {
          cursor = deleteUnder(indexBefore(node));
        }
      } else if (node.parent != null) {
        _ref1 = cursor = indexAfter(cursor), node = _ref1.node, index = _ref1.index;
        child = node.list[index];
        if (isText(child)) {
          postfix = node.kill(index, index + 1).list[0];
          cursor = indexBottom(node.list[index - 1]);
          cursor.node.put(cursor.index, postfix, false);
        } else {
          cursor = deleteRight(cursor);
        }
      }
    } else if (isList(node)) {
      child = node.list[index];
      if (index === node.length && (node.parent != null)) {
        if (node.length === 0) {
          cursor = deleteUnder(indexBefore(node));
        } else {
          cursor = indexAfter(node);
        }
      } else if (isList(child)) {
        cursor = indexTop(child);
      } else if (isText(child)) {
        cursor = deleteRight(indexTop(child));
      } else {
        cursor = deleteUnder({
          node: node,
          index: index
        });
      }
    }
    return cursor;
  };

  splitNode = function(cursor) {
    var index, ins, node, prefix;
    node = cursor.node, index = cursor.index;
    if (isText(node) && (node.parent != null)) {
      if (index === 0) {
        return indexBefore(node);
      }
      if (index === node.length) {
        return indexAfter(node);
      }
      prefix = newList([node.kill(0, index)]);
      ins = indexBefore(node);
      ins.node.put(ins.index, prefix, false);
      return {
        node: node,
        index: 0
      };
    }
    return cursor;
  };

  flowLeft = function(cursor) {
    var index, node;
    node = cursor.node, index = cursor.index;
    if (isText(node) && (node.parent != null)) {
      cursor = liftLeft(indexBefore(node));
    } else if (isList(node)) {
      if (index > 0) {
        cursor = {
          node: node,
          index: index - 1
        };
      } else if (node.parent != null) {
        cursor = indexBefore(node);
      }
    }
    return cursor;
  };

  flowRight = function(cursor) {
    var index, node;
    node = cursor.node, index = cursor.index;
    if (isText(node) && (node.parent != null)) {
      cursor = liftRight(indexAfter(node));
    } else if (isList(node)) {
      if (index < node.length) {
        cursor = {
          node: node,
          index: index + 1
        };
      } else if (node.parent != null) {
        cursor = indexAfter(node);
      }
    }
    return cursor;
  };

  tabLeft = function(cursor) {
    var index, node, _ref;
    _ref = cursor = travelLeft(cursor), node = _ref.node, index = _ref.index;
    if (index === 0 && (node.parent == null)) {
      return cursor;
    }
    if (isList(node) && node.length > 0) {
      return tabLeft(cursor);
    }
    return cursor;
  };

  tabRight = function(cursor) {
    var index, node, _ref;
    _ref = cursor = travelRight(cursor), node = _ref.node, index = _ref.index;
    if (index === node.length && (node.parent == null)) {
      return cursor;
    }
    if (isList(node) && node.length > 0) {
      return tabRight(cursor);
    }
    return cursor;
  };

  stepLeft = function(cursor) {
    var index, node;
    node = cursor.node, index = cursor.index;
    if (isText(node) && 0 < index) {
      cursor = {
        node: node,
        index: index - 1
      };
    } else {
      cursor = travelLeft(cursor);
    }
    return cursor;
  };

  stepRight = function(cursor) {
    var index, node;
    node = cursor.node, index = cursor.index;
    if (isText(node) && index < node.length) {
      cursor = {
        node: node,
        index: index + 1
      };
    } else {
      cursor = travelRight(cursor);
    }
    return cursor;
  };

  travelLeft = function(cursor) {
    var child, index, node;
    node = cursor.node, index = cursor.index;
    if (isText(node) && (node.parent != null)) {
      cursor = travelLeft(indexBefore(node));
    } else if (isList(node)) {
      if (0 < index) {
        child = node.list[index - 1];
        if (isList(child) || isText(child)) {
          cursor = indexBottom(child);
        } else {
          cursor = {
            node: node,
            index: index - 1
          };
        }
      } else if (node.parent != null) {
        cursor = indexBefore(node);
      }
    }
    return liftLeft(cursor);
  };

  travelRight = function(cursor) {
    var child, index, node;
    node = cursor.node, index = cursor.index;
    if (isText(node) && (node.parent != null)) {
      cursor = travelRight(indexAfter(node));
    } else if (isList(node)) {
      if (index < node.length) {
        child = node.list[index];
        if (isList(child) || isText(child)) {
          cursor = indexTop(child);
        } else {
          cursor = {
            node: node,
            index: index + 1
          };
        }
      } else if (node.parent != null) {
        cursor = indexAfter(node);
      }
    }
    return liftRight(cursor);
  };

  liftLeft = function(cursor) {
    var child, index, node;
    node = cursor.node, index = cursor.index;
    if (isList(node)) {
      child = node.list[index - 1];
      if (isText(child)) {
        cursor = indexBottom(child);
      }
    }
    return cursor;
  };

  liftRight = function(cursor) {
    var child, index, node;
    node = cursor.node, index = cursor.index;
    if (isList(node)) {
      child = node.list[index];
      if (isText(child)) {
        cursor = indexTop(child);
      }
    }
    return cursor;
  };

  indexTop = function(node) {
    return {
      node: node,
      index: 0
    };
  };

  indexBottom = function(node) {
    return {
      node: node,
      index: node.length
    };
  };

  indexBefore = function(node) {
    return {
      node: node.parent,
      index: node.parent.indexOf(node)
    };
  };

  indexAfter = function(node) {
    return {
      node: node.parent,
      index: node.parent.indexOf(node) + 1
    };
  };

  selectionRange = function(trail, cursor) {
    var start, stop;
    start = Math.min(trail.index, cursor.index);
    stop = Math.max(trail.index + 1, cursor.index + 1);
    return {
      start: start,
      stop: stop
    };
  };

  drawSelection = function(bc, frame, start, stop, style, listStyle) {
    var parent, x, y, _ref;
    bc.globalAlpha = 1.0;
    if (isList(frame.node)) {
      parent = frame;
      style = listStyle;
    } else {
      parent = frame.parent;
    }
    while ((parent != null) && (parent.parent != null)) {
      bc.strokeStyle = parent.style.selection;
      _ref = parent.getPosition(), x = _ref.x, y = _ref.y;
      bc.strokeRect(x, y, parent.width, parent.height);
      parent = parent.parent;
    }
    bc.globalAlpha = 0.5;
    bc.strokeStyle = style;
    bc.fillStyle = style;
    frame.paintSelection(bc, start, stop);
    return bc.globalAlpha = 1.0;
  };

}).call(this);
