# QuickMotion

Material 3 Expressive motion for QML, as a drop-in module.

A curve and its duration are one value, not two knobs. Spatial curves
overshoot and need room to settle; effect curves do not, and look sluggish
given that room. Picking each independently is how motion ends up feeling
wrong in a way nobody can point at — and it is what happens by default,
because QML makes you write them separately every time.

```qml
import QuickMotion

Behavior on scale { Anim { role: Motion.Reveal } }
Behavior on color { ColourAnim {} }
```

- Zero dependencies beyond `QtQuick`. No shell, no config, no palette.
- Roles are named for what is happening, not for which curve is used, so
  the call site survives the specification changing its numbers.
- `Motion.scale = 0` disables animation outright, which is what
  accessibility settings and remote sessions need.

## Install

```sh
sudo ./install.sh
```

Goes into Qt's QML import path, so `import QuickMotion` just works —
including from Quickshell configs, which read that path like any Qt
program. `DESTDIR`, `PREFIX` and `QMLDIR` are honoured for packaging.

## Roles

| Role | For |
|---|---|
| `Motion.Press` | a control acknowledging a touch |
| `Motion.Release` | the same control letting go |
| `Motion.Reveal` | something arriving on screen |
| `Motion.Dismiss` | something leaving |
| `Motion.Resize` | a container following its content |
| `Motion.Emphasis` | drawing attention deliberately |
| `Motion.Fade` | opacity only |
| `Motion.Tint` | colour only |

Press is deliberately quicker than release. Acknowledging a touch has to
feel instant; letting go should settle. Symmetric timing reads as lag on
the way in and haste on the way out.

The underlying curves and durations remain available as `Motion.curve.*`
and `Motion.dur.*` for cases a role does not cover.

## AnimatedRow

A horizontal row whose items animate in, out, and out of each other's way.

This exists because `Repeater` cannot do it. A Repeater destroys its
delegate the instant the model shrinks, so a removed item has nothing left
to animate and simply blinks out — however carefully its entry was
animated. `ListView` keeps the delegate alive for the length of its
`remove` transition, which is the whole trick.

```qml
AnimatedRow {
    model: items       // must be a real model, see below
    itemWidth: 9
    gap: 7
    travel: 6
    delegate: Rectangle { width: 9; height: 9; radius: 4.5 }
}
```

Entry is two beats, not one: the item arrives half again its resting size,
holds, and settles. A single beat — appear at final size and stop — is what
makes an otherwise correct animation feel flat, and no amount of curve
tuning fixes it, because the missing thing is the pause between two events
rather than the shape of one. `arriveScale: 1` restores the single beat.

Two things will catch you, both silent:

**The model must emit insert and remove signals.** A plain integer model
lays out correctly and updates on every change, so it looks right — but
QML rebuilds the view rather than reporting insertions, the transitions
never run, and items appear and vanish instantly. There is no warning
anywhere. Use a `ListModel`.

**`itemWidth` is needed whenever items are uniform.** A `ListView` only
builds delegates inside its viewport, so binding width to `contentWidth`
closes a loop: no width, no delegates, no content, no width, nothing
drawn. Given `itemWidth` the row computes its width from the count instead.

For the same reason the row's width follows the count instantly as items
arrive, and animates only as they leave. A viewport still animating open
does not contain the item just appended, so the add transition is skipped
for it and the item snaps into place while everything around it moves.

## Components

| | |
|---|---|
| `Anim`, `ColourAnim` | animations that take a role instead of a curve and a duration |
| `AnimatedRow` | a row whose items animate in, out, and out of each other's way |
| `Shake` | refusal feedback |
| `Pressable` | a control that acknowledges a touch and settles when released |
| `Reveal` | a container that grows and shrinks with its content |
| `SlideIn` | a panel arriving from an edge |
| `Stagger` | delays for cascading entries |
| `MotionShape` | a drawn shape, optionally resolving to a circle |

`Shake` defaults to animating the anchor offset rather than `x`, because an
item centred with anchors ignores `x` entirely — animating it there does
nothing at all, silently.

`SlideIn` uses different curves entering and leaving. Something arriving is
worth watching and decelerates into place; something leaving should get out
of the way. One curve for both makes dismissal feel reluctant.

`MotionShape` draws ten shapes from two formulas — a rounded polygon and a
scalloped circle — so adding another is a line rather than a file. With
`settlesToCircle` it starts as its shape and becomes a dot shortly after.
The swap is instantaneous on purpose: masked by whatever size change is
running it reads as the shape resolving, while morphing between paths of
different vertex counts costs a great deal and looks worse.

`AnimatedRow` takes a `jitter` from 0 to 1: each item arrives a little
larger or smaller, a beat sooner or later. Identical items animating
identically read as stamped out. The variation is derived from the index
rather than random, so a rebuilt item does not jump to a different one
mid-animation.

## Demo

```sh
QML_IMPORT_PATH=. qs -p demo/gallery.qml   # everything at once
QML_IMPORT_PATH=. qs -p demo/dots.qml      # just the row
```

A row that fills and empties itself is the only way to actually see an exit
animation.

## Licence

MIT. See [LICENSE](LICENSE).
