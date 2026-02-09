const rl = @cImport(@cInclude("raylib.h"));
const std = @import("std");

const window_width = 800;
const window_height = 600;

const Rectangle = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

const Velocity = struct {
    x: f32,
    y: f32,
};

const paddle_width = 100;
const paddle_height = 20;
const paddle_speed = 8;

const ball_size = 20;

fn bounce(ball: Rectangle, thing: Rectangle) Velocity {
    const overlap_x = @min(ball.x + ball.width, thing.x + thing.width) - @max(ball.x, thing.x);
    const overlap_y = @min(ball.y + ball.height, thing.y + thing.height) - @max(ball.y, thing.y);

    if (overlap_x <= 0 or overlap_y <= 0) return .{ .x = 0, .y = 0 };

    // Minimum penetration indicates the most recent axis to overlap, and therefore the colliding wall
    if (overlap_x < overlap_y) {
        const ball_mid = ball.x + (ball.width / 2);
        const thing_mid = thing.x + (thing.width / 2);
        // Which side collided?
        if (ball_mid < thing_mid) {
            return .{ .x = -overlap_x, .y = 0 };
        } else {
            return .{ .x = overlap_x, .y = 0 };
        }
    } else {
        const ball_mid = ball.y + (ball.height / 2);
        const thing_mid = thing.y + (thing.height / 2);
        // Which side collided?
        if (ball_mid < thing_mid) {
            return .{ .x = 0, .y = -overlap_y };
        } else {
            return .{ .x = 0, .y = overlap_y };
        }
    }
}

pub fn main() void {
    rl.InitWindow(window_width, window_height, "Breakout");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    var paddle = Rectangle{
        .x = @as(f32, (window_width - paddle_width)) / 2.0,
        .y = 550,
        .height = paddle_height,
        .width = paddle_width,
    };

    var ball = Rectangle{
        .x = @as(f32, (window_width - ball_size)) / 2.0,
        .y = paddle.y - 50,
        .width = ball_size,
        .height = ball_size,
    };
    var ball_velocity = Velocity{ .x = 5, .y = 5 };

    while (!rl.WindowShouldClose()) {
        // -- Modify world --
        // Move paddle
        if (rl.IsKeyDown(rl.KEY_LEFT)) paddle.x -= paddle_speed;
        if (rl.IsKeyDown(rl.KEY_RIGHT)) paddle.x += paddle_speed;

        // clamp paddle to world space
        if (paddle.x < 0) paddle.x = 0;
        if (paddle.x > window_width - paddle_width) paddle.x = window_width - paddle_width;

        // Move ball
        ball.x += ball_velocity.x;
        ball.y += ball_velocity.y;

        // Clamp ball to world space
        if (ball_velocity.x > 0) {
            const ball_x_edge = ball.x + ball_size;
            const overshoot = ball_x_edge - window_width;
            if (overshoot > 0) {
                ball_velocity.x = -ball_velocity.x;
                ball.x = window_width - overshoot - ball_size;
            }
        } else {
            if (ball.x < 0) {
                ball_velocity.x = -ball_velocity.x;
                ball.x = -ball.x;
            }
        }

        if (ball_velocity.y > 0) {
            const ball_y_edge = ball.y + ball_size;
            const overshoot = ball_y_edge - window_height;
            if (overshoot > 0) {
                ball_velocity.y = -ball_velocity.y;
                ball.y = window_height - overshoot - ball_size;
            }
        } else {
            if (ball.y < 0) {
                ball_velocity.y = -ball_velocity.y;
                ball.y = -ball.y;
            }
        }

        // Bounce off paddle
        const rebound = bounce(ball, paddle);
        if (rebound.x != 0) {
            ball.x += rebound.x;
            ball_velocity.x = -ball_velocity.x;
        } else if (rebound.y != 0) {
            ball.y += rebound.y;
            ball_velocity.y = -ball_velocity.y;
        }

        // -- Render --
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        // Draw paddle
        rl.DrawRectangle(@intFromFloat(paddle.x), @intFromFloat(paddle.y), paddle_width, paddle_height, rl.DARKGRAY);

        // Draw Ball
        rl.DrawRectangle(@intFromFloat(ball.x), @intFromFloat(ball.y), ball_size, ball_size, rl.DARKGRAY);

        rl.DrawFPS(10, 10);
        var buf: [64]u8 = undefined;
        const text = std.fmt.bufPrintZ(&buf, "{d:.2}ms", .{rl.GetFrameTime() * 1000.0}) catch "??";
        rl.DrawText(@ptrCast(text.ptr), 10, 30, 20, rl.DARKGRAY);
        rl.EndDrawing();
    }
}
