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

# Janet dependencies live in jpm_tree/lib. `make deps` bootstraps spork's
# janet-pm into the tree, then installs project.janet's dependencies with it.
# janet-pm caches project.janet's dependency list in bundle/ and never refreshes
# it, and keeps an installed bundle even when its pin changes. So the shim is
# removed and tools/sync-deps.janet uninstalls stale bundles before installing.
JANET ?= janet
JANET_TREE := $(abspath jpm_tree/lib)
RUN_JANET := JANET_PATH=$(JANET_TREE) $(JANET)
SPORK_URL := https://github.com/janet-lang/spork.git
SPORK_TAG := 3918802d6b79848a3dba113b1fe2ee1a8f7b667b
SPORK_SRC := .cache/spork-$(SPORK_TAG)

.PHONY: deps reference-trace trace vertical-trace world1-trace world1-check motion-vectors frame-spine-vectors area-vectors player-vectors actor-vectors render-vectors test check smoke run clean

$(SPORK_SRC)/bin/janet-pm:
	rm -rf $(SPORK_SRC)
	git clone -q $(SPORK_URL) $(SPORK_SRC)
	git -C $(SPORK_SRC) checkout -q $(SPORK_TAG)

deps: $(SPORK_SRC)/bin/janet-pm
	mkdir -p $(JANET_TREE)
	$(RUN_JANET) -e '(unless (bundle/installed? "spork") (bundle/install "$(SPORK_SRC)"))'
	$(RUN_JANET) tools/sync-deps.janet
	rm -rf bundle
	$(RUN_JANET) $(SPORK_SRC)/bin/janet-pm deps

reference-trace: build/trace-reference

trace: build/trace-reference test/fixtures/boot-walk.inputs local/smb.nes
	./build/trace-reference local/smb.nes test/fixtures/boot-walk.inputs build/boot-walk.trace 900

vertical-trace: build/trace-reference test/fixtures/boot-walk.inputs local/smb.nes
	./build/trace-reference local/smb.nes test/fixtures/boot-walk.inputs build/boot-title-w1.trace 420
	$(RUN_JANET) tools/trace-janet.janet test/fixtures/boot-walk.inputs build/boot-title-w1-janet.trace 420

world1-trace: build/trace-reference test/fixtures/world1-warpless.inputs local/smb.nes
	./build/trace-reference local/smb.nes test/fixtures/world1-warpless.inputs build/world1-reference.trace 7915
	$(RUN_JANET) tools/trace-janet.janet test/fixtures/world1-warpless.inputs build/world1-janet.trace 7915

world1-check: world1-trace
	$(RUN_JANET) tools/compare-route-traces.janet build/world1-reference.trace build/world1-janet.trace

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
	@for t in test/unit/*.janet; do $(RUN_JANET) $$t || exit 1; done

check: trace vertical-trace test
	$(RUN_JANET) tools/compare-route-traces.janet build/boot-title-w1.trace build/boot-title-w1-janet.trace

smoke:
	$(RUN_JANET) src/main.janet --smoke 420

# Play: arrows are WASD, Z = A, X = B, Enter = Start, Right Shift = Select,
# R hot-reloads src/smb/live-step.janet. Needs local/smb.nes.
run:
	$(RUN_JANET) src/main.janet

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
