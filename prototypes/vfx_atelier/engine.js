// Real three.quarks batching; the application supplies every simulation step.
class AtelierParticles {
  constructor(parent) {
    this.scene = parent; this.meshes = []; this.systems = [];
    this.materials = new Map(); this.batch = new Q.BatchedRenderer();
    worldScene.add(this.batch); this.activeParticlesCount = 0;
  }
  spawnEmitter(config) {
    const count = Math.max(1, Math.ceil((config.count || 60) * 1.18));
    const c = {...config, size: (config.size || [.6, 1.4]).map(x => x * .66)};
    const key = `${c.texture || 'glow'}:${c.blending ?? THREE.AdditiveBlending}`;
    if (!this.materials.has(key)) this.materials.set(key, new THREE.MeshBasicMaterial({
      map: PARTICLE_TEXTURES[c.texture || 'glow'], transparent: true, depthWrite: false,
      blending: c.blending ?? THREE.AdditiveBlending, side: THREE.DoubleSide,
      toneMapped: false
    }));
    const engine = this; let index = 0;
    const behavior = {
      type: 'AtelierMotion', initialize(p) {
        const s = engine._initParticle(c, c.origin || new THREE.Vector3(), index++, count);
        if(index%4===0){s.sizeStart*=.26;s.vel.multiplyScalar(1.25);}
        p.atelier = s; p.life = s.maxLife + s.delay;
        p.velocity.set(0, 0, 0); p.position.copy(s.pos); p.color.w = 0;
      },
      update(p, dt) {
        const s = p.atelier, age = p.age - s.delay;
        if (age < 0) { p.color.w = 0; return; }
        const t = Math.min(1, age / s.maxLife);
        if (s.orbitSpeed) {
          const angle = s.orbitAngle + s.orbitSpeed * age;
          const radius = Math.max(.05, s.orbitRadius * (1 + s.radialRate * t));
          s.pos.set(s.origin.x + Math.cos(angle) * radius, s.origin.y + s.vel.y * age, s.origin.z + Math.sin(angle) * radius);
        } else {
          s.vel.y -= s.gravity * dt; s.vel.multiplyScalar(Math.pow(s.drag, dt * 60));
          s.pos.addScaledVector(s.vel, dt);
        }
        if (c.bounceFloor && s.pos.y < .08 && s.vel.y < 0) {
          s.pos.y = .08; s.vel.y *= -.45; s.vel.x *= .72; s.vel.z *= .72;
        }
        p.position.copy(s.pos); p.rotation = s.angle + s.spin * age;
        const col = s.colorStart.clone();
        if (s.colorMid) col.copy(t < .5 ? s.colorStart : s.colorMid).lerp(t < .5 ? s.colorMid : s.colorEnd, t < .5 ? t * 2 : (t - .5) * 2);
        else col.lerp(s.colorEnd, t);
        const alpha = t < .1 ? t / .1 : Math.pow((1 - t) / .9, 1.35);
        p.color.set(col.r * 1.22, col.g * 1.22, col.b * 1.22, alpha * (c.opacity ?? 1));
        p.size.setScalar(Math.max(.001, s.sizeStart * (c.sizeBell ? Math.sin(t * Math.PI) : 1 - Math.pow(t, 1.45))));
      }, frameUpdate() {}, reset() {}, clone() { return this; }
    };
    const system = new Q.ParticleSystem({duration: .02, looping: false,
      shape: new Q.SphereEmitter({radius: 0}), startLife: new Q.ConstantValue(1),
      startSpeed: new Q.ConstantValue(0), startSize: new Q.ConstantValue(1),
      startColor: new Q.ConstantColor(new THREE.Vector4(1, 1, 1, 1)),
      emissionOverTime: new Q.ConstantValue(0), emissionBursts: [{time: 0, count: new Q.ConstantValue(count), cycle: 1, interval: 0, probability: 1}],
      worldSpace: false, material: this.materials.get(key), behaviors: [behavior]
    });
    this.scene.add(system.emitter); this.scene.updateMatrixWorld(true);
    this.batch.addSystem(system); this.systems.push(system); return system;
  }
  // _initParticle is retained from the supplied source by prepare.py.
  spawnAnimatedMesh(mesh, duration, onUpdate, delay = 0) {
    mesh.visible = delay <= 0; this.scene.add(mesh);
    this.meshes.push({mesh, duration, onUpdate, delay, age: 0}); return mesh;
  }
  update(dt) {
    this.scene.updateMatrixWorld(true); this.batch.update(dt);
    this.activeParticlesCount = 0;
    for (let i = this.systems.length - 1; i >= 0; --i) {
      const s = this.systems[i]; this.activeParticlesCount += s.particleNum;
      if (s.emissionState.time > .02 && s.particleNum === 0) {
        this.batch.deleteSystem(s); s.dispose(); this.systems.splice(i, 1);
      }
    }
    for (const item of [...this.meshes]) {
      item.age += dt;
      if (item.age < item.delay) continue;
      item.mesh.visible = true;
      const activeDt = Math.min(item.age - item.delay, dt);
      item.onUpdate?.(Math.min(1, (item.age - item.delay) / item.duration), item.mesh, activeDt);
      if (item.age >= item.delay + item.duration) {
        item.mesh.removeFromParent(); disposeTree(item.mesh);
        this.meshes.splice(this.meshes.indexOf(item), 1);
      }
    }
  }
  dispose() {
    for (const s of this.systems) { this.batch.deleteSystem(s); s.dispose(); }
    disposeTree(this.batch); this.batch.removeFromParent();
    for (const m of this.materials.values()) m.dispose();
    this.systems.length = 0;
  }
}

function disposeTree(root) {
  const geometries = new Set(), materials = new Set();
  root.traverse(o => { if (o.geometry) geometries.add(o.geometry);
    if (o.material) (Array.isArray(o.material) ? o.material : [o.material]).forEach(m => materials.add(m)); });
  geometries.forEach(g => g.dispose()); materials.forEach(m => m.dispose());
}

// One owner for event time. Split a step exactly at each pending event boundary.
class Timeline {
  constructor() { this.time = 0; this.queue = []; this.nextId = 0; }
  after(ms, fn) { this.queue.push({time: this.time + ms / 1000, fn, id: this.nextId++}); }
  advance(dt, draw) {
    const end = this.time + dt;
    while (true) {
      this.queue.sort((a, b) => a.time - b.time || a.id - b.id);
      const event = this.queue[0];
      if (!event || event.time > end + 1e-9) break;
      const step = Math.max(0, event.time - this.time);
      if (step > 1e-9) draw(step);
      this.time = event.time; this.queue.shift(); event.fn();
    }
    const tail = end - this.time; if (tail > 1e-9) draw(tail); this.time = end;
  }
}
