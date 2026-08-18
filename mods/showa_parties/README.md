# Showa Parties

Every third day somebody throws a party. Five guests turn up, each with one
thing on their mind, and the news tells you where it is.

## Where and when

A party runs **every third day**, rotating around the venues the rest of the
suite registers — the mall, the arcade, the chikagai, the cup grounds, the
lake, Elm's lab. The theme rotates independently, so the same room throws a
different evening each time it comes round:

| Theme | The crowd |
|---|---|
| TRADE MEET | 2 traders, 2 swappers, 1 battler |
| BATTLE PARTY | 3 battlers, 1 swapper, 1 trader |
| SWAP MEET | 3 swappers, 1 battler, 1 trader |

The whole guest list is a pure function of the day and the room, so the people
standing there are the people the news announced, and walking out and back in
does not reroll them.

## What to do at one

- **Battle.** A friendly match, scaled to your party. It is a real trainer
  battle, so losing is a whiteout — that is what losing one is on Gold.
- **Swap an item.** "I am after a POTION. I will give you a REVIVE for it."
  If it is in your bag, it is a deal.
- **Trade a POKEMON.** For real, through the engine's own trade routine: the
  mon you receive keeps the level of the one you handed over, recomputes its
  stats for its new species, arrives nicknamed with the guest as its original
  trainer, and is ticked off in the #DEX.

One deal per guest per party. The host by the door has the guest list,
tonight's theme, and how many days until the next one.

## Without the rest of the suite

Parties are thrown at venues the *other* Showa mods register, so with none of
them installed there is nowhere to hold one and no party happens. The mod
still loads cleanly and says so.

## Testing

```sh
LUA_SCRIPT=mods/showa_parties/tests/parties_rules_test.lua LUA_CWD=. \
  lovec.exe <shim>/luarun
LUA_SCRIPT=mods/showa_parties/tests/parties_headless_test.lua LUA_CWD=. \
  lovec.exe <shim>/luarun

POKEPORT_GAME=gold POKEPORT_IDENTITY=party_driver POKEPORT_NO_DISCORD=1 \
  POKEPORT_DRIVER=mods/showa_parties/tests/party_driver.lua lovec.exe .
```

## Notes for the next feature

`src/core/gen2/NpcTrade.lua` is the cart's own trade routine and this mod
calls it rather than hand-rolling a party swap — it already gets the level
carry-over, the party closing up, the mail slot shifting with it and the #DEX
tick right. That is the one reason this mod declares `engine_internals`.

Spawning five people in a room is also where `core.placement` came from: a
cell being free of NPCs is **not** enough, and a search that skips the
walkability check stands your guests on the shelves.
