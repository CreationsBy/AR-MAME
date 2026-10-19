#ifndef AR_CORE_H
#define AR_CORE_H
#include <stdint.h>
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef struct {
    const char *name, *title, *year, *manufacturer, *parent;
    unsigned buttons, players, four_way, analog, orientation;
} AMMachine;
/* A hardware object, never an invented gameplay actor. Native unrotated pixels. */
typedef struct {
    int id, x, y, width, height, sprite;
    uint32_t pixels[256]; /* RGBA bytes, zero alpha is transparent */
} AMVisual;
int am_machine(const char *name, AMMachine *result);
size_t am_visuals(AMVisual *out, size_t capacity);
#ifdef __cplusplus
}
#endif
#endif
