# OpenComputer Scripts for GTNH

## Install

```shell
mkdir new_dir
cd new_dir
wget https://raw.githubusercontent.com/joegnis/oc-scripts-gtnh/master/install.lua
./install.lua
```

```
Usage:
./install [-b|--branch BRANCH] [-u|--update-file FILE]
./install [-b|--branch BRANCH] [-c|--update-config]
./install --help | -h

Options:
  -b --branch BRANCH
    Downloads from a specific branch.
    Default is %s.
  -u --update-file FILE
    Updates a specific file.
  -c --update-config
    Updates all config files.
  -h --help
    Shows this message.

By default, this script always (re)downloads
all source files except for config files.

For config files, by default it downloads all
missing ones but does not download existing ones.
To force download a config file, use -u option.
Before it updates a config file,
it backs up existing one before proceeding.
```

## Automating Blood magic Alchemic Chemistry Set

Automates item crafting in BM chemistry set.
To run: `./bm_alchemist.lua`. Config file: `bm_alchemist_config.lua`.

Script first reads AE patterns when launched, and after having detected materials in input chest, it tries matching patterns' input materials with them and then put them one by one into the chemistry set if matched.

Requirements:
- 1 computer
- 1 Adapter
- 1 Transposer
- 1 ME Interface
- Alchemic Chemistry Set
- 1 Blood Orb
- ...

See the illustration below for an example setup. Additionally,
- route the output (bottom) of Chemset to ME Interface;
- put Blood Orb into Chemset with the orb's tier high enough to craft the recipes we want;
- put AE patterns in the interface (Patterns should have exactly 5 inputs and 1 output).

Maintenance:
- After adding any new pattern, rerun the script.
- Press Ctrl-C to quit the script while it is running.

![chemset setup](./readme_assets/chemset_setup.png)

## Automating Blood Altar

Automates item crafting and blood network refilling in BM Blood Altar.
To run: `./blood_altar.lua`. Config file: `blood_altar_config.lua`.

Script works in a similar way of the chemistry set script to automate item crafting. Additionally,
- when a blood orb is present in the orb chest,
  it puts the orb onto Altar when Altar is idle to keep player's blood network filled.
- waits for Altar to fill up when blood is not enough for crafting
  (blood requirements are hardcoded in config file)

Requirements:
- 1 OC computer with a Tier 1 CPU that supports to 6 or 7 components:
  1 hard disk, 1 graphics card, 1 internet card (optional but convenient),
  2 transposers, and 2 adapters
- 2 Transposers
- 2 Adapters
- 1 Blood Orb (optional)
- Some chests
- Some item conduits (or other item transfer methods)
- Some OC cables/network conduits

See the illustration below for an example setup.
This setup has roughly two groups of components:
one has OC computer and ME interface;
another has Altar.
I separate the two groups physically since
it saves space for Well of Suffering ritual.

Connection:
- auto-pull items from ME-side output chest to the bottom of Altar;
- auto-pull items from Altar-side orb chest to ME-side orb chest
- auto-pull items from Altar-side output chest to ME-side ME Interface
- connect Altar-side transposer to ME-side computer

Other notes
- ME interface doesn't need be set to blocking mode
  since all altar recipes are one input to one output, i.e.,
  it is impossible to have two recipes having the same input.

![altar setup (input)](./readme_assets/bm_altar_setup_input.png)

![altar setup (altar)](./readme_assets/bm_altar_setup_altar.png)


## Misc.

### Config Switcher Fluid-Only Recipe Control

> Config switcher (name grabbed from [greginator](https://divran.github.io/greginator/))
is a universal AE2 system that enables one machine to handle recipes
with many different kinds of not-consumed items like programmed circuits, molds, shapes, catalyst and etc.
It was [posted by Sampsa on Discord server](https://discord.com/channels/181078474394566657/1144053760033824870).
Before we have a auto-pulling stocking input hatch, this system can't
handle fluid-only recipes very well.
>
> To understand the limitation before getting such input hatch,
first we must understand that in the item-only-variant of the system,
the storage cell in the ME chest connected to machine will not be extracted by EnderIO conduit until the ingredients in it are consumed.
When crafting an recipe with items, machine directly consumes the items through a stocking input bus.
However, when crafting a fluid-only recipe,
fluids have to be exported to machine's input hatch.
It creates an intermediate state where
ingredients in storage cell are gone before crafting is done,
which confuses EnderIO conduit to extract storage cell too early.
Storage cell has to wait in ME chest until crafting is done since it contains the config item required for crafting.

Script tries its best (not guaranteed) to determine whether crafting is complete, and
after that it transfers the storage cell out.
Crafting is deemed complete when it sees
1. there is no item (fluids are in packets which are items) in machine's AE subnet, and
2. there are no more fluids in machine input hatch
3. the above two checks have passed several times consecutively

Required external components:
1. 1 transposer attached to input hatch to read its contents
2. 1 transposer attached to ME chest and a chest to transfer storage cell out
3. 1 adapter attached to a machine subnet's ME Interface to read AE network contents

### Regulating Stack Size

Moves items from input chests to output chests in stacks of size in certain multiples.
To run: `./regulate_size.lua`. Config file: `regulate_size_config.lua`.

Requirements:
- 1 computer
- 1 or more Transposers
- Some chests
- ...

Installation:
- Put chests around Transposer(s): for each Transposer, one input chest per multiple and at least one output chest.
- Change config file accordingly.

![regulate stack size setup](./readme_assets/regulate_stack_setup.jpg)
