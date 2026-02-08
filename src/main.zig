const rl = @cImport(@cInclude("raylib.h"));

const window_width = 800;
const window_height = 600;

const paddle_width = 100;
const paddle_height = 20;
const paddle_y = 550;
const paddle_speed = 8;

pub fn main() void {
    rl.InitWindow(window_width, window_height, "Breakout");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    var paddle_x: f32 = @as(f32, (window_width - paddle_width)) / 2.0;

    while (!rl.WindowShouldClose()) {
        // Update
        if (rl.IsKeyDown(rl.KEY_LEFT)) paddle_x -= paddle_speed;
        if (rl.IsKeyDown(rl.KEY_RIGHT)) paddle_x += paddle_speed;

        if (paddle_x < 0) paddle_x = 0;
        if (paddle_x > window_width - paddle_width) paddle_x = window_width - paddle_width;

        // Draw
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);
        rl.DrawRectangle(@intFromFloat(paddle_x), paddle_y, paddle_width, paddle_height, rl.DARKGRAY);
        rl.EndDrawing();
    }
}
