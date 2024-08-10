TARGET=sunset.nes
CFG=config/nes.cfg
OBJS=src/main.o src/reset.o src/sprites.o
CA65=ca65
LD=ld65
LDFLAGS=-C $(CFG) 

src/%.o : src/%.s
	$(CA65) $<
$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@ 

.PHONY: clean
clean:
	rm -f $(TARGET) $(OBJS)