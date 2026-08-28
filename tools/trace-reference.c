#include "smbcore/mario.h"

#include <errno.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TRACE_VERSION 1u
#define TRACE_RAM_SIZE 0x800u
#define TRACE_RECORD_SIZE (5u * 4u + TRACE_RAM_SIZE)
#define FNV_OFFSET 2166136261u
#define FNV_PRIME 16777619u

struct input_sequence {
  FILE *file;
  uint32_t next_frame;
  uint8_t next_value;
  uint8_t current_value;
  bool has_next;
};

struct trace_context {
  FILE *rom;
  struct input_sequence inputs;
  uint32_t tile_hash;
  uint32_t tile_count;
  uint32_t palette_hash;
};

static uint32_t hash_byte(uint32_t hash, uint8_t value) {
  return (hash ^ value) * FNV_PRIME;
}

static uint32_t hash_u32(uint32_t hash, uint32_t value) {
  for (unsigned shift = 0; shift < 32; shift += 8) {
    hash = hash_byte(hash, (uint8_t)(value >> shift));
  }
  return hash;
}

static bool write_u32_le(FILE *file, uint32_t value) {
  const uint8_t bytes[4] = {
    (uint8_t)value,
    (uint8_t)(value >> 8),
    (uint8_t)(value >> 16),
    (uint8_t)(value >> 24),
  };
  return fwrite(bytes, sizeof(bytes), 1, file) == 1;
}

static bool read_next_event(struct input_sequence *sequence) {
  char line[256];

  while (fgets(line, sizeof(line), sequence->file)) {
    char *cursor = line;
    while (*cursor == ' ' || *cursor == '\t') cursor++;
    if (*cursor == '\0' || *cursor == '\n' || *cursor == '#') continue;

    errno = 0;
    char *end = NULL;
    const unsigned long frame = strtoul(cursor, &end, 0);
    if (errno || end == cursor || *end != ':') {
      fprintf(stderr, "Invalid input event: %s", line);
      return false;
    }

    cursor = end + 1;
    errno = 0;
    const unsigned long value = strtoul(cursor, &end, 0);
    if (errno || end == cursor || value > 0xff) {
      fprintf(stderr, "Invalid input value: %s", line);
      return false;
    }
    while (*end == ' ' || *end == '\t' || *end == '\r') end++;
    if (*end != '\0' && *end != '\n' && *end != '#') {
      fprintf(stderr, "Unexpected input event suffix: %s", line);
      return false;
    }
    if (frame > UINT32_MAX) {
      fprintf(stderr, "Input frame is too large: %s", line);
      return false;
    }

    sequence->next_frame = (uint32_t)frame;
    sequence->next_value = (uint8_t)value;
    sequence->has_next = true;
    return true;
  }

  sequence->has_next = false;
  return !ferror(sequence->file);
}

static uint8_t input_at_frame(struct input_sequence *sequence, uint32_t frame) {
  while (sequence->has_next && sequence->next_frame <= frame) {
    sequence->current_value = sequence->next_value;
    if (!read_next_event(sequence)) exit(1);
  }
  return sequence->current_value;
}

static bool trace_read_rom(void *userdata, u8 *buffer, size_t size) {
  struct trace_context *context = userdata;
  return fread(buffer, size, 1, context->rom) == 1;
}

static bool trace_seek_rom(void *userdata, size_t offset) {
  struct trace_context *context = userdata;
  return fseek(context->rom, (long)offset, SEEK_SET) == 0;
}

static void trace_joy1(void *userdata, struct SMB_buttons *buttons) {
  struct trace_context *context = userdata;
  const uint8_t input = context->inputs.current_value;

  buttons->r = (input & 0x01) != 0;
  buttons->l = (input & 0x02) != 0;
  buttons->d = (input & 0x04) != 0;
  buttons->u = (input & 0x08) != 0;
  buttons->start = (input & 0x10) != 0;
  buttons->select = (input & 0x20) != 0;
  buttons->b = (input & 0x40) != 0;
  buttons->a = (input & 0x80) != 0;
}

static void trace_palette(void *userdata, const u8 *palette) {
  struct trace_context *context = userdata;
  uint32_t hash = FNV_OFFSET;
  for (size_t index = 0; index < 32; index++) {
    hash = hash_byte(hash, palette[index]);
  }
  context->palette_hash = hash;
}

static void trace_tile(void *userdata, const struct SMB_tile tile) {
  struct trace_context *context = userdata;
  uint32_t hash = context->tile_hash;

  hash = hash_u32(hash, (uint32_t)tile.tileidx);
  hash = hash_u32(hash, (uint32_t)tile.paletteidx);
  hash = hash_u32(hash, tile.flip_horz ? 1u : 0u);
  hash = hash_u32(hash, tile.flip_vert ? 1u : 0u);
  hash = hash_u32(hash, (uint32_t)tile.x);
  hash = hash_u32(hash, (uint32_t)tile.y);
  hash = hash_u32(hash, tile.extra_type);
  if (tile.extra_type == TILE_TYPE_BG) {
    hash = hash_u32(hash, tile.extra_bg.x);
    hash = hash_u32(hash, tile.extra_bg.y);
  } else {
    hash = hash_u32(hash, tile.extra_spriteidx);
  }

  context->tile_hash = hash;
  context->tile_count++;
}

static bool write_header(FILE *output, uint32_t frame_count) {
  return fwrite("SMBTRC1", 8, 1, output) == 1 &&
         write_u32_le(output, TRACE_VERSION) &&
         write_u32_le(output, frame_count) &&
         write_u32_le(output, TRACE_RAM_SIZE) &&
         write_u32_le(output, TRACE_RECORD_SIZE);
}

static bool write_record(FILE *output, uint32_t frame, uint8_t input,
                         const struct trace_context *context,
                         struct SMB_state *state) {
  return write_u32_le(output, frame) &&
         write_u32_le(output, input) &&
         write_u32_le(output, context->tile_hash) &&
         write_u32_le(output, context->tile_count) &&
         write_u32_le(output, context->palette_hash) &&
         fwrite(SMB_ram(state), TRACE_RAM_SIZE, 1, output) == 1;
}

static void usage(const char *program) {
  fprintf(stderr,
          "Usage: %s ROM INPUT_EVENTS OUTPUT_TRACE FRAME_COUNT\n"
          "Input events use frame:value with SMB button bits "
          "A B Select Start Up Down Left Right.\n",
          program);
}

int main(int argc, char **argv) {
  if (argc != 5) {
    usage(argv[0]);
    return 2;
  }

  errno = 0;
  char *frame_end = NULL;
  const unsigned long parsed_frames = strtoul(argv[4], &frame_end, 0);
  if (errno || frame_end == argv[4] || *frame_end != '\0' ||
      parsed_frames == 0 || parsed_frames > UINT32_MAX) {
    fprintf(stderr, "Invalid frame count: %s\n", argv[4]);
    return 2;
  }
  const uint32_t frame_count = (uint32_t)parsed_frames;

  struct trace_context context = {0};
  context.rom = fopen(argv[1], "rb");
  context.inputs.file = fopen(argv[2], "r");
  FILE *output = fopen(argv[3], "wb");
  if (!context.rom || !context.inputs.file || !output) {
    fprintf(stderr, "Could not open trace input/output files\n");
    return 1;
  }
  if (!read_next_event(&context.inputs)) return 1;

  struct SMB_state *state = malloc(SMB_state_size());
  if (!state) {
    fprintf(stderr, "Could not allocate SMB state\n");
    return 1;
  }

  const struct SMB_callbacks callbacks = {
    .userdata = &context,
    .read_rom_bytes = trace_read_rom,
    .seek_rom = trace_seek_rom,
    .update_palette = trace_palette,
    .draw_tile = trace_tile,
    .joy1 = trace_joy1,
  };

  if (!SMB_state_init(state, &callbacks)) {
    fprintf(stderr, "Reference rejected ROM: %s\n", argv[1]);
    return 1;
  }
  SMB_start_on_level(state, 1, 1);

  if (!write_header(output, frame_count)) {
    fprintf(stderr, "Could not write trace header\n");
    return 1;
  }

  for (uint32_t frame = 0; frame < frame_count; frame++) {
    const uint8_t input = input_at_frame(&context.inputs, frame);
    context.tile_hash = FNV_OFFSET;
    context.tile_count = 0;
    context.palette_hash = FNV_OFFSET;

    SMB_tick(state);
    if (!write_record(output, frame, input, &context, state)) {
      fprintf(stderr, "Could not write frame %" PRIu32 "\n", frame);
      return 1;
    }
  }

  const bool success = fclose(output) == 0;
  fclose(context.inputs.file);
  fclose(context.rom);
  free(state);

  if (!success) {
    fprintf(stderr, "Could not finalize trace\n");
    return 1;
  }

  printf("Wrote %" PRIu32 " frames to %s\n", frame_count, argv[3]);
  return 0;
}
