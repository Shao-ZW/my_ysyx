#include <NDL.h>
#include <sdl-timer.h>
#include <stdio.h>

#define TIMEROUND ((uint32_t)49 * 24 * 60 * 60 * 1000)

SDL_TimerID SDL_AddTimer(uint32_t interval, SDL_NewTimerCallback callback, void *param) {
  return NULL;
}

int SDL_RemoveTimer(SDL_TimerID id) {
  return 1;
}

uint32_t SDL_GetTicks() {
  uint32_t now_time = NDL_GetTicks() % TIMEROUND;
  return now_time;
}

void SDL_Delay(uint32_t ms) {
}
