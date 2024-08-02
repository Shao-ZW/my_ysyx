#include <common.h>

#if defined(MULTIPROGRAM) && !defined(TIME_SHARING)
# define MULTIPROGRAM_YIELD() yield()
#else
# define MULTIPROGRAM_YIELD()
#endif

#define NAME(key) \
  [AM_KEY_##key] = #key,

static int screen_w = 0, screen_h = 0;

static const char *keyname[256] __attribute__((used)) = {
  [AM_KEY_NONE] = "NONE",
  AM_KEYS(NAME)
};

size_t serial_write(const void *buf, size_t offset, size_t len) {
  yield();
  for(const char *p = buf; p - (char*)buf < len; p++)
      putch(*p);
  return len;
}

size_t events_read(void *buf, size_t offset, size_t len) {
  yield();
  AM_INPUT_KEYBRD_T ev = io_read(AM_INPUT_KEYBRD);
  if (ev.keycode == AM_KEY_NONE) 
    return 0;
  return snprintf(buf, len, "%s %s\n", ev.keydown ? "kd" : "ku", keyname[ev.keycode]);
}

size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  AM_GPU_CONFIG_T config = io_read(AM_GPU_CONFIG);
  screen_h = config.height;
  screen_w = config.width;
  return snprintf((char *)buf, len, "WIDTH:%d\nHEIGHT:%d\n", screen_w, screen_h);
}

size_t fb_write(const void *buf, size_t offset, size_t len) {
  yield();
  offset /= sizeof(uint32_t);
  len /= sizeof(uint32_t);
  int x = offset % screen_w;
  int y = offset / screen_w;
  io_write(AM_GPU_FBDRAW, x, y, (void*)buf, len, 1, true);
  return len;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
}
