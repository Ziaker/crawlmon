(function (root, f) {
  if (typeof module === 'object' && module.exports) module.exports = f();
  else root.MS_History = f();
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  function create(options) {
    var opts = options || {};
    var getState = opts.getState;
    var setState = opts.setState;
    var limit = opts.limit === undefined ? 200 : Math.floor(Number(opts.limit));
    var coalesceMs = opts.coalesceMs === undefined ? 400 : Number(opts.coalesceMs);
    var now = typeof opts.now === 'function' ? opts.now : function () { return Date.now(); };

    if (typeof getState !== 'function') throw new TypeError('MS_History: getState must be a function');
    if (typeof setState !== 'function') throw new TypeError('MS_History: setState must be a function');
    if (!isFinite(limit) || limit < 1) limit = 1;
    if (!isFinite(coalesceMs) || coalesceMs < 0) coalesceMs = 0;

    var entries = [];
    var index = 0;
    var listeners = [];
    var restoring = false;
    var h;

    function snapshot() {
      return JSON.stringify(getState());
    }

    function notify() {
      var copy = listeners.slice();
      for (var i = 0; i < copy.length; i++) copy[i](h);
    }

    function restore() {
      restoring = true;
      try {
        setState(JSON.parse(entries[index].json));
      } finally {
        restoring = false;
      }
    }

    entries.push({ label: 'Início', json: snapshot(), t: now(), key: null });

    function commit(label, coalesceKey) {
      if (restoring) return false;
      var json = snapshot();
      var current = entries[index];
      if (current.json === json) return false;

      var key = coalesceKey === undefined ? null : coalesceKey;
      var t = now();

      if (key !== null && current.key !== null && current.key === key && (t - current.t) <= coalesceMs) {
        current.json = json;
        current.t = t;
        notify();
        return true;
      }

      entries.splice(index + 1);
      entries.push({ label: label, json: json, t: t, key: key });
      index = entries.length - 1;
      while (entries.length > limit) {
        entries.shift();
        index--;
      }
      notify();
      return true;
    }

    function undo() {
      if (index <= 0) return false;
      index--;
      restore();
      notify();
      return true;
    }

    function redo() {
      if (index >= entries.length - 1) return false;
      index++;
      restore();
      notify();
      return true;
    }

    function jump(i) {
      var target = Math.floor(Number(i));
      if (!isFinite(target)) return false;
      if (target < 0) target = 0;
      if (target > entries.length - 1) target = entries.length - 1;
      if (target === index) return false;
      index = target;
      restore();
      notify();
      return true;
    }

    function clear() {
      entries = [{ label: 'Início', json: snapshot(), t: now(), key: null }];
      index = 0;
      notify();
    }

    function onChange(cb) {
      if (typeof cb !== 'function') throw new TypeError('MS_History: onChange needs a function');
      listeners.push(cb);
      return function () {
        var at = listeners.indexOf(cb);
        if (at >= 0) listeners.splice(at, 1);
      };
    }

    h = {
      commit: commit,
      undo: undo,
      redo: redo,
      jump: jump,
      clear: clear,
      onChange: onChange,
      canUndo: function () { return index > 0; },
      canRedo: function () { return index < entries.length - 1; },
      list: function () {
        return entries.map(function (e, i) {
          return { index: i, label: e.label, t: e.t, current: i === index };
        });
      },
      get index() { return index; },
      get size() { return entries.length; }
    };

    return h;
  }

  return { create: create };
});
