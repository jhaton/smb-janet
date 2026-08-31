#include "smbcore/ctx.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct oracle_context {
  FILE *rom;
};

static struct SMB_state state;
static struct oracle_context context;

static bool oracle_read_rom(void *userdata, u8 *buffer, size_t size) {
  struct oracle_context *oracle = userdata;
  return fread(buffer, size, 1, oracle->rom) == 1;
}

static bool oracle_seek_rom(void *userdata, size_t offset) {
  struct oracle_context *oracle = userdata;
  return fseek(oracle->rom, (long)offset, SEEK_SET) == 0;
}

static void print_hex(const u8 *bytes, size_t length) {
  for (size_t index = 0; index < length; index++) {
    printf("%02x", bytes[index]);
  }
}

static void prepare_player(void) {
  memset(state.rammem, 0, 0x800);
  OperMode = OM_GAME;
  OperMode_Task = OMT_GAME_GAMECOREROUTINE;
  GameEngineSubroutine = GR_PLAYERCTRLROUTINE;
  Player_State = PLAYERSTATE_ONGROUND;
  PlayerFacingDir = BUTTON_R;
  Player_MovingDir = BUTTON_R;
  Player_CollisionBits = 0xff;
  Player_PageLoc = 1;
  Player_X_Position = 0x80;
  Player_Y_HighPos = 1;
  Player_Y_Position = 0x80;
  ScreenLeft_PageLoc = 1;
  ScreenLeft_X_Pos = 0;
  GetScreenPosition();
  AreaType = AREA_GROUND;
  PlayerSize = 1;
  PlayerAnimTimerSet = 4;
  MaximumLeftSpeed = 0xd8;
  MaximumRightSpeed = 0x28;
  FrictionAdderHigh = 0;
  FrictionAdderLow = 0xe4;
}

enum operation {
  OP_PHYSICS,
  OP_MOVEMENT,
  OP_COLLISION,
  OP_VERTICAL_PIPE,
  OP_SIDE_PIPE,
  OP_VINE,
  OP_CHANGE_SIZE,
  OP_INJURY,
  OP_DEATH,
  OP_FIRE_FLOWER,
  OP_ACTION,
  OP_CHANGE_ANIMATION,
  OP_CONTROL,
  OP_GRAPHICS,
};

static void emit(enum operation operation, const char *name) {
  printf("V\t%u\t%s\t", operation, name);
  print_hex(state.rammem, 0x800);
  putchar('\t');

  u8 result = 0;
  switch (operation) {
  case OP_PHYSICS: PlayerPhysicsSub(); break;
  case OP_MOVEMENT: PlayerMovementSubs(); break;
  case OP_COLLISION: PlayerBGCollision(); break;
  case OP_VERTICAL_PIPE: VerticalPipeEntry(); break;
  case OP_SIDE_PIPE: SideExitPipeEntry(); break;
  case OP_VINE: Vine_AutoClimb(); break;
  case OP_CHANGE_SIZE: PlayerChangeSize(); break;
  case OP_INJURY: PlayerInjuryBlink(); break;
  case OP_DEATH: PlayerDeath(); break;
  case OP_FIRE_FLOWER: PlayerFireFlower(); break;
  case OP_ACTION: result = ProcessPlayerAction(); break;
  case OP_CHANGE_ANIMATION: result = HandleChangeSize(); break;
  case OP_CONTROL: PlayerCtrlRoutine(); break;
  case OP_GRAPHICS: PlayerGfxHandler(); break;
  }

  printf("%u\t", result);
  print_hex(state.rammem, 0x800);
  putchar('\n');
}

static void physics_vectors(void) {
  static const u8 states[] = {
    PLAYERSTATE_ONGROUND, PLAYERSTATE_JUMPSWIM,
    PLAYERSTATE_FALLING, PLAYERSTATE_CLIMBING,
  };
  static const u8 buttons[] = {0, BUTTON_A, BUTTON_B, BUTTON_A | BUTTON_B};
  static const u8 previous[] = {0, BUTTON_A};
  static const u8 directions[] = {0, BUTTON_L, BUTTON_R};
  static const u8 speeds[] = {0, 8, 9, 15, 16, 24, 25, 27, 28, 33};

  unsigned sequence = 0;
  for (size_t state_index = 0; state_index < sizeof(states); state_index++) {
    for (size_t button_index = 0; button_index < sizeof(buttons); button_index++) {
      for (size_t previous_index = 0; previous_index < sizeof(previous); previous_index++) {
        for (size_t direction_index = 0; direction_index < sizeof(directions); direction_index++) {
          for (size_t speed_index = 0; speed_index < sizeof(speeds); speed_index++) {
            prepare_player();
            Player_State = states[state_index];
            A_B_Buttons = buttons[button_index];
            PreviousA_B_Buttons = previous[previous_index];
            Left_Right_Buttons = directions[direction_index];
            Player_XSpeedAbsolute = speeds[speed_index];
            Player_X_Speed = directions[direction_index] == BUTTON_L ? 0xf0 : 0x10;
            Player_Y_Speed = (button_index & 1) ? 0xfb : 1;
            SwimmingFlag = (state_index == 1 && (speed_index & 1)) ? 1 : 0;
            Whirlpool_Flag = (speed_index == 33) ? 1 : 0;
            RunningTimer = (speed_index == 24) ? 3 : 0;
            PlayerFacingDir = (direction_index == 1) ? BUTTON_L : BUTTON_R;
            Player_MovingDir = (button_index & 2) ? (PlayerFacingDir ^ 3) : PlayerFacingDir;
            if (Player_State == PLAYERSTATE_CLIMBING) {
              Up_Down_Buttons = directions[direction_index] == 0 ? 0 :
                                (direction_index == 1 ? BUTTON_U : BUTTON_D);
              Player_CollisionBits = directions[direction_index] == 0 ? 0 : 0xff;
            }
            char name[32];
            snprintf(name, sizeof(name), "physics-%u", sequence++);
            emit(OP_PHYSICS, name);
          }
        }
      }
    }
  }
}

static void movement_vectors(void) {
  static const u8 states[] = {
    PLAYERSTATE_ONGROUND, PLAYERSTATE_JUMPSWIM,
    PLAYERSTATE_FALLING, PLAYERSTATE_CLIMBING,
  };
  static const u8 directions[] = {0, BUTTON_L, BUTTON_R};
  static const u8 xspeeds[] = {0, 8, 0x18, 0x28, 0xd8, 0xe8, 0xf0};
  unsigned sequence = 0;

  for (size_t state_index = 0; state_index < sizeof(states); state_index++) {
    for (size_t direction_index = 0; direction_index < sizeof(directions); direction_index++) {
      for (size_t speed_index = 0; speed_index < sizeof(xspeeds); speed_index++) {
        prepare_player();
        Player_State = states[state_index];
        Left_Right_Buttons = directions[direction_index];
        SavedJoypadBits[0] = directions[direction_index];
        Player_X_Speed = xspeeds[speed_index];
        Player_XSpeedAbsolute = xspeeds[speed_index] >= 0x80 ?
                                (u8)-xspeeds[speed_index] : xspeeds[speed_index];
        Player_Y_Speed = state_index == 1 ? 0xfb : 2;
        Player_Y_MoveForce = 0x40;
        Player_YMF_Dummy = 0x80;
        SwimmingFlag = state_index == 1 && (speed_index & 1);
        A_B_Buttons = speed_index == 3 ? BUTTON_B : 0;
        PlayerFacingDir = direction_index == 1 ? BUTTON_L : BUTTON_R;
        Player_MovingDir = speed_index >= 4 ? BUTTON_L : BUTTON_R;
        if (Player_State == PLAYERSTATE_CLIMBING) {
          Up_Down_Buttons = direction_index == 0 ? 0 :
                            (direction_index == 1 ? BUTTON_U : BUTTON_D);
          Player_CollisionBits = direction_index == 0 ? 0 : 0xff;
          ClimbSideTimer = speed_index == 0 ? 0 : 1;
        }
        char name[32];
        snprintf(name, sizeof(name), "movement-%u", sequence++);
        emit(OP_MOVEMENT, name);
      }
    }
  }
}

static void set_probe(u8 use_x, u8 probe, u8 metatile) {
  const struct blockbuffer_colli_result result =
    BlockBufferCollision_coords(use_x, 0, probe);
  set_metatile(result.mt_x, result.mt_y, metatile);
}

static void collision_case(const char *name, int probe, u8 metatile,
                           int second_probe, u8 second_metatile) {
  prepare_player();
  Player_State = PLAYERSTATE_FALLING;
  Player_Y_Speed = 2;
  if (probe >= 0) {
    set_probe(probe >= 17, (u8)probe, metatile);
  }
  if (second_probe >= 0) {
    set_probe(second_probe >= 17, (u8)second_probe, second_metatile);
  }
  emit(OP_COLLISION, name);
}

static void collision_vectors(void) {
  collision_case("empty", -1, 0, -1, 0);
  collision_case("floor-left", 15, 0x54, -1, 0);
  collision_case("floor-right", 16, 0x54, -1, 0);
  collision_case("floor-coin", 15, 0xc2, -1, 0);
  collision_case("floor-jumpspring", 15, 0x67, -1, 0);

  prepare_player();
  Player_State = PLAYERSTATE_JUMPSWIM;
  Player_Y_Speed = 0xfb;
  set_probe(0, 14, 0x54);
  emit(OP_COLLISION, "head-solid");

  prepare_player();
  Player_State = PLAYERSTATE_JUMPSWIM;
  Player_Y_Speed = 0xfb;
  set_probe(0, 14, 0xc2);
  emit(OP_COLLISION, "head-coin");

  prepare_player();
  PlayerSize = 0;
  Player_State = PLAYERSTATE_JUMPSWIM;
  Player_Y_Position = 0x84;
  Player_Y_Speed = 0xfb;
  BlockOffsetToggle = 1;
  set_probe(0, 0, 0x52);
  emit(OP_COLLISION, "head-brick-big-slot1");

  prepare_player();
  Player_State = PLAYERSTATE_JUMPSWIM;
  Player_Y_Position = 0x84;
  Player_Y_Speed = 0xfb;
  set_probe(0, 14, MT_QUESTIONBLOCK_POWERUP);
  emit(OP_COLLISION, "head-question-powerup-small");

  prepare_player();
  Player_State = PLAYERSTATE_JUMPSWIM;
  Player_Y_Speed = 0xfb;
  BlockBounceTimer = 1;
  set_probe(0, 14, MT_BRICK);
  emit(OP_COLLISION, "head-block-while-bounce-active");

  collision_case("right-wall", 17, 0x54, -1, 0);
  collision_case("left-wall", 19, 0x54, -1, 0);
  collision_case("right-wall-used-block", 17, MT_BLOCK_EMPTY, -1, 0);
  collision_case("axe", 16, MT_AXE, -1, 0);

  prepare_player();
  Player_State = PLAYERSTATE_ONGROUND;
  Up_Down_Buttons = BUTTON_D;
  set_probe(0, 15, 0x10);
  set_probe(0, 16, 0x11);
  emit(OP_COLLISION, "vertical-pipe");

  static const u8 warp_x[] = {0x50, 0x80, 0xb0};
  for (size_t index = 0; index < sizeof(warp_x); index++) {
    prepare_player();
    Player_State = PLAYERSTATE_ONGROUND;
    Player_X_Position = warp_x[index];
    Up_Down_Buttons = BUTTON_D;
    WarpZoneControl = 1;
    set_probe(0, 15, 0x10);
    set_probe(0, 16, 0x11);
    char name[32];
    snprintf(name, sizeof(name), "vertical-pipe-warp-%zu", index);
    emit(OP_COLLISION, name);
  }

  prepare_player();
  Player_State = PLAYERSTATE_ONGROUND;
  PlayerFacingDir = BUTTON_R;
  set_probe(1, 17, 0x1c);
  set_probe(1, 18, 0x1f);
  set_probe(1, 15, 0x54);
  emit(OP_COLLISION, "side-pipe");

  prepare_player();
  Player_X_Position = 0x86;
  set_probe(1, 18, 0x24);
  emit(OP_COLLISION, "flagpole");

  prepare_player();
  Player_Y_Position = 0x10;
  Player_X_Position = 0x86;
  set_probe(1, 18, 0x26);
  emit(OP_COLLISION, "vine");

  prepare_player();
  SwimmingFlag = 1;
  Player_State = PLAYERSTATE_ONGROUND;
  emit(OP_COLLISION, "swimming-empty");
}

static void transition_vectors(void) {
  static const u8 timers[] = {1, 2, 0xff};
  for (size_t index = 0; index < sizeof(timers); index++) {
    prepare_player();
    GameEngineSubroutine = GR_VERTICALPIPEENTRY;
    ChangeAreaTimer = timers[index];
    AreaType = index == 2 ? AREA_CASTLE : AREA_GROUND;
    char name[32];
    snprintf(name, sizeof(name), "vertical-%u", timers[index]);
    emit(OP_VERTICAL_PIPE, name);

    prepare_player();
    GameEngineSubroutine = GR_SIDEEXITPIPEENTRY;
    ChangeAreaTimer = timers[index];
    Player_X_Position = index == 0 ? 0x80 : 0x83;
    snprintf(name, sizeof(name), "side-%u", timers[index]);
    emit(OP_SIDE_PIPE, name);
  }

  prepare_player();
  GameEngineSubroutine = GR_VINE_AUTOCLIMB;
  Player_Y_HighPos = 0;
  Player_Y_Position = 0xe0;
  emit(OP_VINE, "vine-finished");

  prepare_player();
  GameEngineSubroutine = GR_VINE_AUTOCLIMB;
  Player_Y_HighPos = 1;
  Player_Y_Position = 0x40;
  emit(OP_VINE, "vine-climbing");
}

static void status_vectors(void) {
  static const u8 sizes[] = {0, 1};
  static const u8 change_timers[] = {0xf8, 0xc4, 0xc5};
  for (size_t size_index = 0; size_index < sizeof(sizes); size_index++) {
    for (size_t timer_index = 0; timer_index < sizeof(change_timers); timer_index++) {
      prepare_player();
      PlayerSize = sizes[size_index];
      GameEngineSubroutine = GR_PLAYERCHANGESIZE;
      TimerControl = change_timers[timer_index];
      char name[32];
      snprintf(name, sizeof(name), "change-%u-%u", sizes[size_index],
               change_timers[timer_index]);
      emit(OP_CHANGE_SIZE, name);
    }
  }

  static const u8 injury_timers[] = {0xf1, 0xf0, 0xc8, 0xc7};
  for (size_t index = 0; index < sizeof(injury_timers); index++) {
    prepare_player();
    DisableCollisionDet = 1;
    GameEngineSubroutine = GR_PLAYERINJURYBLINK;
    TimerControl = injury_timers[index];
    char name[32];
    snprintf(name, sizeof(name), "injury-%u", injury_timers[index]);
    emit(OP_INJURY, name);
  }

  static const u8 death_timers[] = {0xf0, 0xef};
  for (size_t index = 0; index < sizeof(death_timers); index++) {
    prepare_player();
    DisableCollisionDet = 1;
    GameEngineSubroutine = GR_PLAYERDEATH;
    TimerControl = death_timers[index];
    Player_Y_Speed = 2;
    char name[32];
    snprintf(name, sizeof(name), "death-%u", death_timers[index]);
    emit(OP_DEATH, name);
  }

  static const u8 flower_timers[] = {0xc1, 0xc0};
  for (size_t index = 0; index < sizeof(flower_timers); index++) {
    prepare_player();
    GameEngineSubroutine = GR_PLAYERFIREFLOWER;
    TimerControl = flower_timers[index];
    Player_SprAttrib = 0x23;
    FrameCounter = 7;
    char name[32];
    snprintf(name, sizeof(name), "flower-%u", flower_timers[index]);
    emit(OP_FIRE_FLOWER, name);
  }

  prepare_player();
  DisableCollisionDet = 1;
  Player_Y_HighPos = 2;
  EventMusicBuffer = 1;
  emit(OP_CONTROL, "control-fall-start");

  prepare_player();
  DisableCollisionDet = 1;
  Player_Y_HighPos = 6;
  EventMusicBuffer = 0;
  emit(OP_CONTROL, "control-fall-finished");
}

static void animation_vectors(void) {
  static const u8 states[] = {
    PLAYERSTATE_ONGROUND, PLAYERSTATE_JUMPSWIM,
    PLAYERSTATE_FALLING, PLAYERSTATE_CLIMBING,
  };
  static const u8 sizes[] = {0, 1};
  static const u8 speeds[] = {0, 8, 9, 0x18};
  static const u8 controls[] = {0, 1, 3};
  unsigned sequence = 0;

  for (size_t state_index = 0; state_index < sizeof(states); state_index++) {
    for (size_t size_index = 0; size_index < sizeof(sizes); size_index++) {
      for (size_t speed_index = 0; speed_index < sizeof(speeds); speed_index++) {
        for (size_t control_index = 0; control_index < sizeof(controls); control_index++) {
          prepare_player();
          Player_State = states[state_index];
          PlayerSize = sizes[size_index];
          Player_X_Speed = speeds[speed_index];
          Player_XSpeedAbsolute = speeds[speed_index];
          Left_Right_Buttons = speed_index == 0 ? 0 : BUTTON_R;
          PlayerAnimCtrl = controls[control_index];
          PlayerAnimTimer = control_index == 0 ? 0 : 2;
          SwimmingFlag = state_index == 1 && (speed_index & 1);
          JumpSwimTimer = control_index == 3 ? 1 : 0;
          A_B_Buttons = control_index == 1 ? BUTTON_A : 0;
          Player_Y_Speed = state_index == 3 && speed_index != 0 ? 1 : 0;
          char name[32];
          snprintf(name, sizeof(name), "action-%u", sequence++);
          emit(OP_ACTION, name);
        }
      }
    }
  }

  for (u8 size = 0; size < 2; size++) {
    for (u8 control = 0; control < 10; control++) {
      for (u8 frame = 0; frame < 4; frame++) {
        prepare_player();
        PlayerSize = size;
        PlayerAnimCtrl = control;
        PlayerChangeSizeFlag = 1;
        FrameCounter = frame;
        char name[32];
        snprintf(name, sizeof(name), "resize-%u-%u-%u", size, control, frame);
        emit(OP_CHANGE_ANIMATION, name);
      }
    }
  }
}

static void graphics_vectors(void) {
  static const u8 states[] = {
    PLAYERSTATE_ONGROUND, PLAYERSTATE_JUMPSWIM,
    PLAYERSTATE_FALLING, PLAYERSTATE_CLIMBING,
  };
  unsigned sequence = 0;

  for (u8 size = 0; size < 2; size++) {
    for (u8 facing = 1; facing <= 2; facing++) {
      for (size_t state_index = 0; state_index < sizeof(states); state_index++) {
        for (u8 moving = 0; moving < 2; moving++) {
          prepare_player();
          PlayerSize = size;
          PlayerFacingDir = facing;
          Player_MovingDir = facing;
          Player_State = states[state_index];
          Player_X_Speed = moving ? (facing == BUTTON_R ? 0x10 : 0xf0) : 0;
          Player_XSpeedAbsolute = moving ? 0x10 : 0;
          Left_Right_Buttons = moving ? facing : 0;
          SwimmingFlag = states[state_index] == PLAYERSTATE_JUMPSWIM;
          Player_Y_Speed = states[state_index] == PLAYERSTATE_CLIMBING ? 1 : 0;
          Player_Rel_XPos = 0x70;
          Player_Rel_YPos = 0x80;
          Player_SprDataOffset = 4;
          Player_SprAttrib = 2;
          char name[32];
          snprintf(name, sizeof(name), "graphics-%u", sequence++);
          emit(OP_GRAPHICS, name);
        }
      }
    }
  }

  static const u8 offscreen[] = {0x10, 0x20, 0x40, 0x80};
  for (size_t index = 0; index < sizeof(offscreen); index++) {
    prepare_player();
    Player_Rel_XPos = 0x70;
    Player_Rel_YPos = 0x80;
    Player_SprDataOffset = 4;
    Player_OffscreenBits = offscreen[index];
    char name[32];
    snprintf(name, sizeof(name), "graphics-offscreen-%u", offscreen[index]);
    emit(OP_GRAPHICS, name);
  }
}

int main(int argc, char **argv) {
  if (argc != 2) {
    fprintf(stderr, "usage: %s ROM\n", argv[0]);
    return 2;
  }

  context.rom = fopen(argv[1], "rb");
  if (!context.rom) {
    perror(argv[1]);
    return 1;
  }

  const struct SMB_callbacks callbacks = {
    .userdata = &context,
    .read_rom_bytes = oracle_read_rom,
    .seek_rom = oracle_seek_rom,
  };
  if (!SMB_state_init(&state, &callbacks)) {
    fprintf(stderr, "failed to initialize SMB1 ROM\n");
    fclose(context.rom);
    return 1;
  }
  SMB_STATE = &state;

  physics_vectors();
  movement_vectors();
  collision_vectors();
  transition_vectors();
  status_vectors();
  animation_vectors();
  graphics_vectors();

  fclose(context.rom);
  return 0;
}
