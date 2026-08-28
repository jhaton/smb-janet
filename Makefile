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

.PHONY: reference-trace trace motion-vectors frame-spine-vectors test check smoke clean

reference-trace: build/trace-reference

trace: build/trace-reference test/fixtures/boot-walk.inputs local/smb.nes
	./build/trace-reference local/smb.nes test/fixtures/boot-walk.inputs build/boot-walk.trace 900

motion-vectors: build/motion-reference
	./build/motion-reference > build/motion-vectors.tsv

frame-spine-vectors: build/frame-spine-reference
	./build/frame-spine-reference > build/frame-spine-vectors.tsv

test: motion-vectors frame-spine-vectors
	jpm --local test

check: trace test
	jpm --local janet tools/compare-traces.janet build/boot-walk.trace build/boot-walk.trace

smoke:
	jpm --local janet src/main.janet --smoke 120

build/trace-reference: tools/trace-reference.c $(REFERENCE_OBJECTS) | build
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) $< $(REFERENCE_OBJECTS) -o $@

build/motion-reference: tools/motion-reference.c $(REFERENCE_OBJECTS) | build
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) -DSMB1_MODE $< $(REFERENCE_OBJECTS) -o $@

build/frame-spine-reference: tools/frame-spine-reference.c $(REFERENCE_OBJECTS) | build
	$(CC) $(CFLAGS) $(REFERENCE_CPPFLAGS) -DSMB1_MODE $< $(REFERENCE_OBJECTS) -o $@

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
