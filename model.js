// Generated by CoffeeScript 1.6.3
(function() {
  var Carriage, ListBuffer, ListNode, TextBuffer, TextNode,
    __slice = [].slice;

  window.hoverColor = "#222";

  window.selectColor = "#888";

  window.selectCompositeOp = "darker";

  window.padding = 8;

  ListNode = (function() {
    function ListNode(list) {
      var item, _i, _len, _ref;
      this.list = list;
      this.type = 'list';
      this.parent = null;
      this.length = this.list.length;
      this.hover = false;
      this.hoverIndex = 0;
      _ref = this.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        item.parent = this;
      }
    }

    ListNode.prototype.copy = function() {
      var item, list, _i, _len, _ref;
      list = [];
      _ref = this.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        list.push(item.copy());
      }
      return new ListNode(list);
    };

    ListNode.prototype.yank = function(start, stop) {
      return new ListBuffer(this.list.slice(start, stop), this);
    };

    ListNode.prototype.kill = function(start, stop) {
      var item, list, _i, _len, _ref;
      list = this.list.slice(start, stop);
      [].splice.apply(this.list, [start, stop - start].concat(_ref = [])), _ref;
      this.length = this.list.length;
      for (_i = 0, _len = list.length; _i < _len; _i++) {
        item = list[_i];
        item.parent = null;
      }
      return new ListBuffer(list, null);
    };

    ListNode.prototype.put = function(index, buff) {
      var item, list, _i, _len;
      if (buff.type !== "listbuffer") {
        throw "buffer conflict";
      }
      if (buff.link != null) {
        list = (function() {
          var _i, _len, _ref, _results;
          _ref = buff.list;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            item = _ref[_i];
            _results.push(item.copy());
          }
          return _results;
        })();
      } else {
        list = buff.list;
        buff.link = this;
      }
      for (_i = 0, _len = list.length; _i < _len; _i++) {
        item = list[_i];
        item.parent = this;
      }
      [].splice.apply(this.list, [index, index - index].concat(list)), list;
      return this.length = this.list.length;
    };

    ListNode.prototype.get = function(index) {
      if (!((0 <= index && index < this.length))) {
        return null;
      }
      return this.list[index];
    };

    ListNode.prototype.getRange = function() {
      var start, stop;
      if (this.parent == null) {
        return null;
      }
      start = this.parent.list.indexOf(this);
      stop = start + 1;
      return {
        target: this.parent,
        start: start,
        stop: stop
      };
    };

    ListNode.prototype.mousemotion = function(x, y) {
      var childhover, item, o, over, row, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
      x -= this.x;
      y -= this.y;
      childhover = null;
      _ref = this.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        over = item.mousemotion(x, y);
        childhover = childhover || over;
      }
      this.hover = ((0 <= x && x < this.width)) && ((0 <= y && y < this.height)) && !childhover;
      _ref1 = this.rows;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        row = _ref1[_j];
        if ((row.offset <= y && y < row.offset + row.height + padding)) {
          this.hoverIndex = row.start;
          _ref2 = row.offsets;
          for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
            o = _ref2[_k];
            if (x < o) {
              break;
            }
            this.hoverIndex += 1;
          }
          this.hoverIndex = Math.max(this.hoverIndex - 1, row.start);
        }
      }
      if (y < padding) {
        this.hoverIndex = 0;
      }
      if (y > this.height) {
        this.hoverIndex = this.length;
      }
      if (childhover != null) {
        return childhover;
      }
      if (this.hover) {
        return this;
      } else {
        return null;
      }
    };

    ListNode.prototype.layout = function(bc) {
      var item, offset, row, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
      this.x = 0;
      this.y = 0;
      this.width = 0;
      this.height = 0;
      this.rows = [];
      this.rows.push(row = {
        offset: padding,
        offsets: [padding],
        frames: [],
        height: 16,
        start: 0,
        stop: 0
      });
      offset = padding;
      _ref = this.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        item.layout(bc);
        if (item.type === 'cr') {
          row.stop = row.start + row.frames.length;
          this.rows.push(row = {
            offset: row.offset + row.height + padding,
            offsets: [padding],
            frames: [],
            height: 16,
            start: row.stop + 1,
            stop: row.stop + 1
          });
          this.width = Math.max(offset, this.width);
          this.height = Math.max(row.offset + row.height + 2 * padding, this.height);
          offset = padding;
        } else {
          item.x = offset;
          item.y = row.offset;
          offset += padding + item.width;
          row.offsets.push(offset);
          row.frames.push(item);
          row.height = Math.max(row.height, item.height);
        }
      }
      row.stop = row.start + row.frames.length;
      this.width = Math.max(offset, this.width);
      this.height = Math.max(row.offset + row.height + padding, this.height);
      _ref1 = this.rows;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        row = _ref1[_j];
        _ref2 = row.frames;
        for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
          item = _ref2[_k];
          item.y += row.height / 2 - item.height / 2;
        }
      }
      if (this.rows.length > 1) {
        this.width += padding;
      }
      if (this.rows.length > 1) {
        return this.height += padding;
      }
    };

    ListNode.prototype.draw = function(bc) {
      var item, _i, _len, _ref;
      bc.fillStyle = "white";
      bc.strokeStyle = "black";
      if (this.hover) {
        bc.strokeStyle = hoverColor;
      }
      bc.fillRect(this.x, this.y, this.width, this.height);
      if (this.parent != null) {
        if (this.rows.length === 1) {
          bc.strokeRect(this.x, this.y + padding / 2, this.width, 0);
          bc.strokeRect(this.x, this.y + this.height - padding / 2, this.width, 0);
        } else {
          bc.strokeRect(this.x, this.y, 0, this.height);
          bc.strokeRect(this.x + this.width, this.y, 0, this.height);
        }
      }
      bc.save();
      bc.translate(this.x, this.y);
      _ref = this.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        item.draw(bc);
      }
      return bc.restore();
    };

    ListNode.prototype.getPosition = function() {
      var x, y, _ref;
      x = y = 0;
      if (this.parent) {
        _ref = this.parent.getPosition(), x = _ref.x, y = _ref.y;
      }
      return {
        x: x + this.x,
        y: y + this.y
      };
    };

    ListNode.prototype.drawSelection = function(bc, start, stop) {
      var left, right, row, x, y, _i, _len, _ref, _ref1, _ref2;
      _ref = this.getPosition(), x = _ref.x, y = _ref.y;
      bc.fillStyle = selectColor;
      bc.globalCompositeOperation = selectCompositeOp;
      _ref1 = this.rows;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        row = _ref1[_i];
        if (stop < row.start) {
          continue;
        }
        if (row.stop < start) {
          continue;
        }
        if (row.start <= start) {
          left = row.offsets[start - row.start] - 1;
        } else {
          left = 0;
        }
        if (stop === start) {
          right = left - 2;
          left -= padding - 4;
        } else if (stop === row.start) {
          right = row.offsets[0];
        } else if (stop <= row.stop) {
          right = row.offsets[stop - row.start] - padding + 1;
        } else {
          right = this.width;
        }
        if (right < left) {
          _ref2 = [right, left], left = _ref2[0], right = _ref2[1];
        }
        bc.fillRect(x + left, y + row.offset - 1, right - left, row.height + padding);
      }
      return bc.globalCompositeOperation = "source-over";
    };

    return ListNode;

  })();

  TextNode = (function() {
    function TextNode(text) {
      this.text = text;
      this.type = 'text';
      this.parent = null;
      this.hover = false;
      this.length = this.text.length;
      this.offsets = [];
      this.hoverIndex = 0;
    }

    TextNode.prototype.copy = function() {
      return new TextNode(this.text);
    };

    TextNode.prototype.yank = function(start, stop) {
      return new TextBuffer(this.text.slice(start, stop), this);
    };

    TextNode.prototype.kill = function(start, stop) {
      var text;
      text = this.text.slice(start, stop);
      this.text = this.text.slice(0, start) + this.text.slice(stop);
      this.length = this.text.length;
      return new TextBuffer(text, null);
    };

    TextNode.prototype.put = function(index, buff) {
      if (buff.type !== "textbuffer") {
        throw "buffer conflict";
      }
      this.text = this.text.slice(0, index) + buff.text + this.text.slice(index);
      return this.length = this.text.length;
    };

    TextNode.prototype.layout = function(bc) {
      var i, _i, _ref, _results;
      bc.font = "16px sans-serif";
      this.x = 0;
      this.y = 0;
      this.width = bc.measureText(this.text).width;
      this.height = 16;
      this.offsets = [0];
      _results = [];
      for (i = _i = 1, _ref = this.length; 1 <= _ref ? _i <= _ref : _i >= _ref; i = 1 <= _ref ? ++_i : --_i) {
        _results.push(this.offsets.push(bc.measureText(this.text.slice(0, i)).width));
      }
      return _results;
    };

    TextNode.prototype.getRange = function() {
      var start, stop;
      if (this.parent == null) {
        return null;
      }
      start = this.parent.list.indexOf(this);
      stop = start + 1;
      return {
        target: this.parent,
        start: start,
        stop: stop
      };
    };

    TextNode.prototype.mousemotion = function(x, y) {
      var o, _i, _len, _ref;
      this.hover = ((this.x <= x && x < this.x + this.width)) && ((this.y <= y && y < this.y + this.height));
      this.hoverIndex = 0;
      _ref = this.offsets;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        o = _ref[_i];
        if (x < o + this.x) {
          break;
        }
        this.hoverIndex += 1;
      }
      this.hoverIndex = Math.max(this.hoverIndex - 1, 0);
      if (this.hover) {
        return this;
      }
      return null;
    };

    TextNode.prototype.draw = function(bc) {
      bc.font = "16px sans-serif";
      bc.fillStyle = "black";
      if (this.hover) {
        bc.fillStyle = hoverColor;
      }
      return bc.fillText(this.text, this.x, this.y + this.height / 2, this.width);
    };

    TextNode.prototype.getPosition = function() {
      var x, y, _ref;
      x = y = 0;
      if (this.parent) {
        _ref = this.parent.getPosition(), x = _ref.x, y = _ref.y;
      }
      return {
        x: x + this.x,
        y: y + this.y
      };
    };

    TextNode.prototype.drawSelection = function(bc, start, stop) {
      var left, right, x, y, _ref;
      _ref = this.getPosition(), x = _ref.x, y = _ref.y;
      left = this.offsets[start] - 1;
      right = this.offsets[stop] + 1;
      bc.fillStyle = selectColor;
      bc.globalCompositeOperation = selectCompositeOp;
      bc.fillRect(x + left, y, right - left, this.height);
      return bc.globalCompositeOperation = "source-over";
    };

    return TextNode;

  })();

  Carriage = (function() {
    function Carriage(list) {
      this.list = list;
      this.type = 'cr';
    }

    Carriage.prototype.copy = function() {
      return new Carriage();
    };

    Carriage.prototype.mousemotion = function(x, y) {
      return false;
    };

    Carriage.prototype.layout = function(bc) {
      this.x = 0;
      this.y = 0;
      this.height = 0;
      return this.width = 0;
    };

    Carriage.prototype.draw = function(bc) {};

    return Carriage;

  })();

  ListBuffer = (function() {
    function ListBuffer(list, link) {
      this.list = list;
      this.link = link;
      this.type = "listbuffer";
    }

    return ListBuffer;

  })();

  TextBuffer = (function() {
    function TextBuffer(text, link) {
      this.text = text;
      this.link = link;
      this.type = "textbuffer";
    }

    return TextBuffer;

  })();

  window.cr = function() {
    return new Carriage();
  };

  window.text = function(text) {
    return new TextNode(text);
  };

  window.list = function() {
    var data;
    data = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return new ListNode(data);
  };

  window.listbuffer = function() {
    var list;
    list = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return new ListBuffer(list, null);
  };

  window.textbuffer = function(text) {
    return new TextBuffer(text, null);
  };

  window.isText = function(node) {
    return (node != null) && node.type === 'text';
  };

  window.isList = function(node) {
    return (node != null) && node.type === 'list';
  };

  window.isCr = function(node) {
    return (node != null) && node.type === 'cr';
  };

  window.nodeType = function(node) {
    if (!((node != null) && (node.type != null))) {
      return null;
    }
    return node.type;
  };

}).call(this);
