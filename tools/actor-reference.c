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

static void prepare_actor(void) {
  memset(state.rammem, 0, 0x800);
  OperMode = OM_GAME;
  OperMode_Task = OMT_GAME_GAMECOREROUTINE;
  GameEngineSubroutine = GR_PLAYERCTRLROUTINE;
  Player_State = PLAYERSTATE_ONGROUND;
  PlayerStatus = PLAYERSTATUS_SMALL;
  PlayerSize = 1;
  PlayerFacingDir = BUTTON_R;
  Player_MovingDir = BUTTON_R;
  Player_CollisionBits = 0xff;
  Player_PageLoc = 1;
  Player_X_Position = 0x80;
  Player_Y_HighPos = 1;
  Player_Y_Position = 0x90;
  ScreenLeft_PageLoc = 1;
  ScreenLeft_X_Pos = 0;
  ScreenRight_PageLoc = 1;
  ScreenRight_X_Pos = 0xff;
  AreaType = AREA_GROUND;
  PrimaryHardMode = 0;
  SecondaryHardMode = 0;
  TimerControl = 0;
  IntervalTimerControl = 0;
  GetScreenPosition();
}

enum operation {
  OP_INITIALIZE,
  OP_MOVEMENT,
  OP_FIREBALL_BUBBLE,
  OP_FIREBALL,
  OP_BUBBLE,
  OP_BLOCK,
  OP_BLOCK_UPDATE,
  OP_MISC,
  OP_CANNONS,
  OP_WHIRLPOOLS,
  OP_FLAGPOLE,
  OP_PLAYER_COLLISION,
  OP_FIREBALL_COLLISION,
  OP_ENEMY_COLLISION,
  OP_ENEMY_BACKGROUND,
  OP_PLATFORM,
  OP_FLOATEY,
  OP_ACTOR_CORE,
};

static void emit(enum operation operation, u8 slot, const char *name) {
  printf("V\t%u\t%u\t%s\t", operation, slot, name);
  print_hex(state.rammem, 0x800);
  putchar('\t');

  switch (operation) {
  case OP_INITIALIZE: CheckpointEnemyID(slot); break;
  case OP_MOVEMENT: EnemyMovementSubs(slot); break;
  case OP_FIREBALL_BUBBLE: ProcFireball_Bubble(); break;
  case OP_FIREBALL: FireballObjCore(slot); break;
  case OP_BUBBLE: BubbleCheck(slot); break;
  case OP_BLOCK: BlockObjectsCore(slot); break;
  case OP_BLOCK_UPDATE: BlockObjMT_Updater(); break;
  case OP_MISC: MiscObjectsCore(); break;
  case OP_CANNONS: ProcessCannons(); break;
  case OP_WHIRLPOOLS: ProcessWhirlpools(); break;
  case OP_FLAGPOLE: FlagpoleRoutine(); break;
  case OP_PLAYER_COLLISION: PlayerEnemyCollision(slot); break;
  case OP_FIREBALL_COLLISION: FireballEnemyCollision(slot); break;
  case OP_ENEMY_COLLISION: EnemiesCollision(slot); break;
  case OP_ENEMY_BACKGROUND: EnemyToBGCollisionDet(slot); break;
  case OP_PLATFORM: LargePlatformSubroutines(slot); break;
  case OP_FLOATEY: FloateyNumbersRoutine(slot); break;
  case OP_ACTOR_CORE: RunEnemyObjectsCore(slot); break;
  }

  print_hex(state.rammem, 0x800);
  putchar('\n');
}

static void initialize_vectors(void) {
  static const u8 ids[] = {
    A_GREEN_KOOPA, A_RED_KOOPA_GREENLIKE, A_BUZZY_BEETLE, A_RED_KOOPA,
    A_HAMMER_BRO, A_GOOMBA, A_BLOOBER, A_BULLET_BILL,
    A_GREEN_PARATROOPA_INPLACE, A_CHEEPCHEEP_GRAY, A_CHEEPCHEEP_RED,
    A_PODOBOO, A_PIRANHA_PLANT, A_GREEN_PARATROOPA, A_RED_PARATROOPA,
    A_GREEN_PARATROOPA_HORIZONTAL, A_LAKITU, A_SPINY,
    A_FLYING_CHEEPCHEEP, A_BOWSER_FLAME, A_STOP_FRENZY,
    A_FIREBAR_1, A_FIREBAR_2, A_FIREBAR_3, A_FIREBAR_4, A_FIREBAR_5,
    A_LARGEPLATFORM_BALANCE, A_LARGEPLATFORM_Y_MOVING,
    A_LARGEPLATFORM_LIFT1, A_LARGEPLATFORM_LIFT2,
    A_LARGEPLATFORM_X_MOVING, A_LARGEPLATFORM_DROP, A_LARGEPLATFORM_RIGHT,
    A_SMALLPLATFORM_1, A_SMALLPLATFORM_2, A_BOWSER, A_POWERUP, A_VINE,
    A_RETAINER,
  };

  for (size_t id_index = 0; id_index < sizeof(ids); id_index++) {
    for (u8 hard = 0; hard < 2; hard++) {
      prepare_actor();
      Enemy_ID[0] = ids[id_index];
      Enemy_Flag[0] = 1;
      Enemy_PageLoc[0] = 1;
      Enemy_X_Position[0] = 0xa0;
      Enemy_Y_HighPos[0] = 1;
      Enemy_Y_Position[0] = 0x80;
      PrimaryHardMode = hard;
      SecondaryHardMode = hard;
      PseudoRandomBitReg[0] = 0x35;
      PseudoRandomBitReg[1] = 0xa6;
      BalPlatformAlignment = 0xff;
      PowerUpType = POWERUP_MUSHROOM;
      char name[48];
      snprintf(name, sizeof(name), "initialize-%u-%u", ids[id_index], hard);
      emit(OP_INITIALIZE, 0, name);
    }
  }

  prepare_actor();
  Enemy_ID[0] = A_FIREBAR_3;
  Enemy_Flag[0] = 1;
  Enemy_PageLoc[0] = 3;
  Enemy_X_Position[0] = 0xc0;
  Enemy_Y_HighPos[0] = 1;
  Enemy_Y_Position[0] = 0x60;
  Enemy_X_Speed[0] = 0x28;
  Enemy_Y_Speed[0] = 0x0c;
  emit(OP_INITIALIZE, 0, "initialize-firebar-preserves-high-spin-state");
}

static void movement_vectors(void) {
  static const u8 states[] = {0, 1, 2, 4, 5, 0x20, 0x40};
  static const u8 frames[] = {0, 1, 7, 0x40};
  for (u8 id = A_GREEN_KOOPA; id <= A_FLYING_CHEEPCHEEP; id++) {
    for (size_t state_index = 0; state_index < sizeof(states); state_index++) {
      for (size_t frame_index = 0; frame_index < sizeof(frames); frame_index++) {
        prepare_actor();
        Enemy_ID[0] = id;
        Enemy_Flag[0] = 1;
        Enemy_State[0] = states[state_index];
        Enemy_PageLoc[0] = 1;
        Enemy_X_Position[0] = 0xa0;
        Enemy_Y_HighPos[0] = 1;
        Enemy_Y_Position[0] = 0x80;
        Enemy_X_Speed[0] = 0xf8;
        Enemy_Y_Speed[0] = 2;
        Enemy_X_MoveForce[0] = 0x40;
        Enemy_Y_MoveForce[0] = 0x20;
        Enemy_YMF_Dummy[0] = 0x80;
        Enemy_MovingDir[0] = 2;
        EnemyIntervalTimer[0] = states[state_index] == 4 ? 1 : 0;
        EnemyFrameTimer[0] = 0;
        FrameCounter = frames[frame_index];
        PseudoRandomBitReg[0] = 0x35;
        PseudoRandomBitReg[1] = 0xa6;
        RedPTroopaOrigXPos[0] = 0x70;
        RedPTroopaCenterYPos[0] = 0xb0;
        YPlatformTopYPos[0] = 0x60;
        YPlatformCenterYPos[0] = 0xa0;
        char name[48];
        snprintf(name, sizeof(name), "movement-%u-%u-%u", id,
                 states[state_index], frames[frame_index]);
        emit(OP_MOVEMENT, 0, name);
      }
    }
  }

  prepare_actor();
  Enemy_ID[0] = A_RED_PARATROOPA;
  Enemy_Flag[0] = 1;
  Enemy_PageLoc[0] = 4;
  Enemy_X_Position[0] = 0xa0;
  Enemy_Y_HighPos[0] = 1;
  Enemy_Y_Position[0] = 0x38;
  RedPTroopaOrigXPos[0] = 0x38;
  RedPTroopaCenterYPos[0] = 0x68;
  FrameCounter = 0x84;
  emit(OP_MOVEMENT, 0, "red-paratroopa-initial-downward-acceleration");

  prepare_actor();
  Enemy_ID[0] = A_RED_PARATROOPA;
  Enemy_Flag[0] = 1;
  Enemy_PageLoc[0] = 4;
  Enemy_X_Position[0] = 0xa0;
  Enemy_Y_HighPos[0] = 1;
  Enemy_Y_Position[0] = 0x68;
  RedPTroopaOrigXPos[0] = 0x38;
  RedPTroopaCenterYPos[0] = 0x68;
  FrameCounter = 0x84;
  emit(OP_MOVEMENT, 0, "red-paratroopa-center-upward-acceleration");
}

static void fireball_vectors(void) {
  for (u8 status = 0; status < 3; status++) {
    for (u8 buttons = 0; buttons < 4; buttons++) {
      for (u8 counter = 0; counter < 3; counter++) {
        prepare_actor();
        PlayerStatus = status;
        A_B_Buttons = (buttons & 1) ? BUTTON_B : 0;
        PreviousA_B_Buttons = (buttons & 2) ? BUTTON_B : 0;
        FireballCounter = counter;
        PlayerAnimTimerSet = 4;
        Fireball_State[0] = counter == 2 ? 1 : 0;
        Fireball_State[1] = 0;
        char name[48];
        snprintf(name, sizeof(name), "fireball-bubble-%u-%u-%u", status,
                 buttons, counter);
        emit(OP_FIREBALL_BUBBLE, 0, name);
      }
    }
  }

  static const u8 states[] = {0, 1, 2, 0x80, 0x83};
  static const u8 facings[] = {0, 1, 2, 3};
  for (u8 slot = 0; slot < 2; slot++) {
    for (size_t state_index = 0; state_index < sizeof(states); state_index++) {
      for (size_t facing_index = 0; facing_index < sizeof(facings); facing_index++) {
        prepare_actor();
        Fireball_State[slot] = states[state_index];
        Fireball_PageLoc[slot] = 1;
        Fireball_X_Position[slot] = 0x88;
        Fireball_Y_HighPos[slot] = 1;
        Fireball_Y_Position[slot] = 0x70;
        Fireball_X_Speed[slot] = 0x40;
        Fireball_Y_Speed[slot] = 2;
        PlayerFacingDir = facings[facing_index];
        char name[48];
        snprintf(name, sizeof(name), "fireball-%u-%u-%u", slot,
                 states[state_index], facings[facing_index]);
        emit(OP_FIREBALL, slot, name);
      }
    }
  }

  prepare_actor();
  Fireball_State[0] = 1;
  Fireball_PageLoc[0] = 1;
  Fireball_X_Position[0] = 0x40;
  Fireball_Y_HighPos[0] = 1;
  Fireball_Y_Position[0] = 0x60;
  Fireball_X_Speed[0] = 0;
  Fireball_Y_Speed[0] = 0;
  Block_Buffers[5 * 16 + 4] = 0x51;
  emit(OP_FIREBALL, 0, "fireball-background-probe-eight-pixels-down");

  for (u8 slot = 0; slot < 3; slot++) {
    for (u8 active = 0; active < 2; active++) {
      for (u8 random = 0; random < 2; random++) {
        prepare_actor();
        Bubble_Y_Position[slot] = active ? 0x70 : SPRITE_Y_OFFSCREEN;
        Bubble_PageLoc[slot] = 1;
        Bubble_X_Position[slot] = 0x88;
        Bubble_YMF_Dummy[slot] = 0x20;
        PseudoRandomBitReg[slot + 1] = random;
        char name[48];
        snprintf(name, sizeof(name), "bubble-%u-%u-%u", slot, active, random);
        emit(OP_BUBBLE, slot, name);
      }
    }
  }
}

static void block_misc_vectors(void) {
  static const u8 block_states[] = {0, 1, 2, 0x11, 0x12};
  for (u8 slot = 0; slot < 2; slot++) {
    for (size_t state_index = 0; state_index < sizeof(block_states); state_index++) {
      prepare_actor();
      Block_State[slot] = block_states[state_index];
      Block_PageLoc[slot] = 1;
      Block_X_Position[slot] = 0x80;
      Block_Y_HighPos[slot] = 1;
      Block_Y_Position[slot] = 0x81;
      Block_Y_Speed[slot] = 0xfe;
      Block_Y_MoveForce[slot] = 0x20;
      Block_PageLoc[slot + 2] = 1;
      Block_X_Position[slot + 2] = 0x88;
      Block_Y_HighPos[slot + 2] = 1;
      Block_Y_Position[slot + 2] = 0x89;
      Block_Y_Speed[slot + 2] = 0xfc;
      char name[48];
      snprintf(name, sizeof(name), "block-%u-%u", slot, block_states[state_index]);
      emit(OP_BLOCK, slot, name);
    }
  }

  for (u8 slot = 0; slot < 2; slot++) {
    for (u8 busy = 0; busy < 2; busy++) {
      prepare_actor();
      Block_RepFlag[slot] = 1;
      Block_Orig_YPos[slot] = 0x80;
      Block_BBuf_Low[slot] = 8;
      Block_Metatile[slot] = 0x51;
      VRAM_Buffer1[0] = busy;
      char name[48];
      snprintf(name, sizeof(name), "block-update-%u-%u", slot, busy);
      emit(OP_BLOCK_UPDATE, slot, name);
    }
  }

  static const u8 misc_states[] = {1, 2, 0x2f, 0x80, 0x90, 0x92};
  for (u8 slot = 0; slot < 9; slot++) {
    for (size_t state_index = 0; state_index < sizeof(misc_states); state_index++) {
      prepare_actor();
      Misc_State[slot] = misc_states[state_index];
      Misc_PageLoc[slot] = 1;
      Misc_X_Position[slot] = 0x90;
      Misc_Y_HighPos[slot] = 1;
      Misc_Y_Position[slot] = 0x70;
      Misc_X_Speed[slot] = 0x10;
      Misc_Y_Speed[slot] = 0xfb;
      HammerEnemyOffset[slot] = 0;
      Enemy_Flag[0] = 1;
      Enemy_ID[0] = A_HAMMER_BRO;
      Enemy_PageLoc[0] = 1;
      Enemy_X_Position[0] = 0xa0;
      Enemy_Y_Position[0] = 0x80;
      Enemy_MovingDir[0] = 2;
      char name[48];
      snprintf(name, sizeof(name), "misc-%u-%u", slot, misc_states[state_index]);
      emit(OP_MISC, slot, name);
    }
  }
}

static void cannon_whirlpool_vectors(void) {
  for (u8 hard = 0; hard < 2; hard++) {
    for (u8 timer = 0; timer < 2; timer++) {
      prepare_actor();
      SecondaryHardMode = hard;
      PseudoRandomBitReg[1] = 0;
      Cannon_PageLoc[0] = 1;
      Cannon_X_Position[0] = 0xc0;
      Cannon_Y_Position[0] = 0x90;
      Cannon_Timer[0] = timer;
      char name[48];
      snprintf(name, sizeof(name), "cannon-%u-%u", hard, timer);
      emit(OP_CANNONS, 0, name);
    }
  }

  static const u8 bullet_states[] = {0, 1, 0x20};
  static const u8 bullet_positions[] = {0x40, 0xc0};
  for (size_t state_index = 0;
       state_index < sizeof(bullet_states);
       state_index++) {
    for (size_t position_index = 0;
         position_index < sizeof(bullet_positions);
         position_index++) {
      for (u8 paused = 0; paused < 2; paused++) {
        prepare_actor();
        Enemy_Flag[0] = 1;
        Enemy_ID[0] = A_BULLET_BILL_CANNON;
        Enemy_State[0] = bullet_states[state_index];
        Enemy_PageLoc[0] = 1;
        Enemy_X_Position[0] = bullet_positions[position_index];
        Enemy_Y_HighPos[0] = 1;
        Enemy_Y_Position[0] = 0x80;
        Enemy_X_Speed[0] = 0x18;
        Enemy_Y_Speed[0] = 2;
        Enemy_BoundBoxCtrl[0] = 9;
        TimerControl = paused;
        char name[64];
        snprintf(name, sizeof(name), "cannon-existing-%u-%u-%u",
                 bullet_states[state_index], bullet_positions[position_index],
                 paused);
        emit(OP_CANNONS, 0, name);
      }
    }
  }

  static const u8 diffs[] = {0, 8, 16, 24, 32};
  for (u8 frame = 0; frame < 2; frame++) {
    for (size_t diff_index = 0; diff_index < sizeof(diffs); diff_index++) {
      prepare_actor();
      AreaType = AREA_WATER;
      FrameCounter = frame;
      Whirlpool_PageLoc[0] = 1;
      Whirlpool_X_Position[0] = 0x70;
      Whirlpool_Length[0] = 0x20;
      Player_PageLoc = 1;
      Player_X_Position = 0x70 + diffs[diff_index];
      char name[48];
      snprintf(name, sizeof(name), "whirlpool-%u-%u", frame, diffs[diff_index]);
      emit(OP_WHIRLPOOLS, 0, name);
    }
  }
}

static void flagpole_platform_vectors(void) {
  for (u8 routine = GR_FLAGPOLESLIDE; routine <= GR_PLAYERENDLEVEL; routine++) {
    for (u8 position = 0; position < 3; position++) {
      prepare_actor();
      Enemy_ID[5] = A_FLAGPOLE;
      Enemy_Flag[5] = 1;
      Enemy_PageLoc[5] = 1;
      Enemy_X_Position[5] = 0xc0;
      Enemy_Y_HighPos[5] = 1;
      Enemy_Y_Position[5] = position == 0 ? 0x70 : (position == 1 ? 0xa9 : 0xaa);
      Player_State = PLAYERSTATE_CLIMBING;
      Player_Y_Position = position == 2 ? 0xa2 : 0x80;
      GameEngineSubroutine = routine;
      FlagpoleScore = position;
      FlagpoleFNum_Y_Pos = 0x90;
      FlagpoleFNum_YMFDummy = 0x40;
      char name[48];
      snprintf(name, sizeof(name), "flagpole-%u-%u", routine, position);
      emit(OP_FLAGPOLE, 5, name);
    }
  }

  for (u8 id = A_LARGEPLATFORM_BALANCE; id <= A_LARGEPLATFORM_RIGHT; id++) {
    for (u8 frame = 0; frame < 4; frame++) {
      prepare_actor();
      Enemy_ID[0] = id;
      Enemy_Flag[0] = 1;
      Enemy_PageLoc[0] = 1;
      Enemy_X_Position[0] = 0xa0;
      Enemy_Y_HighPos[0] = 1;
      Enemy_Y_Position[0] = 0x80;
      Enemy_State[0] = 0;
      Enemy_Y_Speed[0] = id == A_LARGEPLATFORM_LIFT1 ? 0xff : 0;
      Enemy_Y_MoveForce[0] = 0x10;
      YPlatformTopYPos[0] = 0x60;
      YPlatformCenterYPos[0] = 0xa0;
      FrameCounter = frame;
      char name[48];
      snprintf(name, sizeof(name), "platform-%u-%u", id, frame);
      emit(OP_PLATFORM, 0, name);
    }
  }

  prepare_actor();
  Enemy_ID[0] = A_LARGEPLATFORM_Y_MOVING;
  Enemy_Flag[0] = 1;
  Enemy_PageLoc[0] = 3;
  Enemy_X_Position[0] = 0x70;
  Enemy_Y_HighPos[0] = 1;
  Enemy_Y_Position[0] = 0x60;
  Enemy_Y_Speed[0] = 0;
  Enemy_Y_MoveForce[0] = 0;
  YPlatformTopYPos[0] = 0x60;
  YPlatformCenterYPos[0] = 0xa0;
  FrameCounter = 5;
  emit(OP_PLATFORM, 0, "platform-y-initial-downward-acceleration");

  prepare_actor();
  Enemy_ID[0] = A_LARGEPLATFORM_Y_MOVING;
  Enemy_Flag[0] = 1;
  Enemy_PageLoc[0] = 3;
  Enemy_X_Position[0] = 0x70;
  Enemy_Y_HighPos[0] = 1;
  Enemy_Y_Position[0] = 0xe3;
  Enemy_Y_Speed[0] = 0;
  Enemy_Y_MoveForce[0] = 0;
  YPlatformTopYPos[0] = 0x60;
  YPlatformCenterYPos[0] = 0xa0;
  FrameCounter = 5;
  emit(OP_PLATFORM, 0, "platform-y-center-upward-acceleration");
}

static void set_collision_box(u8 offset, u8 left, u8 top, u8 right, u8 bottom) {
  BoundingBoxCoords[offset + 0] = left;
  BoundingBoxCoords[offset + 1] = top;
  BoundingBoxCoords[offset + 2] = right;
  BoundingBoxCoords[offset + 3] = bottom;
}

static void collision_vectors(void) {
  static const u8 ids[] = {
    A_GREEN_KOOPA, A_BUZZY_BEETLE, A_HAMMER_BRO, A_GOOMBA,
    A_BLOOBER, A_BULLET_BILL, A_PODOBOO, A_PIRANHA_PLANT,
    A_LAKITU, A_SPINY, A_FLYING_CHEEPCHEEP, A_POWERUP,
    A_BULLET_BILL_CANNON,
  };
  static const u8 states[] = {0, 2, 4, 0x20};
  for (size_t id_index = 0; id_index < sizeof(ids); id_index++) {
    for (size_t state_index = 0; state_index < sizeof(states); state_index++) {
      for (u8 vertical = 0; vertical < 2; vertical++) {
        prepare_actor();
        Enemy_ID[0] = ids[id_index];
        Enemy_Flag[0] = 1;
        Enemy_State[0] = states[state_index];
        Enemy_Y_Position[0] = 0x90;
        Enemy_MovingDir[0] = 2;
        PowerUpType = POWERUP_MUSHROOM;
        PlayerStatus = PLAYERSTATUS_SMALL;
        Player_Y_Speed = vertical ? 2 : 0xfe;
        Player_Rel_XPos = 0x80;
        Enemy_Rel_XPos = 0x88;
        set_collision_box(0, 0x70, 0x70, 0x90, 0xa0);
        set_collision_box(4, 0x78, 0x78, 0x98, 0xa0);
        char name[64];
        snprintf(name, sizeof(name), "player-collision-%u-%u-%u", ids[id_index],
                 states[state_index], vertical);
        emit(OP_PLAYER_COLLISION, 0, name);
      }
    }
  }

  prepare_actor();
  Enemy_ID[0] = A_POWERUP;
  Enemy_Flag[0] = 1;
  Enemy_State[0] = 8;
  Enemy_Y_Position[0] = 0x51;
  PowerUpType = POWERUP_FIREFLOWER;
  PlayerStatus = PLAYERSTATUS_BIG;
  Player_Y_Speed = 0xfd;
  Player_Rel_XPos = 0x80;
  Enemy_Rel_XPos = 0x88;
  set_collision_box(0, 0x70, 0x60, 0x90, 0x90);
  set_collision_box(4, 0x78, 0x50, 0x98, 0x78);
  emit(OP_PLAYER_COLLISION, 0, "player-collision-fire-flower-big");

  for (size_t id_index = 0; id_index < sizeof(ids); id_index++) {
    prepare_actor();
    Fireball_State[0] = 1;
    set_collision_box(0x1c, 0x78, 0x78, 0x90, 0x90);
    Enemy_ID[0] = ids[id_index];
    Enemy_Flag[0] = 1;
    Enemy_Y_Position[0] = 0x80;
    Enemy_Rel_XPos = 0x88;
    set_collision_box(4, 0x78, 0x78, 0x90, 0x90);
    char name[48];
    snprintf(name, sizeof(name), "fireball-collision-%u", ids[id_index]);
    emit(OP_FIREBALL_COLLISION, 0, name);
  }

  prepare_actor();
  Fireball_State[0] = 1;
  set_collision_box(0x1c, 0x78, 0x68, 0x90, 0x80);
  Enemy_ID[0] = A_BOWSER;
  Enemy_Flag[0] = 1;
  Enemy_State[0] = 0;
  Enemy_PageLoc[0] = 1;
  Enemy_X_Position[0] = 0x88;
  Enemy_Y_HighPos[0] = 1;
  Enemy_Y_Position[0] = 0x68;
  BowserHitPoints = 1;
  set_collision_box(4, 0x78, 0x68, 0x98, 0x90);
  emit(OP_FIREBALL_COLLISION, 0, "fireball-collision-defeats-bowser");

  for (u8 state0 = 0; state0 < 8; state0 += 4) {
    for (u8 state1 = 0; state1 < 8; state1 += 4) {
      prepare_actor();
      FrameCounter = 1;
      Enemy_Flag[0] = 1;
      Enemy_Flag[1] = 1;
      Enemy_ID[0] = A_GREEN_KOOPA;
      Enemy_ID[1] = A_GOOMBA;
      Enemy_State[0] = state0;
      Enemy_State[1] = state1;
      Enemy_MovingDir[0] = 1;
      Enemy_MovingDir[1] = 2;
      set_collision_box(4, 0x70, 0x70, 0x90, 0xa0);
      set_collision_box(8, 0x78, 0x70, 0x98, 0xa0);
      char name[48];
      snprintf(name, sizeof(name), "enemy-collision-%u-%u", state0, state1);
      emit(OP_ENEMY_COLLISION, 1, name);
    }
  }

  static const u8 background_ids[] = {
    A_GREEN_KOOPA, A_RED_KOOPA, A_GOOMBA, A_PIRANHA_PLANT,
    A_GREEN_PARATROOPA, A_RED_PARATROOPA,
  };
  static const u8 background_states[] = {0, 1, 2, 4, 5, 0x20, 0x80};
  static const u8 background_y[] = {0x70, 0x80, 0xb0};
  for (size_t id_index = 0; id_index < sizeof(background_ids); id_index++) {
    for (size_t state_index = 0; state_index < sizeof(background_states);
         state_index++) {
      for (size_t y_index = 0; y_index < sizeof(background_y); y_index++) {
        prepare_actor();
        memset(Block_Buffers, 0x51, 0x1a0);
        Enemy_ID[0] = background_ids[id_index];
        Enemy_Flag[0] = 1;
        Enemy_State[0] = background_states[state_index];
        Enemy_PageLoc[0] = 1;
        Enemy_X_Position[0] = 0x88;
        Enemy_Y_HighPos[0] = 1;
        Enemy_Y_Position[0] = background_y[y_index];
        Enemy_X_Speed[0] = 0xf8;
        Enemy_Y_Speed[0] = 2;
        Enemy_MovingDir[0] = 2;
        char name[64];
        snprintf(name, sizeof(name), "enemy-background-%u-%u-%u",
                 background_ids[id_index], background_states[state_index],
                 background_y[y_index]);
        emit(OP_ENEMY_BACKGROUND, 0, name);
      }
    }
  }

  prepare_actor();
  memset(Block_Buffers, 0x51, 0x1a0);
  Enemy_ID[0] = A_POWERUP;
  Enemy_Flag[0] = 1;
  Enemy_State[0] = 0xc0;
  Enemy_PageLoc[0] = 1;
  Enemy_X_Position[0] = 0xa5;
  Enemy_Y_HighPos[0] = 1;
  Enemy_Y_Position[0] = 0x78;
  Enemy_X_Speed[0] = 0x10;
  Enemy_Y_Speed[0] = 1;
  Enemy_MovingDir[0] = 1;
  emit(OP_ENEMY_BACKGROUND, 0, "powerup-landing-after-fall");
}

static void floatey_vectors(void) {
  static const u8 controls[] = {0, 1, 5, 0xb};
  for (u8 slot = 0; slot < 6; slot++) {
    for (size_t index = 0; index < sizeof(controls); index++) {
      prepare_actor();
      FloateyNum_Control[slot] = controls[index];
      FloateyNum_Timer[slot] = index == 0 ? 0 : 2;
      FloateyNum_X_Pos[slot] = 0x80;
      FloateyNum_Y_Pos[slot] = 0x70;
      char name[48];
      snprintf(name, sizeof(name), "floatey-%u-%u", slot, controls[index]);
      emit(OP_FLOATEY, slot, name);
    }
  }
}

static void actor_core_vectors(void) {
  static const u8 states[] = {0, 0x20};
  static const u8 frames[] = {0, 1};

  for (u8 id = A_GREEN_KOOPA; id <= A_FLYING_CHEEPCHEEP; id++) {
    for (size_t state_index = 0; state_index < sizeof(states); state_index++) {
      for (size_t frame_index = 0; frame_index < sizeof(frames); frame_index++) {
        if (states[state_index] == 0x20
            && (id == A_GREEN_PARATROOPA_INPLACE
                || id == A_GREEN_PARATROOPA
                || id == A_RED_PARATROOPA
                || id == A_GREEN_PARATROOPA_HORIZONTAL
                || id == A_UNK_0x13)) {
          continue;
        }
        prepare_actor();
        Enemy_Flag[0] = 1;
        Enemy_ID[0] = id;
        Enemy_State[0] = states[state_index];
        Enemy_PageLoc[0] = 1;
        Enemy_X_Position[0] = 0x88;
        Enemy_Y_HighPos[0] = 1;
        Enemy_Y_Position[0] = 0x80;
        Enemy_X_Speed[0] = 0xf8;
        Enemy_Y_Speed[0] = 2;
        Enemy_X_MoveForce[0] = 0x40;
        Enemy_Y_MoveForce[0] = 0x20;
        Enemy_YMF_Dummy[0] = 0x80;
        Enemy_MovingDir[0] = 2;
        Enemy_BoundBoxCtrl[0] = 3;
        FrameCounter = frames[frame_index];
        char name[64];
        snprintf(name, sizeof(name), "actor-core-%u-%u-%u", id,
                 states[state_index], frames[frame_index]);
        emit(OP_ACTOR_CORE, 0, name);
      }
    }
  }

  prepare_actor();
  set_collision_box(0, 0xac, 0x6d, 0xb8, 0x85);
  Player_Y_Speed = 0xfd;
  Enemy_Flag[0] = 1;
  Enemy_ID[0] = A_LARGEPLATFORM_X_MOVING;
  Enemy_PageLoc[0] = 1;
  Enemy_X_Position[0] = 0x91;
  Enemy_Y_HighPos[0] = 1;
  Enemy_Y_Position[0] = 0x60;
  Enemy_BoundBoxCtrl[0] = 5;
  emit(OP_ACTOR_CORE, 0, "actor-core-platform-vertical-and-side-contact");

  prepare_actor();
  Enemy_Flag[0] = 1;
  Enemy_ID[0] = A_RED_KOOPA_GREENLIKE;
  Enemy_State[0] = 1;
  Enemy_PageLoc[0] = 1;
  Enemy_X_Position[0] = 0xbf;
  Enemy_Y_HighPos[0] = 2;
  Enemy_Y_Position[0] = 2;
  Enemy_X_Speed[0] = 8;
  Enemy_Y_Speed[0] = 3;
  Enemy_X_MoveForce[0] = 0x38;
  Enemy_Y_MoveForce[0] = 0x3d;
  Enemy_YMF_Dummy[0] = 0xdd;
  Enemy_MovingDir[0] = 1;
  Enemy_BoundBoxCtrl[0] = 3;
  emit(OP_ACTOR_CORE, 0, "actor-core-below-screen-render-erase");

  prepare_actor();
  Enemy_Flag[0] = 1;
  Enemy_ID[0] = A_BOWSER_FLAME;
  Enemy_State[0] = 0;
  Enemy_PageLoc[0] = 6;
  Enemy_X_Position[0] = 0x71;
  Enemy_Y_HighPos[0] = 1;
  Enemy_Y_Position[0] = 0x80;
  Enemy_X_MoveForce[0] = 0;
  Enemy_Y_MoveForce[0] = 0;
  BowserFlamePRandomOfs[0] = 1;
  Enemy_SprDataOffset[0] = 0x18;
  FrameCounter = 2;
  emit(OP_ACTOR_CORE, 0, "actor-core-bowser-flame-page-borrow");
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

  initialize_vectors();
  movement_vectors();
  fireball_vectors();
  block_misc_vectors();
  cannon_whirlpool_vectors();
  flagpole_platform_vectors();
  collision_vectors();
  floatey_vectors();
  actor_core_vectors();

  fclose(context.rom);
  return 0;
}
