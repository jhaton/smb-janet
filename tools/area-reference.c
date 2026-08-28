#include "smbcore/ctx.h"
#include "smbcore/area.c"

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

static u8 world_area_end(u8 world) {
  return world == 7 ? 0x24 : WorldAddrOffsets[world + 1];
}

static void prepare_area(u8 world, u8 area) {
  memset(state.rammem, 0, 0x800);
  WorldNumber = world;
  AreaNumber = area;
  LoadAreaPointer();
  InitializeArea();
}

static void pointer_vectors(void) {
  for (u8 world = 0; world < 8; world++) {
    const u8 start = WorldAddrOffsets[world];
    const u8 end = world_area_end(world);
    for (u8 absolute = start; absolute < end; absolute++) {
      const u8 area = absolute - start;
      memset(state.rammem, 0, 0x800);
      WorldNumber = world;
      AreaNumber = area;
      LoadAreaPointer();
      GetAreaDataAddrs();
      printf("A\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\n",
             world, area, AreaPointer, AreaType,
             LOAD_16(EnemyData_addr_hi, EnemyData_addr_lo),
             LOAD_16(AreaData_addr_hi, AreaData_addr_lo),
             ForegroundScenery, BackgroundScenery, BackgroundColorCtrl,
             PlayerEntranceCtrl, GameTimerSetting, TerrainControl,
             AreaStyle, CloudTypeOverride);
    }
  }
}

static void decoder_vectors(void) {
  bool emitted[16][128] = {{false}};

  for (u8 world = 0; world < 8; world++) {
    const u8 start = WorldAddrOffsets[world];
    const u8 end = world_area_end(world);
    for (u8 absolute = start; absolute < end; absolute++) {
      const u8 area = absolute - start;
      prepare_area(world, area);
      for (u16 offset = 0; offset < 0x100; offset += 2) {
        const u8 data0 = AreaData[offset];
        if (data0 == 0xfd) break;
        const u8 data1 = AreaData[(u8)(offset + 1)] & 0x7f;
        const u8 nibble = data0 & 0x0f;
        if (nibble == 0x0d && (data1 & 0x40) == 0) continue;
        if (!emitted[nibble][data1]) {
          emitted[nibble][data1] = true;
          printf("D\t%u\t%u\t%u\n", nibble, data1,
                 decode_area_data_to_idx(nibble, data1));
        }
      }
    }
  }
}

static void column_vectors(void) {
  for (u8 world = 0; world < 8; world++) {
    const u8 start = WorldAddrOffsets[world];
    const u8 end = world_area_end(world);
    for (u8 absolute = start; absolute < end; absolute++) {
      const u8 area = absolute - start;
      prepare_area(world, area);

      for (u16 column = 0; column < 256; column++) {
        AreaParserCore();
        printf("C\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t",
               world, area, column, CurrentPageLoc, CurrentColumnPos,
               BlockBufferColumnPos, AreaDataOffset, AreaObjectPageLoc,
               AreaObjectPageSel, BackloadingFlag);
        print_hex(MetatileBuffer, 13);
        putchar('\t');
        for (u8 row = 0; row < 13; row++) {
          const u8 metatile = get_metatile(BlockBufferColumnPos, row);
          printf("%02x", metatile);
        }
        putchar('\t');
        print_hex(AreaObjectLength, 3);
        putchar('\t');
        print_hex(AreaObjOffsetBuffer, 3);
        putchar('\t');
        print_hex(Enemy_Flag, 7);
        putchar('\t');
        print_hex(Enemy_ID, 6);
        putchar('\t');
        print_hex(Enemy_PageLoc, 6);
        putchar('\t');
        print_hex(Enemy_X_Position, 6);
        putchar('\t');
        print_hex(Enemy_Y_Position, 6);
        putchar('\n');
        IncrementColumnPos();
      }
    }
  }
}

static void enemy_vectors(void) {
  for (u8 world = 0; world < 8; world++) {
    const u8 start = WorldAddrOffsets[world];
    const u8 end = world_area_end(world);
    for (u8 absolute = start; absolute < end; absolute++) {
      const u8 area = absolute - start;
      prepare_area(world, area);
      u16 sequence = 0;

      for (u8 page = 0; page < 32; page++) {
        for (u16 x = 0; x < 256; x += 16) {
          ScreenRight_PageLoc = page;
          ScreenRight_X_Pos = (u8)x;
          const u8 before = EnemyDataOffset;
          ProcLoopCommand(0);
          const u8 after = EnemyDataOffset;
          if (before != after || Enemy_Flag[0] != 0) {
            printf("E\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\n",
                   world, area, sequence++, page, (u8)x, before, after,
                   Enemy_ID[0], Enemy_Flag[0], Enemy_PageLoc[0],
                   Enemy_X_Position[0], Enemy_Y_Position[0]);
            Enemy_Flag[0] = 0;
            Enemy_ID[0] = 0;
          }
          if (EnemyData[EnemyDataOffset] == 0xff) {
            page = 32;
            break;
          }
        }
      }
    }
  }
}

static void loop_vectors(void) {
  for (u8 index = 0; index < 11; index++) {
    for (u8 correct = 0; correct < 2; correct++) {
      memset(state.rammem, 0, 0x800);
      WorldNumber = LoopCmdWorldNumber[index];
      CurrentPageLoc = LoopCmdPageNumber[index];
      CurrentColumnPos = 0;
      LoopCommand = 1;
      Player_Y_Position = LoopCmdYPosition[index] + (correct ? 0 : 1);
      Player_State = PLAYERSTATE_ONGROUND;
      Player_PageLoc = 0x20;
      ScreenLeft_PageLoc = 0x21;
      ScreenRight_PageLoc = 0x22;
      AreaObjectPageLoc = 0x23;
      EnemyDataOffset = 0x34;
      EnemyObjectPageLoc = 0x24;
      AreaDataOffset = 0x35;
      EnemyObjectPageSel = 1;
      AreaObjectPageSel = 1;
      EnemyFrenzyBuffer = A_BULLET_BILL_OR_CHEEPCHEEP_FRENZY;
      EnemyFrenzyQueue = A_GOOMBA;
      for (u8 slot = 0; slot < 5; slot++) {
        Enemy_Flag[slot] = 1;
        Enemy_ID[slot] = A_GOOMBA;
        Enemy_State[slot] = 2;
      }
      if (WorldNumber == 6) {
        MultiLoopPassCntr = 2;
        MultiLoopCorrectCntr = 2;
      }

      ProcLoopCommand(5);
      printf("L\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t",
             index, correct, Player_PageLoc, CurrentPageLoc,
             ScreenLeft_PageLoc, ScreenRight_PageLoc, AreaObjectPageLoc,
             EnemyDataOffset, EnemyObjectPageLoc, AreaDataOffset,
             EnemyObjectPageSel, AreaObjectPageSel, MultiLoopPassCntr,
             MultiLoopCorrectCntr, LoopCommand);
      print_hex(Enemy_Flag, 5);
      printf("\t%u\n", EnemyFrenzyBuffer);
    }
  }
}

static void scroll_vectors(void) {
  static const u8 pages[] = {0x00, 0x01, 0xff};
  static const u8 positions[] = {0x00, 0x01, 0xfe, 0xff};
  static const u8 amounts[] = {0x00, 0x01, 0x02, 0x0f, 0x10, 0xff};

  for (size_t p = 0; p < sizeof(pages); p++) {
    for (size_t x = 0; x < sizeof(positions); x++) {
      for (size_t a = 0; a < sizeof(amounts); a++) {
        memset(state.rammem, 0, 0x800);
        ScreenLeft_PageLoc = pages[p];
        ScreenLeft_X_Pos = positions[x];
        Mirror_PPU_CTRL_REG1 = 0xa6;
        ScrollThirtyTwo = 0xf8;
        ScrollScreen(amounts[a]);
        printf("S\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\n",
               pages[p], positions[x], amounts[a], ScrollAmount,
               ScrollThirtyTwo, ScreenLeft_PageLoc, ScreenLeft_X_Pos,
               ScreenRight_PageLoc, ScreenRight_X_Pos,
               Mirror_PPU_CTRL_REG1);
      }
    }
  }
}

static void scroll_handler_vector(const char *name, u8 player_scroll,
                                  u8 platform_scroll, u8 player_position,
                                  u8 lock, u8 collision_timer) {
  memset(state.rammem, 0, 0x800);
  ScreenLeft_PageLoc = 1;
  ScreenLeft_X_Pos = 0;
  GetScreenPosition();
  Player_PageLoc = 1;
  Player_X_Position = 0x80;
  Player_X_Scroll = player_scroll;
  Platform_X_Scroll = platform_scroll;
  Player_Pos_ForScroll = player_position;
  ScrollLock = lock;
  SideCollisionTimer = collision_timer;
  ScrollHandler();
  printf("H\t%s\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\n",
         name, Player_X_Scroll, Platform_X_Scroll, ScrollAmount,
         ScreenLeft_PageLoc, ScreenLeft_X_Pos, ScreenRight_PageLoc,
         ScreenRight_X_Pos, ScrollThirtyTwo);
}

static void scroll_handler_vectors(void) {
  scroll_handler_vector("locked", 2, 0, 0x70, 1, 0);
  scroll_handler_vector("left-threshold", 2, 0, 0x40, 0, 0);
  scroll_handler_vector("collision", 2, 0, 0x70, 0, 1);
  scroll_handler_vector("zero", 0, 0, 0x70, 0, 0);
  scroll_handler_vector("overflow", 0x81, 0, 0x70, 0, 0);
  scroll_handler_vector("one-mid", 1, 0, 0x60, 0, 0);
  scroll_handler_vector("two-mid", 2, 0, 0x60, 0, 0);
  scroll_handler_vector("two-right", 2, 0, 0x70, 0, 0);
  scroll_handler_vector("platform", 1, 2, 0x70, 0, 0);
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

  pointer_vectors();
  decoder_vectors();
  column_vectors();
  enemy_vectors();
  loop_vectors();
  scroll_vectors();
  scroll_handler_vectors();

  fclose(context.rom);
  return 0;
}
