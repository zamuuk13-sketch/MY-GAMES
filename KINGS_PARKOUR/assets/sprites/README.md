# Kings Parkour — Sprites

## `idle_sprite_sheet.svg`

- Pixel-art idle animation with 6 frames in one horizontal row.
- Frame size: **48 × 64 px**; full sheet: **288 × 64 px**.
- Transparent background; character faces right.
- Palette: charcoal/black clothes, purple accents, warm skin tones, white sneakers.

### Using it in Godot 4

1. Keep the SVG inside `assets/sprites/` in the project.
2. Add an `AnimatedSprite2D` node to the player.
3. In its `SpriteFrames` resource, create an animation named `idle`.
4. Add frames from the sprite sheet and set the region/cell size to **48 × 64** (6 horizontal frames).
5. Set the animation speed to around **6 FPS** and enable looping.

This is the first visual placeholder for the idle animation; the next step is to refine the frame-by-frame breathing and connect it to the player controller.
