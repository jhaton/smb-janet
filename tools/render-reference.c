#include "../reference/smb-vanilla-port/src/smbcore/smbcore.c"

#include <stdio.h>
#include <string.h>

struct render_capture {
  const char *scenario;
  size_t command_index;
};

static void capture_palette(void *userdata, const u8 *palette_indices) {
  const struct render_capture *capture = userdata;
  printf("P\t%s\t", capture->scenario);
  for (size_t i = 0; i < 0x20; i++) {
    printf("%02x", palette_indices[i]);
  }
  putchar('\n');
}

static void capture_tile(void *userdata, const struct SMB_tile tile) {
  struct render_capture *capture = userdata;
  if (tile.extra_type == TILE_TYPE_SPRITE) {
    printf("T\t%s\t%zu\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t-1\n",
           capture->scenario, capture->command_index, tile.tileidx,
           tile.paletteidx, tile.flip_horz, tile.flip_vert, tile.x, tile.y,
           tile.extra_type, tile.extra_spriteidx);
  } else {
    printf("T\t%s\t%zu\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n",
           capture->scenario, capture->command_index, tile.tileidx,
           tile.paletteidx, tile.flip_horz, tile.flip_vert, tile.x, tile.y,
           tile.extra_type, tile.extra_bg.x, tile.extra_bg.y);
  }
  capture->command_index++;
}

static void prepare_fixture(struct SMB_state *state, u8 sprite_data[0x100]) {
  memset(state, 0, sizeof(*state));

  for (size_t i = 0; i < 0x3c0; i++) {
    state->ppuram[0x2000 + i] = (u8)(i * 13 + 7);
    state->ppuram[0x2400 + i] = (u8)(i * 17 + 11);
  }
  for (size_t i = 0; i < 0x40; i++) {
    state->ppuram[0x23c0 + i] = (u8)(i * 29 + 3);
    state->ppuram[0x27c0 + i] = (u8)(i * 31 + 5);
  }
  for (size_t i = 0; i < 0x20; i++) {
    state->ppuram[0x3f00 + i] = (u8)((i * 3 + 2) & 0x3f);
  }

  for (size_t i = 0; i < 64; i++) {
    sprite_data[i * 4 + 0] = (u8)(i * 17 + 3);
    sprite_data[i * 4 + 1] = (u8)(i * 11 + 5);
    sprite_data[i * 4 + 2] = (u8)((i & 3)
                                        | ((i % 3 == 0) ? 0x20 : 0)
                                        | ((i & 4) ? 0x40 : 0)
                                        | ((i & 8) ? 0x80 : 0));
    sprite_data[i * 4 + 3] = (u8)(i * 19 + 9);
  }
}

static void emit_scenario(struct SMB_state *state, const char *name,
                          const bool screen_on, const u16 scroll_x) {
  u8 sprite_data[0x100];
  struct sprite sprites[64];
  struct render_capture capture = {name, 0};

  prepare_fixture(state, sprite_data);
  state->callbacks.userdata = &capture;
  state->callbacks.update_palette = capture_palette;
  state->callbacks.draw_tile = capture_tile;
  state->ppu.screen_on = screen_on;
  state->ppu.t.NN = (scroll_x / 256) & 1;
  state->ppu.t.XXXXX = (scroll_x % 256) / 8;
  state->ppu.x = scroll_x & 7;
  SMB_STATE = state;

  transfer_sprite_data(sprites, sprite_data);
  draw_graphics(sprites);
  printf("C\t%s\t%zu\n", name, capture.command_index);
}

static bool emit_chr_vectors(const char *rom_path) {
  u8 chr[0x2000];
  FILE *rom = fopen(rom_path, "rb");
  if (rom == NULL) {
    return false;
  }
  const bool loaded = fseek(rom, 0x8010, SEEK_SET) == 0
                   && fread(chr, 1, sizeof(chr), rom) == sizeof(chr);
  fclose(rom);
  if (!loaded) {
    return false;
  }

  for (size_t tile = 0; tile < 512; tile++) {
    printf("X\t%zu\t", tile);
    const u8 *planes = chr + tile * 0x10;
    for (size_t y = 0; y < 8; y++) {
      for (size_t x = 0; x < 8; x++) {
        const u8 low = (planes[y] >> (7 - x)) & 1;
        const u8 high = (planes[y + 8] >> (7 - x)) & 1;
        putchar('0' + (high << 1) + low);
      }
    }
    putchar('\n');
  }
  return true;
}

int main(int argc, char **argv) {
  static struct SMB_state state;
  if (argc != 2) {
    fprintf(stderr, "usage: %s ROM\n", argv[0]);
    return 2;
  }
  if (!emit_chr_vectors(argv[1])) {
    fprintf(stderr, "failed to load CHR from %s\n", argv[1]);
    return 1;
  }

  emit_scenario(&state, "screen-off", false, 0);
  emit_scenario(&state, "scroll-0", true, 0);
  emit_scenario(&state, "scroll-7", true, 7);
  emit_scenario(&state, "scroll-8", true, 8);
  emit_scenario(&state, "scroll-255", true, 255);
  emit_scenario(&state, "scroll-256", true, 256);
  emit_scenario(&state, "scroll-511", true, 511);
  return 0;
}
