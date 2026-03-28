# PlaytimeRanking

**PlaytimeRanking** is a World of Warcraft Classic: Burning Crusade addon that creates a shared leaderboard based on total playtime.

Instead of only looking at playtime per character, the addon groups all your characters under one player profile and lets you compare your total time played with other players using the addon.

---

## Features

- Player-based leaderboard
- Character breakdown on click
- Total playtime tracking via `/played`
- Shared data sync between addon users
- Playtime achievements
- Minimap button
- In-game options panel
- WoW-themed interface

---

## Overview

PlaytimeRanking turns time played into a social and competitive stat.

Each player can group all of their characters under a single main profile name.  
The addon then adds together the total playtime of those characters and displays a ranking between all players who use the addon.

Example:

- Daeler — 4200h
- Ultia — 3100h
- PlayerX — 1800h

When clicking on a player, the addon shows the details of their characters:

- Character name
- Realm
- Class
- Level
- Individual playtime

---

## How it works

### 1. Playtime tracking
The addon retrieves the total playtime of the current character using `/played`.

### 2. Local storage
Character data is saved locally in SavedVariables.

### 3. Player grouping
All characters can be grouped under one main player name.

For example:

- `Daelerbackbi`
- `Daelermage`
- `Daelerwar`

can all belong to:

- `Daeler`

### 4. Addon sync
The addon shares data silently between players using addon communication channels.

Supported sync contexts:
- Guild
- Party
- Raid

### 5. Leaderboard
The addon rebuilds and displays a sorted leaderboard based on total playtime.

---

## Achievement system

PlaytimeRanking includes an achievement system based on total hours played.

Examples of milestones:

- 500h
- 1000h
- 1500h
- 2000h
- ...
- 100000h

These milestones can be used to unlock titles, ranks, or visual progression inside the addon.

---

## Interface

### Main window
The main window shows:

- Rank
- Player name
- Total playtime
- Number of characters
- Highest achievement reached

### Character details
Clicking on a player expands their character list.

### Minimap button
- **Left click**: open leaderboard
- **Right click**: open options
- **Drag**: move around the minimap

### Options panel
Available in:

`Esc > Interface > AddOns > PlaytimeRanking`

Options include:
- Main player name
- Achievement step
- Automatic `/played` update
- Show or hide minimap button
- Manual sync

---

## Slash commands

```lua
/ptr
/ptr sync
/ptr update
/ptr options
