# Dead-Lined

**Genre:** Arcade Bullet-Hell with Tower Defense  
**Platform:** PC

For development setup and code architecture, see [README.md](README.md).

---

## 🎮 Game Overview: Core, Twist, Hook

### The Hook (Elevator Pitch)
**A bullet hell tower defence game where your turrets target you too.**

Survive increasingly difficult rounds of buggy hostile drones by dodging their attacks. Spend your own capacity on building a cohort of turrets to aid your defense, however, turrets are also buggy and target you as well. Managing your capacity and turret setup can quickly become chaotic, and loss of all capacity leads to burn out.
### Core Gameplay
1. **Dodging**: Use movement and dashing to dodge incoming attacks from drones or turrets. Lure drones away from your turrets, when they are under heavy attack. 
2. **Manage Turrets** : Spend capactity on placing and upgrading turrets during Lunch Time to multiply your firepower. Keep them alive by luring enemies away and repairing the turret, when they are low on capacity. 
3. **Fire your weapon**: You have a weak free fire weapon, which can be used to defend yourself, but is to weak to rely on.
3. **Crunch Time Mode**: Pick up a rare powerup dropped by enemies, then activate it to become invincible, switch to the wrench as your only weapon, and gain combat buffs.

### The Unique Twist
**Turrets as Double-Edged Sword:**
- Unlike traditional tower defense, turrets aren't reliable helpers—they're buggy and target both enemies and you
- Creates constant risk/reward tension: build turrets for firepower = higher friendly fire risk
- Upgrading turrets to max level makes them safe (only shoot enemies)

**Crunch Time Inversion:**
- Normal play: you dodge while turrets assist
- Crunch Time: wrench only, invincible, must be aggressive and close-range
- Switching modes forces different playstyles

### Design Philosophy
**Every element serves the core:** Dodging is primary skill. Turrets are strategic layer. Capacity gates turret building to create meaningful decisions; Crunch Time is a rare, earned burst. Nothing distracts from the core loop.

---

## 🕹️ Gameplay Loop

### Build Phase
**Duration:** Configurable timer (auto-ends)

**What you do:**
- Place new turrets (costs capacity)
- Upgrade existing turrets by holding Upgrade on the turret panel (costs capacity; each level applies a buff)
- Sell turrets by holding Sell (refunds 75% of everything spent on that turret, capped at max capacity)
- Repair damaged turrets by when in proximity, in build or combat phase (drains capacity while repairing)
- Collect leftover enemy capacity orbs
- Shoot the green, left-positioned lever to end the build phase and start combat early

**Risk/Reward:**
- Building costs capacity but reduces enemy density
- Too many turrets = friendly fire risk
- Max-level turrets stop targeting you (their shots and shockwaves can still hit you)

### Combat Phase
**Duration:** Ends when all enemies in the wave are destroyed

**What you do:**
- Dodge incoming attacks (PRIMARY SKILL)
- Pull aggro off turrets: enemies always go for the player within 100 px, and only switch to a turret when it is more than 80 px closer than the player (they come back once the player is within 40 px of the turret's distance)
- Dash: the player is invincible from the moment dash is pressed until the dash ends. A quick tap (released within 0.15 s) is a normal 120 px dash. Holding longer charges it: time slows (0.5×, still steering), the player glows white, and releasing dashes in the movement direction (or facing direction when standing still). Distance grows linearly from 120 px to 300 px at 0.5 s after the press (real time, auto-fires). No shooting or activating Crunch Time while the button is held.
- Shoot enemies freely (0.25s cooldown, 0 capacity cost)
- Activate a carried Crunch Time powerup
- Manage capacity by surviving hits

**Escalation:** Each wave spawns more enemies, faster bullets, higher difficulty

### Crunch Time (Power-Up Mode)
**Powerup:** Each enemy has a small chance (2% by default, set per enemy type) to drop a Crunch Time powerup: an orb with its own look that lasts longer on the ground. Every turret standing on the map raises that chance (+2% each, capped at +15%), so a turret-heavy board — which is harder to dodge in — hands out more escapes. Touching it picks it up and it trails behind the player. Only one can be carried, and none can be picked up while Crunch Time is running; the rest stay on the ground.

**Activation:** Press Crunch Time (C) during combat while carrying the powerup. It is used up on activation and lasts 5 seconds. No capacity cost.

**Losing it:** The carried powerup disappears if the player is hit, or when the round ends unused. Uncollected powerups disappear as soon as combat ends, or after their lifetime. 

Leftover capacity orbs stay through the build phase so they can still be collected, and clear when the next wave starts.

**Effect:**
- Invincibility during Crunch Time and for 0.5 seconds after it ends
- Wrench becomes your only weapon (shooting disabled)
- Combat buffs: 3x damage, faster swings, 2x radius, 1.5x speed

**Caveat:** You must be aggressive and close-range, and no powerups drop while Crunch Time is active. Orbs are suppressed too, unless the playtest toggle `drop_orbs_during_crunch_time` is enabled.

---

## 📊 Resource System: Capacity (Single Resource)

**Single unified resource (0–100%) that governs everything:**

| Action | Cost | Effect |
|--------|------|--------|
| Take damage | 1-20% | Direct deduction |
| Build turret | 10-20% | Strategy cost |
| Upgrade turret | Escalates | Reliability cost |
| Sell turret | Refund | Returns 75% of the turret's total cost |
| Repair turret | Continuous | Restores turret health while held |
| Collect orbs | +5-10% | Resource generation |

**Strategic Tension:** Build turrets to help combat, but every turret spends the same capacity that keeps you alive.

**Death Condition:** Capacity reaches 0% → Player burns out and Game Over.

---

## 👾 Enemies & Combat

### Enemy Types
- **Chaser:** Approaches from a personal flanking offset, then closes directly for contact damage and bounces back after a hit.
- **Kamikazer:** Seeks until it has line of sight, locks into a straight charge, and explodes on contact with the player or a turret; a missed or blocked charge must decelerate or recover before trying again.
- **Stalker:** Maintains a preferred distance, circles its target while it has line of sight, and fires telegraphed, aimed projectiles.
- **Shotgunner:** Maintains distance, then stops for a readable windup before firing a projectile fan; firing knocks it backward and briefly confuses it before it relocates. A confused indicator remains visible for every attack cooldown, including when damage cancels its windup.
- **Emitter:** Relocates to a safe spot away from threats, then stands still and fires a rotating two-sided projectile stream; nearby threats make it flee, and hits briefly pause active emission with a confused indicator.

### Unfinished Enemies
- **Saboteur:** Approaches a turret and channels a visible tether that gradually slows or temporarily disables it; damage interrupts and confuses the Saboteur, asking the player to defend important formations before the channel completes.
- **Blinker:** Marks a destination, vanishes without attacking, then reappears and fires a readable radial burst; the landing marker gives the player time to evade, while teleporting disrupts slow locks and mortar markers but persistent area control catches it after arrival.

### Unfinished Boss Enemies
Every fifth combat wave selects one boss at random from the unlocked boss pool and adds it to that wave. The boss materializes at a random valid map position after a clear spawn telegraph; the position must be reachable and must not overlap the player, a turret, or blocking geometry.

Bosses are tankier than normal enemies and each has one clear mechanic that changes the player's positioning, target priority, or evasion route while turrets remain the main damage source.

- **Bulwark:** A slow, high-health boss with directional frontal armor that turns toward the player and reduces, rather than blocks, incoming frontal damage. The player baits its facing away from the main turret formation so turrets can attack exposed sides; sustained turret fire temporarily breaks the armor, while rings, explosions, piercing shots, and displacement bypass or disrupt it.
- **Multiplier:** Stops for an interruptible telegraph before releasing capped groups of simple melee drones. The player survives and kites the adds through turret coverage while deciding when to interrupt the next spawn; Shockwaver, Beamer, and Missiler control the swarm while sustained and priority turrets continue damaging the boss.
- **Bombarder:** A slow, high-health artillery boss that locks sequences of clearly marked impact circles around the player's current or predicted route, then lands shells that create expanding blast rings. The player plans a path through the fixed markers, leads barrages away from turret formations, and dashes through bad overlaps while turrets damage the boss continuously; each barrage ends with a short recovery before the next telegraph.

**Design Goal:** Slow, readable attacks allow skill-based dodging. Mix of enemy types creates tactical variety.

Each wave uses a finite enemy roster. Enemy types can enter on different waves, grow in count independently, and receive type-specific periodic health increases.

### Turret Types
- **Seeker:** Rotates toward the best visible target, telegraphs its shot, and fires a powerful aimed projectile along a clear line of sight.
- **Shockwaver:** Triggers when a target enters its radius, telegraphs a pulse, then expands a doughnut-shaped shockwave that damages each reached target once and knocks enemies outward; it trades directional reach for local crowd control.
- **Vortexer:** A high-health control turret that emits readable magnetic pulses, dealing no damage but pulling enemies and the player toward it with distance falloff; dashing ignores the pull, and max level stops affecting the player.

### Unfinished Turrets
- **Buffer:** Deals little or no damage but strengthens nearby turrets, rewarding formations while multiplying their friendly-fire danger; weak when isolated and multiple auras should not stack.
- **Missiler:** Slowly locks a distant impact position, telegraphs its blast radius, then launches a mortar shell that creates an expanding damaging ring; strong against stationary groups but weak inside a minimum range and against enemies that leave the marker.
- **Beamer:** Sweeps a long continuous damage beam around itself, dealing damage over time to crossed targets; heat downtime creates safe gaps, and it trades priority-target burst for sustained area denial.
- **Sniper:** Slowly acquires a distant target, freezes a visible firing line, then releases a piercing high-damage shot; its minimum range, slow rotation, long reload, and inability to redirect after locking make misses costly.
- **Interceptor:** Tracks and destroys projectiles within a limited arc until it overheats; it protects turret formations from ranged enemies but offers little against body threats and may also intercept player shots until max level.
- **Slower:** Periodically projects a visible field that slows enemies and the player but deals little or no damage; pulse downtime and the risk of hindering the player make placement important, while dashing ignores the slow.

Turret at max level stops targeting the player. 

---

## 🎯 Scoring & Meta-Goal

**Family Settlement Payout:**
- Waves survived
- Enemies destroyed
- Crunch Time usage
- **Goal:** Accumulate enough "violations" to bankrupt CentriCore (30,000+ points)

When you die, your score determines the company's financial penalty. Higher score = bigger lawsuit.

---

## ✅ Design Alignment Checklist

When adding features, ask:
-  Does this support dodging as the primary skill?
-  Does this create meaningful capacity decisions?
-  Does this reinforce the "buggy turrets" theme?
-  Does this fit the dark-comedy tone?
-  Is this the simplest implementation that works?

If you answer "no" to any, reconsider or remove the feature. Focus beats feature bloat.

