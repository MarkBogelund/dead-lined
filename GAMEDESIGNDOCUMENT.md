# Dead-Lined

**Genre:** Arcade Bullet-Hell with Tower Defense  
**Platform:** PC

For development setup and code architecture, see [README.md](README.md).

---

## 🎮 Game Overview: Core, Twist, Hook

### The Hook (Elevator Pitch)
**"Dodge bullet patterns while managing unreliable turrets that also shoot you."**

A single-resource arcade game where you survive by dodging incoming projectiles and strategically placing turrets to reduce enemy density. The catch: your turrets are buggy and attack indiscriminately—including you. Upgrade them fully to make them reliable.

### Core Gameplay
1. **Free-Fire Dodging** — Shoot enemies infinitely and fast (0.25s cooldown, 0 capacity cost). Dodging bullet patterns is the primary skill loop.
2. **Turret Strategy** — Place turrets during build phases to multiply your firepower. Costs capacity. Risky because they shoot at you too.
3. **Crunch Time Mode** — Activate a power-up to become invincible, switch to the wrench as your only weapon, and gain combat buffs. Capacity-gated.

### The Unique Twist
**Turrets as Double-Edged Sword:**
- Unlike traditional tower defense, turrets aren't reliable helpers—they're buggy and target both enemies and you
- Creates constant risk/reward tension: build turrets for firepower = higher friendly fire risk
- Upgrading turrets to max level makes them safe (only shoot enemies)
- Each turret placement lowers the Crunch Time threshold, forcing future waves to rely more on pure dodging skill

**Crunch Time Inversion:**
- Normal play: you dodge while turrets assist
- Crunch Time: wrench only, invincible, must be aggressive and close-range
- Switching modes forces different playstyles

### Design Philosophy
**Every element serves the core:** Dodging is primary skill. Turrets are strategic layer. Capacity gates turret building and Crunch Time to create meaningful decisions. Nothing distracts from the core loop.

---

## 🕹️ Gameplay Loop

### Build Phase
**Duration:** Configurable timer (auto-ends)

**What you do:**
- Place new turrets (costs capacity)
- Upgrade existing turrets by holding Upgrade on the turret panel (costs capacity; each level applies an unannounced buff)
- Sell turrets by holding Sell (refunds 75% of everything spent on that turret, capped at max capacity)
- Repair damaged turrets by holding Left Shift inside their radius, in build or combat phase (drains capacity while repairing)
- Collect leftover enemy drops

**Risk/Reward:**
- Building costs capacity but reduces enemy density
- Too many turrets = friendly fire risk
- Max-level turrets stop targeting you (their shots and shockwaves can still hit you)

### Combat Phase
**Duration:** Ends when all enemies in the wave are destroyed

**What you do:**
- Dodge incoming projectiles (PRIMARY SKILL)
- Dash: the player is invincible from the moment dash is pressed until the dash ends. A quick tap (released within 0.15 s) is a normal 120 px dash. Holding longer charges it: time slows (0.5×, still steering), the player glows white, and releasing dashes in the movement direction (or facing direction when standing still). Distance grows linearly from 120 px to 300 px at 0.5 s after the press (real time, auto-fires). No shooting or activating Crunch Time while the button is held.
- Shoot enemies freely (0.25s cooldown, 0 capacity cost)
- Activate Crunch Time when capacity % allows
- Manage capacity by surviving hits

**Escalation:** Each wave spawns more enemies, faster bullets, higher difficulty

### Crunch Time (Power-Up Mode)
**Activation:** Manual trigger, only during combat, requires capacity ≥ threshold

**Cost:** Spends 50 capacity on activation and lasts 5 seconds

**Effect:**
- Invincibility
- Wrench becomes your only weapon (shooting disabled)
- Combat buffs: 3x damage, faster swings, 2x radius, 1.5x speed

**Caveat:** You must be aggressive and close-range. Each turret placed lowers the threshold, making future Crunch Times harder to access.

---

## 📊 Resource System: Capacity (Single Resource)

**Single unified resource (0–100%) that governs everything:**

| Action | Cost | Effect |
|--------|------|--------|
| Take damage | 1-20% | Direct deduction |
| Build turret | 10-20% | Strategy cost |
| Upgrade turret | Escalates | Reliability cost |
| Sell turret | Refund | Returns 75% of the turret's total cost |
| Activate Crunch Time | 50% | Power-up gate |
| Repair turret | Continuous | Restores turret health while held |
| Enemy defeated | +5-10% | Resource generation |

**Strategic Tension:** Build turrets to help combat (costs capacity) but it also makes Crunch Time harder to access next wave.

**Death Condition:** Capacity reaches 0% → Player burns out and dies.

**Crunch Time Gate:** Must be ≥ threshold to activate. Threshold lowers with each turret placed.

---

## 👾 Enemies & Combat

### Enemy Types
- **Stalker (Ranged):** Maintains distance and fires slow, readable projectiles. Drops medium scrap.
- **Chaser (Melee):** Rushes and pressures the player or nearby turrets. Drops small scrap.
- **Kamikazer:** Commits to a charge and self-destructs on contact. High burst damage and lower frequency.

**Design Goal:** Slow, readable projectiles allow skill-based dodging. Mix of enemy types creates tactical variety.

Each wave uses a finite enemy roster. Enemy types can enter on different waves, grow in count independently, and receive type-specific periodic health increases.

### Turrets
**Seeker:**
- Rotates toward target, fires powerful projectiles
- **Problem:** Shoots both drones AND you (buggy software)
- **Solution:** Upgrade to max level ("MAX") → stops aiming at you; stray shots can still hit
- **Cost:** Building and upgrading cost capacity
- **Benefit:** Reduces enemy count, multiplies your firepower

**Shockwaver:**
- Detects enemies or the player entering its max range (the same radius the shockwave expands to)
- Telegraphs, then emits an expanding doughnut-shaped shockwave
- Damages every target reached by the ring once per pulse
- Knocks enemies back from the turret as the ring reaches them
- Allows the player to dash through the moving wavefront with correct timing
- Trades directional range for local crowd control around the turret
- Upgrades can raise health, damage, blast radius and pulse rate; at max level the player no longer triggers it, but its pulses still damage the player

---

## 📐 Map & Visuals

- **Camera:** Zoomed out for better visibility of incoming projectile patterns
- **Map Size:** Expanded playable area to support dodge patterns and turret positioning strategy
- **Theme:** Dark-comedy corporate setting (CentriCore facility); pixel-art aesthetic

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
- [ ] Does this support dodging as the primary skill?
- [ ] Does this create meaningful capacity decisions?
- [ ] Does this reinforce the "buggy turrets" theme?
- [ ] Does this fit the dark-comedy tone?
- [ ] Is this the simplest implementation that works?

If you answer "no" to any, reconsider or remove the feature. Focus beats feature bloat.

