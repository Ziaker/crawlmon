(function(root, f) {
  if (typeof module === 'object' && module.exports) module.exports = f();
  else root.MS_Parts = f();
})(typeof window !== 'undefined' ? window : globalThis, function() {
  'use strict';

  var DEG = Math.PI / 180;

  var AXES = { x: [1, 0, 0], y: [0, 1, 0], z: [0, 0, 1] };

  function wedges(count, startDeg) {
    startDeg = startDeg == null ? 0 : startDeg;
    var step = 360 / count;
    var out = [];
    for (var i = 0; i < count; i++) {
      var a0 = startDeg + i * step;
      var a1 = a0 + step;
      var mid = (a0 + a1) / 2;
      var planes;
      if (step < 180) {
        var r0 = (a0 + 90) * DEG;
        var r1 = (a1 - 90) * DEG;
        planes = [
          { n: [Math.cos(r0), Math.sin(r0), 0], c: 0 },
          { n: [Math.cos(r1), Math.sin(r1), 0], c: 0 }
        ];
      } else {
        var rm = mid * DEG;
        planes = [{ n: [Math.cos(rm), Math.sin(rm), 0], c: 0 }];
      }
      out.push({ index: i, a0: a0, a1: a1, mid: mid, planes: planes });
    }
    return out;
  }

  function slabs(count, axis, extent) {
    axis = axis || 'x';
    extent = extent == null ? 1 : extent;
    var base = AXES[axis] || AXES.x;
    var neg = [-base[0], -base[1], -base[2]];
    var width = extent / count;
    var half = extent / 2;
    var OPEN = 1e6;
    var out = [];
    for (var i = 0; i < count; i++) {
      var lo = -half + i * width;
      var hi = lo + width;
      if (i === 0) lo = -OPEN;
      if (i === count - 1) hi = OPEN;
      var center = (lo + hi) / 2;
      var planes = [
        { n: base.slice(), c: -lo },
        { n: neg.slice(), c: hi }
      ];
      out.push({ index: i, axis: axis, lo: lo, hi: hi, center: center, planes: planes });
    }
    return out;
  }

  function keeps(planes, p) {
    var z = p[2] === undefined ? 0 : p[2];
    for (var i = 0; i < planes.length; i++) {
      var pl = planes[i];
      var n = pl.n;
      if (n[0] * p[0] + n[1] * p[1] + n[2] * z + pl.c < 0) return false;
    }
    return true;
  }

  function staggerFactor(stagger, index, count) {
    if (stagger === 'alternate') return (index % 2 === 0) ? 1 : -1;
    if (stagger === 'progressive') return index - (count - 1) / 2;
    return 1;
  }

  function offset(part, params, count) {
    params = params || {};
    var sep = params.separation || 0;
    var sh = params.shiftH || 0;
    var sv = params.shiftV || 0;
    var stag = params.stagger || 'none';
    var index = part && part.index !== undefined ? part.index : 0;
    var dx = 0, dy = 0, dz = 0;
    if (part && part.mid !== undefined && part.mid !== null) {
      var r = part.mid * DEG;
      dx += Math.cos(r) * sep;
      dy += Math.sin(r) * sep;
    } else if (part && part.axis) {
      var base = AXES[part.axis] || AXES.x;
      var k = sep * (index - (count - 1) / 2);
      dx += base[0] * k;
      dy += base[1] * k;
      dz += base[2] * k;
    }
    var f = staggerFactor(stag, index, count);
    dx += sh * f;
    dy += sv * f;
    return [dx, dy, dz];
  }

  function lerp(a, b, u) {
    return a + (b - a) * u;
  }

  function lerpParams(a, b, u) {
    return {
      separation: lerp(a.separation, b.separation, u),
      shiftH: lerp(a.shiftH, b.shiftH, u),
      shiftV: lerp(a.shiftV, b.shiftV, u),
      stagger: u >= 0.5 ? b.stagger : a.stagger
    };
  }

  return {
    wedges: wedges,
    slabs: slabs,
    offset: offset,
    lerpParams: lerpParams,
    keeps: keeps
  };
});
