extends Node2D

# Kings Parkour - rooftop starting map
# Procedural pixel-art scene, designed around a 320x180 canvas scaled up cleanly.
const W := 320
const H := 180
var cloud_offset := 0.0

const SKY := Color("#55b8f5")
const SKY_LIGHT := Color("#8cddff")
const SKY_DARK := Color("#2f8dd8")
const ROOF := Color("#777f91")
const ROOF_LIGHT := Color("#aab4c5")
const ROOF_DARK := Color("#424c62")
const WALL := Color("#c8c8c5")
const WALL_SHADE := Color("#929eae")
const PINK := Color("#ff65b8")

func _process(delta: float) -> void:
	cloud_offset = fposmod(cloud_offset + delta * 5.0, 380.0)
	queue_redraw()

func _draw() -> void:
	# Blue sky with a subtle pixel-art horizon gradient.
	draw_rect(Rect2(0, 0, W, H), SKY)
	draw_rect(Rect2(0, 0, W, 42), Color("#65c7fa"))
	draw_rect(Rect2(0, 42, W, 38), Color("#55b8f5"))
	draw_rect(Rect2(0, 80, W, 36), Color("#489fe8"))
	draw_rect(Rect2(0, 116, W, 20), Color("#3987d2"))

	# Tiny square highlights in the sky.
	for p in [Vector2(18, 26), Vector2(44, 61), Vector2(91, 18), Vector2(135, 47), Vector2(186, 27), Vector2(244, 63), Vector2(292, 35)]:
		draw_rect(Rect2(p.x, p.y, 2, 2), Color("#a5e6ff"))

	# Sun: deliberately chunky, like a classic handheld RPG.
	draw_rect(Rect2(246, 19, 22, 22), Color("#ffb52e"))
	draw_rect(Rect2(250, 15, 14, 30), Color("#ffcf55"))
	draw_rect(Rect2(242, 23, 30, 14), Color("#ffcf55"))
	draw_rect(Rect2(250, 23, 14, 14), Color("#ffe98a"))
	for ray in [Rect2(255, 8, 4, 4), Rect2(255, 48, 4, 4), Rect2(235, 28, 4, 4), Rect2(275, 28, 4, 4), Rect2(241, 14, 4, 4), Rect2(269, 14, 4, 4), Rect2(241, 42, 4, 4), Rect2(269, 42, 4, 4)]:
		draw_rect(ray, Color("#ffcf55"))

	# Distant blocky skyline, softened by atmospheric blue.
	_draw_building(0, 96, 30, 48, Color("#639ac7"), Color("#a7d9f5"))
	_draw_building(25, 82, 27, 62, Color("#5388bd"), Color("#9acbf0"))
	_draw_building(53, 105, 22, 39, Color("#6b9fca"), Color("#b4def7"))
	_draw_building(76, 88, 34, 56, Color("#4c82b9"), Color("#8ec2ec"))
	_draw_building(110, 101, 27, 43, Color("#6598c3"), Color("#add9f2"))
	_draw_building(138, 77, 30, 67, Color("#5688bd"), Color("#9bcdf0"))
	_draw_building(166, 98, 24, 46, Color("#6d9fc8"), Color("#b5def5"))
	_draw_building(190, 87, 31, 57, Color("#4e82b8"), Color("#91c3e9"))
	_draw_building(221, 104, 25, 40, Color("#699bc5"), Color("#b2dbf3"))
	_draw_building(246, 91, 34, 53, Color("#5689bc"), Color("#9acbf0"))
	_draw_building(279, 100, 41, 44, Color("#6799c2"), Color("#b2dcf4"))

	# Animated layered clouds.
	_draw_cloud(fposmod(12.0 + cloud_offset, 380.0) - 45.0, 32.0, 1.0, Color("#f8fdff"))
	_draw_cloud(fposmod(142.0 + cloud_offset * 0.72, 380.0) - 45.0, 59.0, 0.8, Color("#d8f3ff"))
	_draw_cloud(fposmod(275.0 + cloud_offset * 0.55, 380.0) - 45.0, 20.0, 0.7, Color("#ffffff"))

	# Rooftop rear parapet and concrete wall.
	draw_rect(Rect2(0, 135, W, 17), WALL_SHADE)
	draw_rect(Rect2(0, 135, W, 4), Color("#e6e3dc"))
	draw_rect(Rect2(0, 139, W, 10), WALL)
	for x in range(4, W, 28):
		draw_rect(Rect2(x, 140, 2, 8), Color("#b1b5b9"))
		draw_rect(Rect2(x + 5, 136, 12, 2), Color("#f2eee5"))

	# Roof floor with a strong dark pixel outline.
	draw_rect(Rect2(0, 150, W, 30), ROOF_DARK)
	draw_rect(Rect2(0, 150, W, 3), ROOF_LIGHT)
	draw_rect(Rect2(0, 153, W, 27), ROOF)
	# Large rooftop concrete tiles.
	for x in range(0, W, 32):
		draw_rect(Rect2(x, 154, 1, 26), Color("#687488"))
		draw_rect(Rect2(x + 2, 156, 26, 1), Color("#939daf"))
		draw_rect(Rect2(x + 4, 171, 23, 1), Color("#858fa1"))
	for y in [162, 174]:
		for x in range(16, W, 64):
			draw_rect(Rect2(x, y, 7, 1), Color("#b8c0ca"))
	# Scuffs, little pebbles and sunlight flecks.
	for p in [Vector2(13, 160), Vector2(44, 173), Vector2(71, 158), Vector2(101, 168), Vector2(128, 159), Vector2(157, 175), Vector2(187, 164), Vector2(218, 172), Vector2(249, 158), Vector2(285, 168), Vector2(306, 157)]:
		draw_rect(Rect2(p.x, p.y, 2, 1), Color("#c0c5cb"))
	# Drain cover and a small rooftop vent.
	draw_rect(Rect2(26, 163, 13, 8), Color("#4a566b"))
	draw_rect(Rect2(28, 165, 9, 4), Color("#9aa6b6"))
	for x in range(29, 37, 3):
		draw_rect(Rect2(x, 165, 1, 4), Color("#58657a"))
	draw_rect(Rect2(280, 121, 15, 14), Color("#58677c"))
	draw_rect(Rect2(277, 119, 21, 3), Color("#d5d7d7"))
	draw_rect(Rect2(283, 124, 9, 8), Color("#8997a9"))
	draw_rect(Rect2(286, 125, 3, 5), Color("#d2d9df"))

	# Small rooftop safety stripe and edge shadow.
	draw_rect(Rect2(0, 149, W, 1), Color("#f2d58a"))
	draw_rect(Rect2(0, 178, W, 2), Color("#303b52"))

	# Tiny entrance door in the rear wall, with a bright handle.
	draw_rect(Rect2(145, 119, 24, 30), Color("#68758b"))
	draw_rect(Rect2(148, 122, 18, 27), Color("#aab4c0"))
	draw_rect(Rect2(151, 125, 12, 24), Color("#64728a"))
	draw_rect(Rect2(160, 137, 2, 2), Color("#ffe48a"))
	draw_rect(Rect2(142, 117, 30, 3), Color("#f0eee7"))

	# Pink checkpoint flag to establish a destination without blocking the rooftop.
	draw_rect(Rect2(222, 121, 2, 29), Color("#424b60"))
	draw_rect(Rect2(224, 122, 15, 9), PINK)
	draw_rect(Rect2(224, 122, 15, 2), Color("#ffb4df"))
	draw_rect(Rect2(237, 124, 2, 5), Color("#df3e98"))
	draw_rect(Rect2(222, 149, 7, 2), Color("#424b60"))

func _draw_building(x: int, y: int, width: int, height: int, base: Color, window: Color) -> void:
	draw_rect(Rect2(x, y, width, height), base)
	draw_rect(Rect2(x, y, width, 3), window)
	draw_rect(Rect2(x + 2, y + 4, width - 4, 1), Color("#83b7df"))
	for wx in range(x + 4, x + width - 3, 7):
		for wy in range(y + 8, y + height - 3, 9):
			draw_rect(Rect2(wx, wy, 3, 4), window)
			draw_rect(Rect2(wx, wy + 4, 3, 1), Color("#477db4"))
	# Pixel roof details.
	draw_rect(Rect2(x + 3, y - 2, width - 6, 2), Color("#b9e0f7"))
	if width > 27:
		draw_rect(Rect2(x + width / 2 - 2, y - 6, 5, 6), base.darkened(0.1))

func _draw_cloud(x: float, y: float, scale: float, color: Color) -> void:
	var s := scale
	# Block silhouettes and one-pixel highlights keep the edges intentionally crisp.
	draw_rect(Rect2(x + 4*s, y + 5*s, 24*s, 8*s), color)
	draw_rect(Rect2(x + 9*s, y + 1*s, 10*s, 12*s), color)
	draw_rect(Rect2(x + 17*s, y + 3*s, 9*s, 10*s), color)
	draw_rect(Rect2(x + 1*s, y + 7*s, 6*s, 5*s), color)
	draw_rect(Rect2(x + 7*s, y + 12*s, 17*s, 2*s), color.darkened(0.08))
	draw_rect(Rect2(x + 10*s, y + 2*s, 6*s, 2*s), Color("#ffffff"))
