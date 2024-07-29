#include <NDL.h>
#include <SDL.h>
#include <string.h>

#define keyname(k) #k,
#define KEYNUM sizeof(keyname) / sizeof(keyname[0])

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

static uint8_t keystate[KEYNUM] = {0};

static inline uint8_t keytoscancode(char *buf) {
  for(int i = 0; i < KEYNUM; ++i) {
    if(strncmp(keyname[i], buf, strlen(buf) - 1) == 0 && strlen(buf) - 1 == strlen(keyname[i])) {
      return i;
    }
  }

  return -1;
}

int SDL_PushEvent(SDL_Event *ev) {
  return 0;
}

int SDL_PollEvent(SDL_Event *ev) {
  char buf[64];
  
  if(!NDL_PollEvent(buf, sizeof(buf)))
    return 0;
  
  if(strncmp(buf, "kd", 2) == 0) {
    
    ev->type = SDL_KEYDOWN;
    ev->key.keysym.sym = keytoscancode(buf + 3);
    keystate[ev->key.keysym.sym] = 1;
  }
  else if(strncmp(buf, "ku", 2) == 0) {
    ev->type = SDL_KEYUP;
    ev->key.keysym.sym = keytoscancode(buf + 3);
    keystate[ev->key.keysym.sym] = 0;
  }

  return 1;
}

int SDL_WaitEvent(SDL_Event *event) {
  char buf[64];
  
  while(!NDL_PollEvent(buf, sizeof(buf)))
    ;
  
  if(strncmp(buf, "kd", 2) == 0) {
    event->type = SDL_KEYDOWN;
    event->key.keysym.sym = keytoscancode(buf + 3);
    keystate[event->key.keysym.sym] = 1;
  }
  else if(strncmp(buf, "ku", 2) == 0) {
    event->type = SDL_KEYUP;
    event->key.keysym.sym = keytoscancode(buf + 3);
    keystate[event->key.keysym.sym] = 0;
  }

  return 0;
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  return 0;
}

uint8_t* SDL_GetKeyState(int *numkeys) {
  if (numkeys) *numkeys = KEYNUM;
  return keystate;
}
