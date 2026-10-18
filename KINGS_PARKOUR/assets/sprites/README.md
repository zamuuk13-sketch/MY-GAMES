# Kings Parkour — Sprites

## `idle_sprite_sheet.svg`

- Pixel-art idle animation with **8 frames** in one horizontal row.
- Frame size: **48 × 64 px**; full sheet: **384 × 64 px**.
- Transparent background; character faces right.
- Palette: charcoal/black clothes, purple accents, warm skin tones, white sneakers.
- The loop includes subtle breathing and a blink; legs stay planted while the torso/head move slightly.

### Using it in Godot 4

1. Keep the SVG inside `assets/sprites/` in the project.
2. Add an `AnimatedSprite2D` node to the player.
3. In its `SpriteFrames` resource, create an animation named `idle`.
4. Import the sheet as frames with cell size **48 × 64** (8 horizontal frames).
5. Set the animation speed to around **6 FPS** and enable looping.

This is the first pass of the idle animation. It can be refined further and connected to the player controller in a later step.
