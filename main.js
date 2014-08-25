// Generated by CoffeeScript 1.6.3
(function() {
  var addFrame, buildStyle, condStyle, defaultStyle, deleteLeft, deleteRight, deleteUnder, drawSelection, flowLeft, flowRight, indexAfter, indexBefore, indexBottom, indexTop, labelStyle, liftLeft, liftRight, splitNode, stepLeft, stepRight, tabLeft, tabRight, travelLeft, travelRight;

  defaultStyle = {
    fontName: "sans-serif",
    fontSize: 16,
    topPadding: 0,
    leftPadding: 0,
    rightPadding: 0,
    bottomPadding: 0,
    spacing: 5,
    indent: 10,
    verticalSpacing: 0,
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

  addFrame = function(container, node) {
    var first, frame, item, row, subitem, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _ref, _ref1, _ref2, _ref3, _ref4;
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
        } else {
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
    } else if (isList(node)) {
      container.push(frame = newFrame(node, buildStyle(defaultStyle, {
        selection: "blue"
      })));
      if (node.label != null) {
        frame.push(newDeco(node.label, labelStyle));
      }
      _ref4 = node.list;
      for (_m = 0, _len4 = _ref4.length; _m < _len4; _m++) {
        item = _ref4[_m];
        addFrame(frame, item);
      }
    } else if (isText(node, 'int')) {
      container.push(frame = newFrame(node, buildStyle(container.style, {
        color: "blue"
      })));
    } else {
      container.push(frame = newFrame(node, container.style));
    }
    return null;
  };

  window.addEventListener('load', function() {
    var bc, canvas, cursor, draw, frame, insertMode, mode, mouse, root, selectMode, visualMode;
    canvas = autoResize(document.getElementById('editor'));
    bc = canvas.getContext('2d');
    mouse = mouseInput(canvas);
    root = newList([newList([newList([newText("square"), newText("x")]), newMark('cr'), newList([newText("x"), newText("*"), newText("x")], 'infix')], 'define'), newList([newList([newText("factorial"), newText("n")]), newMark('cr'), newList([newList([newList([newText("n"), newText("="), newText("1", "int")], 'infix'), newMark("cr"), newText("1", "int")]), newList([newList([newText("n"), newText("="), newText("0", "int")], 'infix'), newMark("cr"), newText("1", "int")]), newList([newMark("cr"), newList([newText("n"), newText("*"), newList([newText("factorial"), newList([newText("n"), newText("-"), newText("1", "int")], 'infix')])], 'infix')], 'else')], 'cond')], 'define')]);
    cursor = liftRight({
      index: 0,
      node: root
    });
    frame = null;
    canvas.addEventListener('click', function(ev) {
      var near;
      ev.preventDefault();
      if ((near = frame.nearest.apply(frame, mouse.point)) != null) {
        return cursor = {
          index: near.index,
          node: near.frame.node
        };
      }
    });
    selectMode = function(code) {
      var index, lst, node;
      if (code === "i") {
        return insertMode;
      }
      if (code === "v") {
        return visualMode;
      }
      if (code === "h") {
        cursor = stepLeft(cursor);
      }
      if (code === "l") {
        cursor = stepRight(cursor);
      }
      if (code === "j") {
        cursor = flowLeft(cursor);
      }
      if (code === "k") {
        cursor = flowRight(cursor);
      }
      if (code === "w") {
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
          cursor = indexTop(cursor.node);
        } else {
          cursor = tabLeft(cursor);
          if (isText(cursor.node)) {
            cursor = indexTop(cursor.node);
          }
        }
      }
      if (code === "<" && (cursor.node.parent != null)) {
        node = cursor.node, index = cursor.index;
        lst = node.parent;
        index = lst.indexOf(node);
        if (index > 0) {
          lst.put(index - 1, lst.kill(index, index + 1), false);
        }
      }
      if (code === ">" && (cursor.node.parent != null)) {
        node = cursor.node, index = cursor.index;
        lst = node.parent;
        index = lst.indexOf(node);
        if (index < lst.length - 1) {
          lst.put(index + 1, lst.kill(index, index + 1), false);
        }
      }
      if (code === " " && isText(cursor.node)) {
        if (cursor.index === 0) {
          cursor = indexBefore(cursor.node);
        }
        if (cursor.index === cursor.node.length) {
          cursor = indexAfter(cursor.node);
        }
      }
      return selectMode;
    };
    selectMode.tag = "select";
    insertMode = function(code) {
      var newlabel, node;
      if (code === 27) {
        return selectMode;
      } else if (code === " ") {
        cursor = splitNode(cursor);
      } else if (code === 13) {
        cursor = splitNode(splitNode(cursor));
        cursor.node.put(cursor.index, newList([newMark('cr')]), false);
        cursor.index += 1;
      } else if (code === "(") {
        cursor = splitnode(splitNode(cursor));
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
      } else if (code === 8) {
        cursor = deleteLeft(cursor);
      } else if (code === 46) {
        cursor = deleteRight(cursor);
      } else if (typeof code === 'string') {
        if (isText(cursor.node)) {
          cursor.node.put(cursor.index, newText(code), false);
          cursor.index += 1;
        } else if (isList(cursor.node)) {
          cursor.node.put(cursor.index, newList([node = newText(code)]), false);
          cursor.node = node;
          cursor.index = 1;
        }
      }
      return insertMode;
    };
    insertMode.tag = "insert";
    visualMode = function(code) {
      if (code === 27) {
        return selectMode;
      }
      return mode;
    };
    visualMode.tag = "visual";
    mode = selectMode;
    keyboardEvents(canvas, function(keyCode, text) {
      var code;
      code = text === "" ? keyCode : text;
      return mode = mode(code);
    });
    draw = function() {
      var cframe, first, near, node, _i, _len, _ref;
      bc.fillStyle = "#ccc";
      bc.fillRect(0, 0, canvas.width, canvas.height);
      frame = newFrame(root, buildStyle(defaultStyle, {
        indent: 0,
        verticalSpacing: 25
      }));
      first = true;
      _ref = frame.node.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        if (!first) {
          frame.newline();
        }
        addFrame(frame, node);
        first = false;
      }
      frame.layout(bc);
      frame.x = 50;
      frame.y = 50;
      frame.paint(bc);
      if ((near = frame.nearest.apply(frame, mouse.point)) != null) {
        drawSelection(bc, near.frame, near.index, near.index, "black");
      }
      if (cursor != null) {
        cframe = frame.find(cursor.node);
        if (cframe != null) {
          drawSelection(bc, cframe, cursor.index, cursor.index, "blue");
        }
      }
      bc.font = "12px sans-serif";
      bc.fillStyle = 'black';
      bc.fillRect(0, 0, canvas.width, 16);
      bc.fillStyle = 'white';
      bc.fillText(" index [] ", 0, 11);
      bc.fillStyle = 'black';
      bc.fillText(" Some commands in the help are missing due to an update.", 0, 30);
      bc.fillRect(0, canvas.height - 16, canvas.width, 16);
      bc.fillStyle = 'white';
      bc.fillText(" -- " + mode.tag + " --", 0, canvas.height - 5);
      return requestAnimationFrame(draw);
    };
    return draw();
  });

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

  drawSelection = function(bc, frame, start, stop, style) {
    var parent, x, y, _ref;
    bc.globalAlpha = 0.1;
    parent = frame.parent;
    while (parent != null) {
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
