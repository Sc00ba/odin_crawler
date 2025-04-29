package main

import "core:c"
import "core:fmt"
import "core:math/linalg"
import "core:time"
import "core:math/rand"
import "core:math"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

TileName :: enum u8 {
	FloorGrate,
	FloorGrateFuzzed,
	FloorGrateFuzzedWithRedDot,
	CeilingTile,
	HorizontalPipe,
	HorizontalPipeWithEye,
	HorizontalPipeWithPurpleSlime,
	VerticalPipe,
	VerticalPipeWithLeftHand,
	VerticalPipeWithRighHand,
	SimpleBraceStructure,
	OrangeCrate,
	BlueCrate,
	LightningGlobe1,
	LightningGlobe2,
	LightningGlobe3,
}

Tile :: struct {
	name: TileName,
	prob: f32,
}

TilerBehavior :: enum {RANDOM, ROUND_ROBBIN}
Tiler :: struct {
	tex_id: u32,
	tiles: []Tile,
	delta: f32,
	behavior: TilerBehavior,
	idx: int,
	last_update: time.Time
}

NewTiler :: proc(tex_id: u32, tex_len: f32, tiles: []Tile, behavior: TilerBehavior = .RANDOM) -> (^Tiler, bool) {
	if len(tiles) < 1 {
		return nil, false
	}

	switch behavior {
	case .RANDOM:
		prob_sum := f32(0.0)
		for tile in tiles {
			prob_sum += tile.prob
		}

		if prob_sum != 1.0 {
			return nil, false
		}
	case .ROUND_ROBBIN:
	}

	tiler := new(Tiler)

	tiler.tex_id = tex_id
	tiler.tiles = tiles
	tiler.delta = 1.0 / tex_len
	tiler.behavior = behavior
	tiler.last_update = time.now()
	return tiler, true
}

SelectTileCoords :: proc(t: ^Tiler) -> (i, j: f32) {
	switch t.behavior {
	case .RANDOM:
		target := rand.float32()
		prob_sum := f32(0.0)
		for tile in t.tiles {
			prob_sum += tile.prob
			if target < prob_sum {
				i, j = f32(u8(tile.name) & 7) * t.delta, f32(u8(tile.name) >> 3) * t.delta
				return
			}
		}
	case .ROUND_ROBBIN:
		tile := t.tiles[t.idx]
		if time.since(t.last_update) >= time.Millisecond * 250 {
			t.idx = (t.idx + 1) % len(t.tiles)
			t.last_update = time.now()
		}
		i, j = f32(u8(tile.name) & 7) * t.delta, f32(u8(tile.name) >> 3) * t.delta
		return
	}
	return
}

DrawFloor :: proc(pos: rl.Vector2, tiler: ^Tiler, height: f32 = 0.0) {
	rlgl.Begin(rlgl.QUADS)
	defer rlgl.End()

	rlgl.SetTexture(tiler.tex_id)

	color := rl.WHITE
	rlgl.Color4ub(color.r, color.g, color.b, color.a)

	i, j := SelectTileCoords(tiler)
	
	a := rl.Vector3{pos.x + 0, height, pos.y + 0}
	b := rl.Vector3{pos.x + 0, height, pos.y + 1}
	c := rl.Vector3{pos.x + 1, height, pos.y + 1}
	d := rl.Vector3{pos.x + 1, height, pos.y + 0}

	rlgl.TexCoord2f(i + 0, j + 0) // top left
	rlgl.Vertex3f(expand_values(a))

	rlgl.TexCoord2f(i + 0, j + tiler.delta) // bottom left
	rlgl.Vertex3f(expand_values(b))

	rlgl.TexCoord2f(i + tiler.delta, j + tiler.delta) // bottom right
	rlgl.Vertex3f(expand_values(c))

	rlgl.TexCoord2f(i + tiler.delta, j + 0) // top right
	rlgl.Vertex3f(expand_values(d))
}

DrawCeiling :: proc(pos: rl.Vector2, height: f32, tiler: ^Tiler) {
	rlgl.Begin(rlgl.QUADS)
	defer rlgl.End()

	rlgl.SetTexture(tiler.tex_id)

	color := rl.WHITE
	rlgl.Color4ub(color.r, color.g, color.b, color.a)

	i, j := SelectTileCoords(tiler)
	
	a := rl.Vector3{pos.x + 0, height, pos.y + 0}
	b := rl.Vector3{pos.x + 0, height, pos.y + 1}
	c := rl.Vector3{pos.x + 1, height, pos.y + 1}
	d := rl.Vector3{pos.x + 1, height, pos.y + 0}

	rlgl.TexCoord2f(i + 0, j + 0) // top left
	rlgl.Vertex3f(expand_values(d))

	rlgl.TexCoord2f(i + 0, j + tiler.delta) // bottom left
	rlgl.Vertex3f(expand_values(c))

	rlgl.TexCoord2f(i + tiler.delta, j + tiler.delta) // bottom right
	rlgl.Vertex3f(expand_values(b))

	rlgl.TexCoord2f(i + tiler.delta, j + 0) // top right
	rlgl.Vertex3f(expand_values(a))
}

// N looking in the positive Z direction which is mapped to Y
// W looking in the positive X direction
Direction :: enum u8 {N, E, S, W}

DrawWall :: proc(pos: rl.Vector2, dir: Direction, height: f32, tiler: ^Tiler) {
	rlgl.Begin(rlgl.QUADS)
	defer rlgl.End()

	rlgl.SetTexture(tiler.tex_id)

	color := rl.WHITE
	rlgl.Color4ub(color.r, color.g, color.b, color.a)

	a, b, c, d: rl.Vector3
	switch dir {
	case .N:
		a = rl.Vector3{pos.x + 0, 0, pos.y + 0}
		b = rl.Vector3{pos.x + 0, 1, pos.y + 0}
		c = rl.Vector3{pos.x + 1, 1, pos.y + 0}
		d = rl.Vector3{pos.x + 1, 0, pos.y + 0}
	case .E:
		a = rl.Vector3{pos.x + 0, 0, pos.y + 0}
		b = rl.Vector3{pos.x + 0, 1, pos.y + 0}
		c = rl.Vector3{pos.x + 0, 1, pos.y + 1}
		d = rl.Vector3{pos.x + 0, 0, pos.y + 1}
	case .S:
		d = rl.Vector3{pos.x + 0, 0, pos.y + 0}
		c = rl.Vector3{pos.x + 0, 1, pos.y + 0}
		b = rl.Vector3{pos.x + 1, 1, pos.y + 0}
		a = rl.Vector3{pos.x + 1, 0, pos.y + 0}
	case .W:
		d = rl.Vector3{pos.x + 0, 0, pos.y + 0}
		c = rl.Vector3{pos.x + 0, 1, pos.y + 0}
		b = rl.Vector3{pos.x + 0, 1, pos.y + 1}
		a = rl.Vector3{pos.x + 0, 0, pos.y + 1}
	}

	for h in 0..<f32(height) {
		i, j := SelectTileCoords(tiler)

		v := rl.Vector3{0, h, 0}
		rlgl.TexCoord2f(i + 0, j + tiler.delta) // bottom left
		rlgl.Vertex3f(expand_values(a + v))

		rlgl.TexCoord2f(i + 0, j + 0) // top left
		rlgl.Vertex3f(expand_values(b + v))

		rlgl.TexCoord2f(i + tiler.delta, j + 0) // top right
		rlgl.Vertex3f(expand_values(c + v))

		rlgl.TexCoord2f(i + tiler.delta, j + tiler.delta) // bottom right
		rlgl.Vertex3f(expand_values(d + v))
	}
}

DrawColumn :: proc(pos: rl.Vector2, height: f32, tiler: ^Tiler) {
	DrawWall(pos, .N, height, tiler)
	DrawWall({pos.x+1, pos.y}, .E, height, tiler)
	DrawWall({pos.x, pos.y+1}, .S, height, tiler)
	DrawWall(pos, .W, height, tiler)
}

DrawCrate :: proc(pos: rl.Vector2, tiler: ^Tiler) {
	DrawColumn(pos, 1.0, tiler)
	DrawFloor(pos, tiler, 1.0)
}

DrawBillboard :: proc(pos: rl.Vector2, cam: ^rl.Camera, height: f32, tiler: ^Tiler) {
	rlgl.Begin(rlgl.QUADS)
	defer rlgl.End()

	rlgl.SetTexture(tiler.tex_id)

	color := rl.WHITE
	rlgl.Color4ub(color.r, color.g, color.b, color.a)

	p: [4]rl.Vector3
	p[0] = rl.Vector3{-0.5, 0, 0}
	p[1] = rl.Vector3{-0.5, 1, 0}
	p[2] = rl.Vector3{0.5, 1, 0}
	p[3] = rl.Vector3{0.5, 0, 0}

	// Find the cam_dir vector pointing from the camera to the target in the XZ plane
	cam_dir := cam.target.xz - cam.position.xz
	// Find the angle in radians beteen X and the cam_dir vector
	angle := math.atan2(cam_dir.x, cam_dir.y)
	// Compute the sine and cosine of the angle of the cam_dir vector
	sin, cos := math.sincos(angle)
	// Define the rotation matrix.
	m := matrix[2, 2]f32{
		cos, sin,
		-sin, cos
	}

	// Rotate each vertice around 0,0 in the XZ plane.
	for &v in p {
		v.xz = m * v.xz
	}

	for &v in p {
		v += rl.Vector3{pos.x + 0.5, 0, pos.y + 0.5}
	}

	i, j := SelectTileCoords(tiler)
	v := rl.Vector3{0, height, 0}

	rlgl.TexCoord2f(i + 0, j + tiler.delta) // bottom left
	rlgl.Vertex3f(expand_values(p[0] + v))

	rlgl.TexCoord2f(i + 0, j + 0) // top left
	rlgl.Vertex3f(expand_values(p[1] + v))

	rlgl.TexCoord2f(i + tiler.delta, j + 0) // top right
	rlgl.Vertex3f(expand_values(p[2] + v))

	rlgl.TexCoord2f(i + tiler.delta, j + tiler.delta) // bottom right
	rlgl.Vertex3f(expand_values(p[3] + v))
}

main :: proc() {
	rl.SetTraceLogLevel(.ERROR)
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(1920, 1080, "Odin Crawler")
	defer rl.CloseWindow()

	camera := rl.Camera3D {
		position   = {5, 1.8, 5},
		target     = {0, 0, 0},
		up         = {0, 1, 0},
		fovy       = 60,
		projection = .PERSPECTIVE,
	}

	atlas := rl.LoadTexture("res/atlas1.png")
	defer rl.UnloadTexture(atlas)

	shader := rl.LoadShader("res/shader/alpha_testing.vs", "res/shader/alpha_testing.fs")
	defer rl.UnloadShader(shader)

	//seed := u64(1377)
	seed := u64(time.to_unix_nanoseconds(time.now()))
	r := rand.create(seed)
	context.random_generator = rand.default_random_generator(&r)

	tex_len := f32(8.0)
	floor_tiler, ok := NewTiler(atlas.id, tex_len, []Tile{
		{
			name = .FloorGrateFuzzed,
			prob = 0.9
		},
		{
			name = .FloorGrateFuzzedWithRedDot,
			prob = 0.1
		},
	})
	if !ok {
		panic("could not construct floor tiler")
	}
	defer free(floor_tiler)

	ceiling_tiler: ^Tiler
	ceiling_tiler, ok = NewTiler(atlas.id, tex_len, []Tile{
		{
			name = .CeilingTile,
			prob = 1.0
		},
	})
	if !ok {
		panic("could not construct ceiling tiler")
	}
	defer free(ceiling_tiler)


	wall_tiler: ^Tiler
	wall_tiler, ok = NewTiler(atlas.id, tex_len, []Tile{
		{
			name = .HorizontalPipe,
			prob = 0.95
		},
		{
			name = .HorizontalPipeWithPurpleSlime,
			prob = 0.04
		},
		{
			name = .HorizontalPipeWithEye,
			prob = 0.01
		},
	})
	if !ok {
		panic("could not construct wall tiler")
	}
	defer free(wall_tiler)

	column_tiler: ^Tiler
	column_tiler, ok = NewTiler(atlas.id, tex_len, []Tile{
		{
			name = .BlueCrate,
			prob = 1.0
		},
	})
	if !ok {
		panic("could not construct column tiler")
	}
	defer free(column_tiler)

	crate_tiler: ^Tiler
	crate_tiler, ok = NewTiler(atlas.id, tex_len, []Tile{
		{
			name = .OrangeCrate,
			prob = 1.0,
		},
	})
	if !ok {
		panic("could not construct crate tiler")
	}
	defer free(crate_tiler)

	billboard_tiler: ^Tiler
	billboard_tiler, ok = NewTiler(
		atlas.id, 
		tex_len, 
		[]Tile{
			{
				name = .LightningGlobe1,
			},
			{
				name = .LightningGlobe2,
			},
			{
				name = .LightningGlobe3,
			},
		},
		.ROUND_ROBBIN,
	)
	if !ok {
		panic("could not construct billboard tiler")
	}
	defer free(billboard_tiler)

	hit_boxes: [dynamic]rl.Rectangle
	defer delete(hit_boxes)

	rl.SetTargetFPS(60)
	for !rl.WindowShouldClose() {
		rand.reset(seed)

		dt := rl.GetFrameTime()
		{
			movement: rl.Vector3
			if rl.IsKeyDown(.W) { movement += {1, 0, 0} }
			if rl.IsKeyDown(.S) { movement -= {1, 0, 0} }
			if rl.IsKeyDown(.A) { movement -= {0, 1, 0} }
			if rl.IsKeyDown(.D) { movement += {0, 1, 0} }
			if rl.IsKeyDown(.G) { seed = u64(time.to_unix_nanoseconds(time.now())) }

			movement = linalg.normalize0(movement)
			movement *= dt * 4

			mouse_delta := rl.GetMouseDelta()
			dr: rl.Vector3
			dr.xy = mouse_delta * dt * 4
			dr.y = dr.y
			rl.UpdateCameraPro(&camera, movement = movement, rotation = dr, zoom = 0)
		}

		player_hit_box := rl.Rectangle{-0.2, -0.2, 0.4, 0.4}
		player_hit_box.x += camera.position.x
		player_hit_box.y += camera.position.z
		any_collision := false
		for box in hit_boxes {
			if rl.CheckCollisionRecs(player_hit_box, box) {
				any_collision = true
				diff := rl.GetCollisionRec(player_hit_box, box)
				if diff.width > diff.height {
					if diff.y > box.y {
						camera.position.z += diff.height
					} else {
						camera.position.z -= diff.height	
					}
				} else {
					if diff.x > box.x {
						camera.position.x += diff.width
					} else {
						camera.position.x -= diff.width	
					}
				}
			}
		}
		clear(&hit_boxes)

		rl.DisableCursor()

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLANK)

		rl.BeginMode3D(camera)

		// Floor
		floor_size := f32(10.0)
		append(&hit_boxes, rl.Rectangle{-floor_size, -floor_size-1, floor_size*2, 1})
		append(&hit_boxes, rl.Rectangle{-floor_size-1, -floor_size, 1, floor_size*2})
		append(&hit_boxes, rl.Rectangle{-floor_size, floor_size, floor_size*2, 1})
		append(&hit_boxes, rl.Rectangle{floor_size, -floor_size, 1, floor_size*2})
		for i in -floor_size..<f32(floor_size) {
			for j in -floor_size..<f32(floor_size) {
				floor_tex_idx := u8(1)
				if i32(i) % 2 == 0 && i32(j) % 2 !=0 {
					floor_tex_idx = 2
				}
				DrawFloor({i, j}, floor_tiler)
				DrawCeiling({i, j}, 4.0, ceiling_tiler)
				DrawWall({-floor_size, j}, .E, 4.0, wall_tiler)
				DrawWall({floor_size, j}, .W, 4.0, wall_tiler)

				if rand.int_max(100) == 0 {
					DrawColumn({i, j}, 4.0, column_tiler)
					append(&hit_boxes, rl.Rectangle{i, j, 1, 1})
				} else if rand.int_max(100) == 1 {
					DrawCrate({i, j}, crate_tiler)
					append(&hit_boxes, rl.Rectangle{i, j, 1, 1})
				}
			}

			DrawWall({i, -floor_size}, .S, 4.0, wall_tiler)
			DrawWall({i, floor_size}, .N, 4.0, wall_tiler)
		}

		rl.BeginShaderMode(shader)
		DrawBillboard({0, 0}, &camera, 1.0, billboard_tiler)
		DrawCrate({0, 0}, crate_tiler)
		append(&hit_boxes, rl.Rectangle{0, 0, 1, 1})
		rl.EndShaderMode()


		// Guide lines
		rl.DrawLine3D({0, 0, 0}, {20, 0, 0}, rl.RED)
		rl.DrawLine3D({0, 0, 0}, {0, 20, 0}, rl.GREEN)
		rl.DrawLine3D({0, 0, 0}, {0, 0, 20}, rl.BLUE)
		rl.DrawCube({200, 0, 0}, 5, 5, 5, rl.RED)
		rl.DrawCube({0, 200, 0}, 5, 5, 5, rl.GREEN)
		rl.DrawCube({0, 0, 200}, 5, 5, 5, rl.BLUE)

		rl.EndMode3D()

		if any_collision {
			rl.DrawText("FAIL", 10, 30, 50, rl.MAGENTA)
		}
		rl.DrawFPS(10, 10)
	}
}


