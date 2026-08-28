#include "smbcore/ctx.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

struct input_context {
  u8 ports[2];
};

static struct SMB_state state;
static struct input_context input_context;

static void decode_buttons(u8 bits, struct SMB_buttons *buttons) {
  *buttons = (struct SMB_buttons){
    .u = (bits & BUTTON_U) != 0,
    .d = (bits & BUTTON_D) != 0,
    .l = (bits & BUTTON_L) != 0,
    .r = (bits & BUTTON_R) != 0,
    .a = (bits & BUTTON_A) != 0,
    .b = (bits & BUTTON_B) != 0,
    .select = (bits & BUTTON_SELECT) != 0,
    .start = (bits & BUTTON_START) != 0,
  };
}

static void read_joy1(void *userdata, struct SMB_buttons *buttons) {
  const struct input_context *context = userdata;
  decode_buttons(context->ports[0], buttons);
}

static void read_joy2(void *userdata, struct SMB_buttons *buttons) {
  const struct input_context *context = userdata;
  decode_buttons(context->ports[1], buttons);
}

static void print_hex(const u8 *bytes, size_t length) {
  for (size_t index = 0; index < length; index++) {
    printf("%02x", bytes[index]);
  }
}

static void input_vectors(void) {
  static const u8 inputs[] = {
    0x00, BUTTON_START, BUTTON_START, 0x00, BUTTON_START,
    BUTTON_SELECT, BUTTON_SELECT, 0x00, BUTTON_SELECT,
    BUTTON_A | BUTTON_START, BUTTON_A | BUTTON_START, 0x00, 0xff,
  };

  memset(state.rammem, 0, sizeof(state.rammem));
  for (u8 port = 0; port < 2; port++) {
    for (size_t index = 0; index < sizeof(inputs); index++) {
      input_context.ports[port] = inputs[index];
      ReadPortBits(port);
      printf("I\t%u\t%u\t%u\t%u\n", port, inputs[index],
             SavedJoypadBits[port], JoypadBitMask[port]);
    }
  }
}

static void seed_reset_ram(u8 salt) {
  for (size_t index = 0; index < 0x800; index++) {
    state.rammem[index] = (u8)(index * 37 + salt);
  }
}

static void reset_vector(const char *name, bool warm, bool valid_digits) {
  memset(&state.ppu, 0, sizeof(state.ppu));
  memset(state.ppuram, 0, sizeof(state.ppuram));
  seed_reset_ram(warm ? 0x53 : 0x0b);
  WarmBootValidation = warm ? 0xa5 : 0x00;
  for (u8 index = 0; index < 6; index++) {
    DisplayDigits[index] = index;
  }
  if (!valid_digits) {
    DisplayDigits[3] = 10;
  }

  Reset();
  printf("R\t%s\t", name);
  print_hex(state.rammem, 0x800);
  putchar('\n');
}

static void reset_vectors(void) {
  reset_vector("cold", false, true);
  reset_vector("warm", true, true);
  reset_vector("invalid-digits", true, false);
}

static void fill_timer_region(void) {
  for (size_t index = 0; index <= 0x23; index++) {
    RAM(0x780 + index) = (u8)((index * 29 + 3) & 0x0f);
  }
}

static void timer_vector(const char *name, u8 control, u8 interval) {
  memset(state.rammem, 0, sizeof(state.rammem));
  fill_timer_region();
  TimerControl = control;
  IntervalTimerControl = interval;
  dectimers();

  printf("T\t%s\t%u\t%u\t", name, TimerControl, IntervalTimerControl);
  print_hex(&RAM(0x780), 0x24);
  putchar('\n');
}

static void timer_vectors(void) {
  timer_vector("control-3", 3, 0);
  timer_vector("control-1", 1, 7);
  timer_vector("interval-1", 0, 1);
  timer_vector("interval-0", 0, 0);
  timer_vector("interval-ff", 0, 0xff);
}

static void prng_vector(const char *name, const u8 seed[7], size_t iterations) {
  u8 value[7];
  memcpy(value, seed, sizeof(value));
  for (size_t index = 0; index < iterations; index++) {
    update_prng(value);
  }

  printf("P\t%s\t%zu\t", name, iterations);
  print_hex(value, sizeof(value));
  putchar('\n');
}

static void prng_vectors(void) {
  static const u8 canonical[7] = {0xa5, 0, 0, 0, 0, 0, 0};
  static const u8 zero[7] = {0, 0, 0, 0, 0, 0, 0};
  static const u8 ones[7] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
  static const u8 alternating[7] = {0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa};
  static const size_t checkpoints[] = {0, 1, 2, 3, 8, 40, 100, 32767};

  for (size_t index = 0; index < sizeof(checkpoints) / sizeof(checkpoints[0]); index++) {
    prng_vector("canonical", canonical, checkpoints[index]);
  }
  prng_vector("zero", zero, 100);
  prng_vector("ones", ones, 100);
  prng_vector("alternating", alternating, 100);
}

static void score_vector(const char *name, const u8 top[6], const u8 player_one[6],
                         const u8 player_two[6]) {
  memset(state.rammem, 0, sizeof(state.rammem));
  memcpy(&DisplayDigits[0], top, 6);
  memcpy(&DisplayDigits[6], player_one, 6);
  memcpy(&DisplayDigits[12], player_two, 6);

  u8 initial[18];
  memcpy(initial, DisplayDigits, sizeof(initial));
  UpdateTopScore();
  printf("S\t%s\t", name);
  print_hex(initial, sizeof(initial));
  putchar('\t');
  print_hex(DisplayDigits, 6);
  putchar('\n');
}

static void score_vectors(void) {
  static const u8 top[6] = {1, 2, 3, 4, 5, 6};
  static const u8 below[6] = {1, 2, 3, 4, 5, 5};
  static const u8 far_below[6] = {1, 0, 0, 0, 0, 0};
  static const u8 above[6] = {2, 2, 3, 4, 5, 6};
  static const u8 between[6] = {2, 0, 0, 0, 0, 0};
  static const u8 maximum[6] = {9, 9, 9, 9, 9, 9};

  score_vector("both-below", top, below, far_below);
  score_vector("player-one-above", top, above, between);
  score_vector("player-two-above", top, far_below, maximum);
  score_vector("equal", top, top, below);
}

struct pause_case {
  const char *name;
  u8 mode;
  u8 task;
  u8 saved;
  u8 status;
  u8 timer;
  u8 queue;
};

static void pause_vectors(void) {
  static const struct pause_case cases[] = {
    {"title-ineligible", OM_TITLESCREEN, OMT_TITLESCREEN_GAMEMENUROUTINE, BUTTON_START, 0, 0, 0},
    {"game-task-ineligible", OM_GAME, OMT_GAME_SECONDARYGAMESETUP, BUTTON_START, 0, 0, 0},
    {"game-release", OM_GAME, OMT_GAME_GAMECOREROUTINE, 0, 0x81, 0, 7},
    {"victory-release", OM_VICTORY, OMT_VICTORY_BRIDGECOLLAPSE, 0, 0x80, 0, 7},
    {"cooldown", OM_GAME, OMT_GAME_GAMECOREROUTINE, BUTTON_START, 0, 2, 7},
    {"pause", OM_GAME, OMT_GAME_GAMECOREROUTINE, BUTTON_START, 0, 0, 7},
    {"unpause", OM_GAME, OMT_GAME_GAMECOREROUTINE, BUTTON_START, 1, 0, 7},
    {"held", OM_GAME, OMT_GAME_GAMECOREROUTINE, BUTTON_START, 0x80, 0, 7},
  };

  for (size_t index = 0; index < sizeof(cases) / sizeof(cases[0]); index++) {
    const struct pause_case value = cases[index];
    memset(state.rammem, 0, sizeof(state.rammem));
    OperMode = value.mode;
    OperMode_Task = value.task;
    SavedJoypadBits[0] = value.saved;
    GamePauseStatus = value.status;
    GamePauseTimer = value.timer;
    PauseSoundQueue = value.queue;
    PauseRoutine();
    printf("U\t%s\t%u\t%u\t%u\n", value.name, GamePauseStatus,
           GamePauseTimer, PauseSoundQueue);
  }
}

static void mode_vectors(void) {
  static const char *title[] = {"initialize-game", "screen-routines", "primary-game-setup", "game-menu"};
  static const char *game[] = {"initialize-area", "screen-routines", "secondary-game-setup", "game-core"};
  static const char *victory[] = {"bridge-collapse", "setup-victory", "player-victory-walk", "print-victory-messages", "player-end-world"};
  static const char *gameover[] = {"setup-game-over", "screen-routines", "run-game-over"};

  for (size_t task = 0; task < sizeof(title) / sizeof(title[0]); task++) {
    printf("M\t%u\t%zu\ttitle-screen/%s\n", OM_TITLESCREEN, task, title[task]);
  }
  for (size_t task = 0; task < sizeof(game) / sizeof(game[0]); task++) {
    printf("M\t%u\t%zu\tgame/%s\n", OM_GAME, task, game[task]);
  }
  for (size_t task = 0; task < sizeof(victory) / sizeof(victory[0]); task++) {
    printf("M\t%u\t%zu\tvictory/%s\n", OM_VICTORY, task, victory[task]);
  }
  for (size_t task = 0; task < sizeof(gameover) / sizeof(gameover[0]); task++) {
    printf("M\t%u\t%zu\tgame-over/%s\n", OM_GAMEOVER, task, gameover[task]);
  }
}

int main(void) {
  SMB_STATE = &state;
  state.callbacks.userdata = &input_context;
  state.callbacks.joy1 = read_joy1;
  state.callbacks.joy2 = read_joy2;

  input_vectors();
  reset_vectors();
  timer_vectors();
  prng_vectors();
  score_vectors();
  pause_vectors();
  mode_vectors();
  return 0;
}
