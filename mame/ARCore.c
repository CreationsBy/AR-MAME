/* Compiled inside the pinned core, with its real machine and input definitions. */
#include "driver.h"
#include "vidhrdw/generic.h"
#include "ARCore.h"
#include <string.h>

int am_machine(const char *name, AMMachine *out)
{
    int i;
    const struct InputPortTiny *port;
    const struct GameDriver *game = NULL;
    memset(out, 0, sizeof(*out));
    for (i = 0; drivers[i]; i++)
        if (!strcmp(drivers[i]->name, name)) { game = drivers[i]; break; }
    if (!game) return 0;
    out->name = game->name; out->title = game->description;
    out->year = game->year; out->manufacturer = game->manufacturer;
    out->parent = game->clone_of ? game->clone_of->name : "";
    out->orientation = game->flags & ORIENTATION_MASK;
    out->players = 1;
    for (port = game->input_ports; port && (port->type & 0xff) != IPT_END; port++) {
        unsigned type = port->type & 0xff;
        unsigned player = IP_GET_PLAYER(port) + 1;
        if (type >= IPT_BUTTON1 && type <= IPT_BUTTON10) {
            unsigned button = type - IPT_BUTTON1 + 1;
            if (player == 1 && button > out->buttons) out->buttons = button;
            if (player > out->players) out->players = player;
        }
        if (type >= IPT_JOYSTICK_UP && type <= IPT_JOYSTICKLEFT_RIGHT) {
            if (player > out->players) out->players = player;
            if (port->type & IPF_4WAY) out->four_way = 1;
        }
        if (type > IPT_ANALOG_START && type < IPT_ANALOG_END) out->analog = 1;
    }
    return 1;
}

static void decode(AMVisual *out, int gfx_index, int code, int color, int flipx, int flipy)
{
    const struct GfxElement *gfx = Machine->gfx[gfx_index];
    int x, y;
    if (!gfx || !gfx->total_elements || gfx->width > 16 || gfx->height > 16) return;
    out->width = gfx->width; out->height = gfx->height;
    code %= gfx->total_elements;
    for (y = 0; y < out->height; y++) for (x = 0; x < out->width; x++) {
        int px = flipx ? out->width - x - 1 : x;
        int py = flipy ? out->height - y - 1 : y;
        int offset, pen, index;
        UINT8 r, g, b;
        if (gfx->flags & GFX_SWAPXY) { int tmp = px; px = py; py = tmp; }
        offset = code * gfx->char_modulo + py * gfx->line_modulo;
        pen = (gfx->flags & GFX_PACKED) ?
            ((gfx->gfxdata[offset + px / 2] >> ((px & 1) * 4)) & 15) : gfx->gfxdata[offset + px];
        index = Machine->game_colortable[(color % gfx->total_colors) * gfx->color_granularity + pen];
        if (!index) continue;
        palette_get_color(index, &r, &g, &b);
        if (r || g || b) out->pixels[y * 16 + x] = r | (g << 8) | (b << 16) | 0xff000000u;
    }
}

size_t am_visuals(AMVisual *out, size_t capacity)
{
    size_t count = 0;
    int col, row, offs;
    const char *name;
    if (!Machine || !Machine->gamedrv || !videoram || !colorram) return 0;
    name = Machine->gamedrv->name;
    /* Explicitly scoped: other Pac-Man-family hardware has different banks/scrolling. */
    if (strcmp(name, "pacman") && strcmp(name, "puckman")) return 0;
    for (row = 0; row < 28; row++) for (col = 0; col < 36; col++) {
        int r = row + 2, c = col - 2;
        AMVisual *v;
        if (count >= capacity) return count;
        offs = (c & 0x20) ? r + ((c & 0x1f) << 5) : c + (r << 5);
        v = &out[count++]; memset(v, 0, sizeof(*v));
        v->id = row * 36 + col; v->x = col * 8; v->y = row * 8;
        decode(v, 0, videoram[offs], colorram[offs] & 0x1f, 0, 0);
    }
    if (!spriteram || !spriteram_2) return count;
    for (offs = (int)spriteram_size - 2; offs >= 0; offs -= 2) {
        AMVisual *v;
        if (count >= capacity) break;
        v = &out[count++]; memset(v, 0, sizeof(*v));
        v->id = 2000 + offs; v->sprite = 1;
        v->x = 272 - spriteram_2[offs + 1]; v->y = spriteram_2[offs] - 31 + (offs <= 4);
        decode(v, 1, spriteram[offs] >> 2, spriteram[offs + 1] & 0x1f,
               spriteram[offs] & 1, spriteram[offs] & 2);
    }
    return count;
}
