CC ?= cc
CFLAGS ?= -O2 -g
CFLAGS += -std=c11 -Wall -Wextra

REFERENCE := reference/smb-vanilla-port
REFERENCE_CORE := $(REFERENCE)/src/smbcore
REFERENCE_CPPFLAGS := -I$(REFERENCE)/src -I$(REFERENCE_CORE) -DPRINT_WARNINGS_AND_ERRORS
BUILD_REFERENCE := build/reference

SMB1_NAMES := common common_sound area smb1only
SMB2J_NAMES := common common_sound area smb2jonly
SMB1_OBJECTS := $(addprefix $(BUILD_REFERENCE)/smb1-,$(addsuffix .o,$(SMB1_NAMES)))
SMB2J_OBJECTS := $(addprefix $(BUILD_REFERENCE)/smb2j-,$(addsuffix .o,$(SMB2J_NAMES)))
REFERENCE_OBJECTS := $(SMB1_OBJECTS) $(SMB2J_OBJECTS) $(BUILD_REFERENCE)/smbcore.o
AREA_REFERENCE_OBJECTS := $(filter-out $(BUILD_REFERENCE)/smb1-area.o,$(REFERENCE_OBJECTS))
RENDER_REFERENCE_OBJECTS := $(filter-out $(BUILD_REFERENCE)/smbcore.o,$(REFERENCE_OBJECTS))

.PHONY: reference-trace trace vertical-trace world1-trace world1-check motion-vectors frame-spine-vectors area-vectors player-vectors actor-vectors render-vectors test check smoke clean

reference-trace: build/trace-reference

trace: build/trace-reference test/fixtures/boot-walk.inputs local/smb.nes
	./build/trace-reference local/smb.nes test/fixtures/boot-walk.inputs build/boot-walk.trace 900

vertical-trace: build/trace-reference test/fixtures/boot-walk.inputs local/smb.nes
	./build/trace-reference local/smb.nes test/fixtures/boot-walk.inputs build/boot-title-w1.trace 420
	jpm --local janet tools/trace-janet.janet test/fixtures/boot-walk.inputs build/boot-title-w1-janet.trace 420

world1-trace: build/trace-reference test/fixtures/world1-warpless.inputs local/smb.nes
	./build/trace-reference local/smb.nes test/fixtures/world1-warpless.inputs build/world1-reference.trace 7915
	jpm --local janet tools/trace-janet.janet test/fixtures/world1-warpless.inputs build/world1-janet.trace 7915

world1-check: world1-trace
	jpm --local janet tools/compare-route-traces.janet build/world1-reference.trace build/world1-janet.trace

motion-vectors: build/motion-reference
	./build/motion-reference > build/motion-vectors.tsv

frame-spine-vectors: build/frame-spine-reference
	./build/frame-spine-reference > build/frame-spine-vectors.tsv

area-vectors: build/area-reference local/smb.nes
	./build/area-reference local/smb.nes > build/area-vectors.tsv

player-vectors: build/player-reference local/smb.nes
	./build/player-reference local/smb.nes > build/player-vectors.tsv

actor-vectors: build/actor-reference local/smb.nes
	./build/actor-reference local/smb.nes > build/actor-vectors.tsv

render-vectors: build/render-reference local/smb.nes
	./build/render-reference local/smb.nes > build/render-vectors.tsv

test: motion-vectors frame-spine-vectors area-vectors player-vectors actor-vectors render-vectors
	jpm --local test

check: trace vertical-trace test
	jpm --local janet tools/compare-route-traces.janet build/boot-title-w1.trace build/boot-title-w1-janet.trace

smoke:
	jpm --local janet src/main.janet --smoke 420

build/trace-reference: tools/trace-reference.c $(REFERENCE_OBJECTS) | build
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) $< $(REFERENCE_OBJECTS) -o $@

build/motion-reference: tools/motion-reference.c $(REFERENCE_OBJECTS) | build
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) -DSMB1_MODE $< $(REFERENCE_OBJECTS) -o $@

build/frame-spine-reference: tools/frame-spine-reference.c $(REFERENCE_OBJECTS) | build
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) -DSMB1_MODE $< $(REFERENCE_OBJECTS) -o $@

build/area-reference: tools/area-reference.c $(AREA_REFERENCE_OBJECTS) | build
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) -DSMB1_MODE $< $(AREA_REFERENCE_OBJECTS) -o $@

build/player-reference: tools/player-reference.c $(REFERENCE_OBJECTS) | build
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) -DSMB1_MODE $< $(REFERENCE_OBJECTS) -o $@

build/actor-reference: tools/actor-reference.c $(REFERENCE_OBJECTS) | build
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) -DSMB1_MODE $< $(REFERENCE_OBJECTS) -o $@

build/render-reference: tools/render-reference.c $(RENDER_REFERENCE_OBJECTS) | build
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) $< $(RENDER_REFERENCE_OBJECTS) -o $@

$(BUILD_REFERENCE)/smb1-%.o: $(REFERENCE_CORE)/%.c | $(BUILD_REFERENCE)
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) -DSMB1_MODE -c $< -o $@

$(BUILD_REFERENCE)/smb2j-%.o: $(REFERENCE_CORE)/%.c | $(BUILD_REFERENCE)
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) -DSMB2J_MODE -c $< -o $@

$(BUILD_REFERENCE)/smbcore.o: $(REFERENCE_CORE)/smbcore.c | $(BUILD_REFERENCE)
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) -c $< -o $@

build $(BUILD_REFERENCE):
	mkdir -p $@

clean:
	rm -rf build
