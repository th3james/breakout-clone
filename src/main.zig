const rl = @cImport(@cInclude("raylib.h"));

const window_width = 800;
const window_height = 600;

const Vec2 = struct {
    x: f32,
    y: f32,
};

const paddle_width = 100;
const paddle_height = 20;
const paddle_speed = 8;

const ball_size = 20;

pub fn main() void {
    rl.InitWindow(window_width, window_height, "Breakout");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    var paddle_pos = Vec2{
        .x = @as(f32, (window_width - paddle_width)) / 2.0,
        .y = 550,
    };

    var ball_pos = Vec2{
        .x = @as(f32, (window_width - ball_size)) / 2.0,
        .y = paddle_pos.y - 50,
    };
    var ball_velocity = Vec2{ .x = 5, .y = 5 };

    while (!rl.WindowShouldClose()) {
        // -- Modify world --
        // Move paddle
        if (rl.IsKeyDown(rl.KEY_LEFT)) paddle_pos.x -= paddle_speed;
        if (rl.IsKeyDown(rl.KEY_RIGHT)) paddle_pos.x += paddle_speed;

        // clamp paddle to world space
        if (paddle_pos.x < 0) paddle_pos.x = 0;
        if (paddle_pos.x > window_width - paddle_width) paddle_pos.x = window_width - paddle_width;

        // Move ball
        ball_pos.x += ball_velocity.x;
        ball_pos.y += ball_velocity.y;

        // Clamp ball
        if (ball_pos.x < 0) {
            ball_velocity.x = -ball_velocity.x;
            ball_pos.x = -ball_pos.x;
        }

        const ball_x_edge = ball_pos.x + ball_size;
        var overshoot = ball_x_edge - window_width;
        if (overshoot > 0) {
            ball_velocity.x = -ball_velocity.x;
            ball_pos.x = window_width - overshoot - ball_size;
        }

        if (ball_pos.y < 0) {
            ball_velocity.y = -ball_velocity.y;
            ball_pos.y = -ball_pos.y;
        }

        const ball_y_edge = ball_pos.y + ball_size;
        overshoot = ball_y_edge - window_height;
        if (overshoot > 0) {
            ball_velocity.y = -ball_velocity.y;
            ball_pos.y = window_height - overshoot - ball_size;
        }

        // -- Render --
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        // Draw paddle
        rl.DrawRectangle(@intFromFloat(paddle_pos.x), @intFromFloat(paddle_pos.y), paddle_width, paddle_height, rl.DARKGRAY);

        // Draw Ball
        rl.DrawRectangle(@intFromFloat(ball_pos.x), @intFromFloat(ball_pos.y), ball_size, ball_size, rl.DARKGRAY);

        rl.EndDrawing();
    }
}
