# Brainrot Bazaar

[![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Ianfield77/roblox-brainrot-ianfield/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Ianfield77/roblox-brainrot-ianfield/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A 3D brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty
(roblox-brainrot-01), built with Rojo from `src/` into `game.rbxl`.

## The game

Twelve original brainrot characters walk the conveyor belt through the plaza:
Kucing Nasi Goreng, Ayam Disco, Bebek Es Kopi, Kambing Skateboard, Ikan Terbang
Turbo, Gajah Balon Udara, Naga Mie Pedas, Raja Durian Emas, Unicorn Soto Ayam,
Dewa Mie Raksasa, Kapibara Kosmik and Sultan Sate Galaksi. Click one on the belt
to buy it onto your base and it earns money every second, at its own rate.

- **Rarities and mutations:** Common to Godly, with Golden, Diamond and Rainbow
  mutations that multiply income up to 5x.
- **Stealing:** touch another player's brainrot while their base is unlocked and
  it is yours, but you walk away slowed. Lock your base to shield it.
- **Mie Tsunami:** every few minutes a wave sweeps the plaza. Only your own base
  is safe, and the wave washes every brainrot off the belt.
- **Brainrot Rush:** rare spawns tilt rarer for a minute.
- **Progression:** rebirths multiply all income, plus slot and speed upgrades.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.
- `src/shared/` holds the cast and the tuning numbers both sides read.
- `src/server/` holds one module per job: world, state, models, belt, money,
  stealing and events, wired by `init.server.luau`.
- `src/client/` holds the HUD (`Hud.luau`) and its entry script.
- `screenshots/` holds the entry's captures; one of them is the game's first
  thumbnail on Roblox. `PLAY.json` names the published place.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

Build the place first with Rojo:

    rojo build default.project.json --output game.rbxl

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's
RULES.txt, which gives every command in order (Before you submit, then Enter).
