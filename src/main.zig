// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");

//
const player_lifes = 5;
const bricks_lines = 5;
const bricks_per_line = 20;
const bricks_position_y = 50;

// Type and Structure definition
const GameScreen = enum { logo, title, game_play, ending };

// define required struct
const Player = struct {
    position: rl.Vector2,
    speed: rl.Vector2,
    size: rl.Vector2,
    bounds: rl.Rectangle,
    lifes: usize,
};

const Ball = struct {
    position: rl.Vector2,
    speed: rl.Vector2,
    radius: f32,
    active: bool,
};

const Brick = struct {
    position: rl.Vector2,
    size: rl.Vector2,
    bounds: rl.Rectangle,
    resistance: i32,
    active: bool,
};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screen_width = 800;
    const screen_height = 450;

    // LESSON 01: Window initialization and screens management
    rl.initWindow(screen_width, screen_height, "PROJECT: BLOCKS GAME");
    defer rl.closeWindow(); // Close window and OpenGL context

    // NOTE: Load resources (textures, fonts, audio) after Window initialization

    // LESSON 05: Textures loading and drawing
    const texLogo = rl.loadTexture("resources/raylib_logo.png");
    const texBall = rl.loadTexture("resources/ball.png");
    const texPaddle = rl.loadTexture("resources/paddle.png");
    const texBrick = rl.loadTexture("resources/brick.png");

    // LESSON 06: Fonts loading and text drawing
    const font = rl.loadFont("resources/setback.png");

    // LESSON 07: Sounds and music loading and playing
    rl.initAudioDevice(); // Initialize audio system

    const fxStart = rl.loadSound("resources/start.wav");
    const fxBounce = rl.loadSound("resources/bounce.wav");
    const fxExplode = rl.loadSound("resources/explosion.wav");

    // const music = rl.loadMusicStream("resources/blockshock.mod");
    const music = rl.loadMusicStream("resources/country.mp3");

    rl.playMusicStream(music); // Start music streaming

    // Game required variables
    var screen: GameScreen = .logo; // Current game screen state
    var frames_counter: u32 = 0;
    //    var game_result = -1;
    var game_paused = false;

    // TODO: Define and initialize game variables
    var player: Player = undefined;
    var ball: Ball = undefined;
    var bricks: [bricks_lines][bricks_per_line]Brick = undefined;

    player.position = rl.Vector2{ .x = screen_width / 2, .y = screen_height * 7 / 8 };
    player.speed = rl.Vector2{ .x = 8.0, .y = 0.0 };
    player.size = rl.Vector2{ .x = 100, .y = 24 };
    player.lifes = player_lifes;

    ball.radius = 10.0;
    ball.active = false;
    ball.position = rl.Vector2{ .x = player.position.x + player.size.x / 2, .y = player.position.y - ball.radius * 2 };
    ball.speed = rl.Vector2{ .x = 4.0, .y = 4.0 };

    // Initialize bricks
    for (0..bricks_lines) |j| {
        for (0..bricks_per_line) |i| {
            const ii: f32 = @floatFromInt(i);
            const jj: f32 = @floatFromInt(j);
            bricks[j][i].size = rl.Vector2{ .x = screen_width / bricks_per_line, .y = 20 };
            bricks[j][i].position = rl.Vector2{ .x = ii * bricks[j][i].size.x, .y = jj * bricks[j][i].size.y + bricks_position_y };
            bricks[j][i].bounds = rl.Rectangle{ .x = bricks[j][i].position.x, .y = bricks[j][i].position.y, .width = bricks[j][i].size.x, .height = bricks[j][i].size.y };
            bricks[j][i].active = true;
        }
    }

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        switch (screen) {
            .logo => {
                // Update LOGO screen data here!
                frames_counter += 1;
                if (frames_counter > 180) {
                    screen = .title;
                    frames_counter = 0;
                }
            },
            .title => {
                // Update TITLE screen data here!
                frames_counter += 1;
                if (rl.isKeyPressed(rl.KeyboardKey.key_enter)) {
                    screen = .game_play;
                    rl.playSound(fxStart);
                }
            },
            .game_play => {
                // Update GAMEPLAY screen data here!
                frames_counter += 1;
                if (rl.isKeyPressed(rl.KeyboardKey.key_p)) {
                    game_paused = !game_paused;
                    if (game_paused) {
                        rl.pauseMusicStream(music);
                    } else {
                        rl.resumeMusicStream(music);
                    }
                }
                if (!game_paused) {
                    // Player movement logic
                    if (rl.isKeyDown(rl.KeyboardKey.key_left)) player.position.x -= player.speed.x;
                    if (rl.isKeyDown(rl.KeyboardKey.key_right)) player.position.x += player.speed.x;

                    if ((player.position.x) <= 0) player.position.x = 0;
                    if ((player.position.x + player.size.x) >= screen_width) player.position.x = screen_width - player.size.x;

                    player.bounds = rl.Rectangle{ .x = player.position.x, .y = player.position.y, .width = player.size.x, .height = player.size.y };

                    if (ball.active) {
                        // Ball movement logic
                        ball.position.x += ball.speed.x;
                        ball.position.y += ball.speed.y;

                        // Collision logic: ball vs screen-limits
                        if (((ball.position.x + ball.radius) >= screen_width) or ((ball.position.x - ball.radius) <= 0)) ball.speed.x *= -1;
                        if ((ball.position.y - ball.radius) <= 0) ball.speed.y *= -1;

                        // Collision logic: ball vs player
                        if (rl.checkCollisionCircleRec(ball.position, ball.radius, player.bounds)) {
                            ball.speed.y *= -1;
                            ball.speed.x = (ball.position.x - (player.position.x + player.size.x / 2)) / player.size.x * 5.0;
                            rl.playSound(fxBounce);
                        }

                        // Collision logic: ball vs bricks
                        for (0..bricks_lines) |j| {
                            for (0..bricks_per_line) |i| {
                                if (bricks[j][i].active and (rl.checkCollisionCircleRec(ball.position, ball.radius, bricks[j][i].bounds))) {
                                    bricks[j][i].active = false;
                                    ball.speed.y *= -1;
                                    rl.playSound(fxExplode);
                                    break;
                                }
                            }
                        }

                        // Game ending logic
                        if ((ball.position.y + ball.radius) >= screen_height) {
                            ball.position.x = player.position.x + player.size.x / 2;
                            ball.position.y = player.position.y - ball.radius - 1.0;
                            ball.speed = rl.Vector2{ .x = 0, .y = 0 };
                            ball.active = false;

                            if (player.lifes > 0) {
                                player.lifes -= 1;
                            } else {
                                screen = .ending;
                                player.lifes = 5;
                                frames_counter = 0;
                            }
                        }
                    } else {
                        // Reset ball position
                        ball.position.x = player.position.x + player.size.x / 2;

                        // LESSON 03: Inputs management (keyboard, mouse)
                        if (rl.isKeyPressed(rl.KeyboardKey.key_space)) {
                            // Activate ball logic
                            ball.active = true;
                            ball.speed = rl.Vector2{ .x = 0, .y = -5.0 };
                        }
                    }
                }
            },
            .ending => {
                frames_counter += 1;
                if (rl.isKeyPressed(rl.KeyboardKey.key_enter)) {
                    screen = .title;
                }
            },
        }

        // LESSON 07: Sounds and music loading and playing
        // NOTE: Music buffers must be refilled if consumed
        rl.updateMusicStream(music);
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        switch (screen) {
            .logo => {
                // rl.drawText("LOGO SCREEN", 20, 20, 40, rl.Color.light_gray);
                // LESSON 05: Textures loading and drawing
                const pos_x: i32 = @divTrunc(screen_width, 2) - @divTrunc(texLogo.width, 2);
                const pos_y: i32 = @divTrunc(screen_height, 2) - @divTrunc(texLogo.height, 2);
                rl.drawTexture(texLogo, pos_x, pos_y, rl.Color.white);
            },
            .title => {
                // LESSON 06: Fonts loading and text drawing
                rl.drawTextEx(font, "BLOCKS", rl.Vector2{ .x = 100, .y = 80 }, 160, 10, rl.Color.maroon);

                // rl.drawText("TITLE SCREEN", 20, 20, 40, rl.Color.dark_green);
                const title_text = "PRESS [ENTER] to START";
                if ((frames_counter / 30) % 2 == 0) {
                    const pos_x = @divTrunc(rl.getScreenWidth(), 2) - @divTrunc(rl.measureText(title_text, 20), 2);
                    const pos_y = @divTrunc(rl.getScreenHeight(), 2) + 60;
                    rl.drawText(title_text, pos_x, pos_y, 20, rl.Color.dark_gray);
                }
            },
            .game_play => {
                // Draw GAMEPLAY screen here!

                // LESSON 02: Draw basic shapes (circle, rectangle)
                const lesson5_textures = true;
                if (lesson5_textures) {
                    rl.drawTextureEx(texPaddle, player.position, 0.0, 1.0, rl.Color.white); // Draw player

                    const radius: i32 = @intFromFloat(ball.radius);
                    var pos_x: i32 = @intFromFloat(ball.position.x);
                    pos_x -= @divTrunc(radius, 2);
                    var pos_y: i32 = @intFromFloat(ball.position.y);
                    pos_y -= @divTrunc(radius, 2);
                    rl.drawTexture(texBall, pos_x, pos_y, rl.Color.maroon); // Draw ball

                    // Draw bricks
                    for (0..bricks_lines) |j| {
                        for (0..bricks_per_line) |i| {
                            if (bricks[j][i].active) {
                                // const color = if ((i + j) % 2 == 0) rl.Color.gray else rl.Color.dark_gray;
                                const color = if ((i + j) % 2 == 0) rl.Color.blue else rl.Color.green;
                                rl.drawTextureEx(texBrick, bricks[j][i].position, 0.0, 1.0, color);
                            }
                        }
                    }
                } else {
                    var pos_x: i32 = @intFromFloat(player.position.x);
                    var pos_y: i32 = @intFromFloat(player.position.y);
                    var width: i32 = @intFromFloat(player.size.x);
                    var height: i32 = @intFromFloat(player.size.y);
                    rl.drawRectangle(pos_x, pos_y, width, height, rl.Color.black); // Draw player bar
                    rl.drawCircleV(ball.position, ball.radius, rl.Color.maroon); // Draw ball

                    // Draw bricks
                    for (0..bricks_lines) |j| {
                        for (0..bricks_per_line) |i| {
                            if (bricks[j][i].active) {
                                pos_x = @intFromFloat(bricks[j][i].position.x);
                                pos_y = @intFromFloat(bricks[j][i].position.y);
                                width = @intFromFloat(bricks[j][i].size.x);
                                height = @intFromFloat(bricks[j][i].size.y);
                                const color = if ((i + j) % 2 == 0) rl.Color.gray else rl.Color.dark_gray;
                                rl.drawRectangle(pos_x, pos_y, width, height, color);
                            }
                        }
                    }
                }

                // Draw GUI: player lives
                for (0..player.lifes) |i| {
                    const ii: i32 = @intCast(i);
                    rl.drawRectangle(20 + 40 * ii, screen_height - 30, 35, 10, rl.Color.light_gray);
                }

                // Draw pause message when required
                if (game_paused) {
                    const pos_x = screen_width / 2 - @divTrunc(rl.measureText("GAME PAUSED", 40), 2);
                    const pos_y = screen_height / 2 + 60;
                    rl.drawText("GAME PAUSED", pos_x, pos_y, 40, rl.Color.gray);
                }
            },
            .ending => {
                // LESSON 06: Fonts loading and text drawing
                // Draw ending message
                rl.drawTextEx(font, "GAME FINISHED", rl.Vector2{ .x = 80, .y = 100 }, 80, 6, rl.Color.maroon);
                const ending_text = "PRESS [ENTER] TO PLAY AGAIN";
                if ((frames_counter / 30) % 2 == 0) {
                    const pos_x = @divTrunc(rl.getScreenWidth(), 2) - @divTrunc(rl.measureText(ending_text, 20), 2);
                    const pos_y = @divTrunc(rl.getScreenHeight(), 2) + 60;
                    rl.drawText(ending_text, pos_x, pos_y, 20, rl.Color.dark_gray);
                }
            },
        }

        //----------------------------------------------------------------------------------
    }

    // NOTE: Unload any loaded resources (texture, fonts, audio)

    // LESSON 05: Textures loading and drawing
    rl.unloadTexture(texBall);
    rl.unloadTexture(texPaddle);
    rl.unloadTexture(texBrick);

    // LESSON 06: Fonts loading and text drawing
    rl.unloadFont(font);

    // LESSON 07: Sounds and music loading and playing
    rl.unloadSound(fxStart);
    rl.unloadSound(fxBounce);
    rl.unloadSound(fxExplode);

    rl.unloadMusicStream(music); // Unload music streaming buffers

    rl.closeAudioDevice(); // Close audio device connection
}
