const rl = @cImport(@cInclude("raylib.h"));
const std = @import("std");

const window_width = 800;
const window_height = 600;

const Rectangle = struct {
    pos: Position,
    width: f32,
    height: f32,
};

const Velocity = struct {
    x: f32,
    y: f32,
};

const Position = Velocity;

const paddle_width = 100;
const paddle_height = 20;
const paddle_speed = 8;

const ball_size = 20;

const GameState = enum { ready, playing };

const AxisState = struct { position: f32, velocity: f32 };
fn wall_bounce(axis_state: AxisState, size: f32, boundary: f32) AxisState {
    if (axis_state.velocity > 0) {
        const overshoot = (axis_state.position + size) - boundary;
        if (overshoot > 0) {
            return .{ .position = (boundary - overshoot - size), .velocity = -axis_state.velocity };
        }
    } else {
        if (axis_state.position < 0) {
            return .{ .position = -axis_state.position, .velocity = -axis_state.velocity };
        }
    }
    return axis_state;
}

fn bounce(ball: Rectangle, thing: Rectangle) Velocity {
    const overlap_x = @min(ball.pos.x + ball.width, thing.pos.x + thing.width) - @max(ball.pos.x, thing.pos.x);
    const overlap_y = @min(ball.pos.y + ball.height, thing.pos.y + thing.height) - @max(ball.pos.y, thing.pos.y);

    if (overlap_x <= 0 or overlap_y <= 0) return .{ .x = 0, .y = 0 };

    // Minimum penetration indicates the most recent axis to overlap, and therefore the colliding wall
    if (overlap_x < overlap_y) {
        const ball_mid = ball.pos.x + (ball.width / 2);
        const thing_mid = thing.pos.x + (thing.width / 2);
        // Which side collided?
        if (ball_mid < thing_mid) {
            return .{ .x = -overlap_x, .y = 0 };
        } else {
            return .{ .x = overlap_x, .y = 0 };
        }
    } else {
        const ball_mid = ball.pos.y + (ball.height / 2);
        const thing_mid = thing.pos.y + (thing.height / 2);
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
        .pos = .{
            .x = @as(f32, (window_width - paddle_width)) / 2.0,
            .y = 550,
        },
        .height = paddle_height,
        .width = paddle_width,
    };

    const ball_start_pos = Position{
        .x = @as(f32, (window_width - ball_size)) / 2.0,
        .y = paddle.pos.y - 50,
    };

    var ball = Rectangle{
        .pos = ball_start_pos,
        .width = ball_size,
        .height = ball_size,
    };

    var game_state = GameState.ready;

    const zero_velocity = Velocity{ .x = 0, .y = 0 };
    const start_velocity = Velocity{ .x = 5, .y = -5 };
    var ball_velocity = zero_velocity;

    while (!rl.WindowShouldClose()) {
        // Move paddle
        if (rl.IsKeyDown(rl.KEY_LEFT)) paddle.pos.x -= paddle_speed;
        if (rl.IsKeyDown(rl.KEY_RIGHT)) paddle.pos.x += paddle_speed;

        // clamp paddle to world space
        if (paddle.pos.x < 0) paddle.pos.x = 0;
        if (paddle.pos.x > window_width - paddle_width) paddle.pos.x = window_width - paddle_width;

        switch (game_state) {
            .ready => {
                if (rl.IsKeyDown(rl.KEY_SPACE)) {
                    ball.pos = ball_start_pos;
                    ball_velocity = start_velocity;
                    game_state = .playing;
                }
            },
            .playing => {
                // Move ball
                ball.pos.x += ball_velocity.x;
                ball.pos.y += ball_velocity.y;

                // Clamp ball to world space
                const x_bounce = wall_bounce(.{ .position = ball.pos.x, .velocity = ball_velocity.x }, ball.width, window_width);
                ball_velocity.x = x_bounce.velocity;
                ball.pos.x = x_bounce.position;

                const y_bounce = wall_bounce(.{ .position = ball.pos.y, .velocity = ball_velocity.y }, ball.height, window_height);
                if (y_bounce.velocity != ball_velocity.y and ball_velocity.y > 0) {
                    ball_velocity = zero_velocity;
                    ball.pos = ball_start_pos;
                    game_state = .ready;
                } else {
                    ball_velocity.y = y_bounce.velocity;
                    ball.pos.y = y_bounce.position;
                }

                // Bounce off paddle
                const rebound = bounce(ball, paddle);
                if (rebound.x != 0) {
                    ball.pos.x += rebound.x;
                    ball_velocity.x = -ball_velocity.x;
                } else if (rebound.y != 0) {
                    ball.pos.y += rebound.y;
                    ball_velocity.y = -ball_velocity.y;
                }
            },
        }

        // -- Render --
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        // Draw paddle
        rl.DrawRectangle(@intFromFloat(paddle.pos.x), @intFromFloat(paddle.pos.y), paddle_width, paddle_height, rl.DARKGRAY);

        // Draw Ball
        rl.DrawRectangle(@intFromFloat(ball.pos.x), @intFromFloat(ball.pos.y), ball_size, ball_size, rl.DARKGRAY);

        rl.DrawFPS(10, 10);
        var buf: [64]u8 = undefined;
        const text = std.fmt.bufPrintZ(&buf, "{d:.2}ms", .{rl.GetFrameTime() * 1000.0}) catch "??";
        rl.DrawText(@ptrCast(text.ptr), 10, 30, 20, rl.DARKGRAY);
        rl.EndDrawing();
    }
}
