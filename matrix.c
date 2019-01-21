#include <stdlib.h>
#include "lua.h"
#include "lauxlib.h"

static int matrix_mult(lua_State *L) {
  double h1, h2, h3,
         l1, l2, l3,
         u1, u2, u3,
         r11, r12, r13,
         r21, r22, r23,
         r31, r32, r33;

  /* heading values */
  lua_rawgeti(L, 1, 1);
  lua_rawgeti(L, 1, 2);
  lua_rawgeti(L, 1, 3);

  /* left values */
  lua_rawgeti(L, 2, 1);
  lua_rawgeti(L, 2, 2);
  lua_rawgeti(L, 2, 3);

  /* up values */
  lua_rawgeti(L, 3, 1);
  lua_rawgeti(L, 3, 2);
  lua_rawgeti(L, 3, 3);

  /* r values */
  lua_rawgeti(L, 4, 1);
  lua_rawgeti(L, 4, 2);
  lua_rawgeti(L, 4, 3);
  lua_rawgeti(L, 4, 4);
  lua_rawgeti(L, 4, 5);
  lua_rawgeti(L, 4, 6);
  lua_rawgeti(L, 4, 7);
  lua_rawgeti(L, 4, 8);
  lua_rawgeti(L, 4, 9);

  /* Stack looks like this:
     1. h
     2. l
     3. u
     4. {r11, r12, r13, r21, . . . r33}
     5-7. h1-h3
     8-10. l1-3
     11-13. u1-3
     14-22. r11..r33
  */

  h1 = lua_tonumber(L, 5);
  h2 = lua_tonumber(L, 6);
  h3 = lua_tonumber(L, 7);
  l1 = lua_tonumber(L, 8);
  l2 = lua_tonumber(L, 9);
  l3 = lua_tonumber(L, 10);
  u1 = lua_tonumber(L, 11);
  u2 = lua_tonumber(L, 12);
  u3 = lua_tonumber(L, 13);
  r11 = lua_tonumber(L, 14);
  r12 = lua_tonumber(L, 15);
  r13 = lua_tonumber(L, 16);
  r21 = lua_tonumber(L, 17);
  r22 = lua_tonumber(L, 18);
  r23 = lua_tonumber(L, 19);
  r31 = lua_tonumber(L, 20);
  r32 = lua_tonumber(L, 21);
  r33 = lua_tonumber(L, 22);

  /* Push h */
  lua_pushnumber(L, h3 * r11 + l3 * r21 + u3 * r31);
  lua_pushnumber(L, h2 * r11 + l2 * r21 + u2 * r31);
  lua_pushnumber(L, h1 * r11 + l1 * r21 + u1 * r31);

  /* Push l */
  lua_pushnumber(L, h3 * r12 + l3 * r22 + u3 * r32);
  lua_pushnumber(L, h2 * r12 + l2 * r22 + u2 * r32);
  lua_pushnumber(L, h1 * r12 + l1 * r22 + u1 * r32);

  /* Push u */
  lua_pushnumber(L, h3 * r13 + l3 * r23 + u3 * r33);
  lua_pushnumber(L, h2 * r13 + l2 * r23 + u2 * r33);
  lua_pushnumber(L, h1 * r13 + l1 * r23 + u1 * r33);

  /* Read u */
  lua_rawseti(L, 3, 1);
  lua_rawseti(L, 3, 2);
  lua_rawseti(L, 3, 3);

  /* Read l */
  lua_rawseti(L, 2, 1);
  lua_rawseti(L, 2, 2);
  lua_rawseti(L, 2, 3);

  /* Read h */
  lua_rawseti(L, 1, 1);
  lua_rawseti(L, 1, 2);
  lua_rawseti(L, 1, 3);

  /* Return success */
  return 0;
}

static const luaL_reg module_funcs[] = {
  { "mult", matrix_mult },
  { NULL, NULL }
};

int luaopen_matrix(lua_State *L) {
  luaL_openlib(L, "matrix", module_funcs, 0);
  lua_pushliteral (L, "_COPYRIGHT");
  lua_pushliteral (L, "Copyright (C) 2014 Carlo Cabanilla <carlo.cabanilla@gmail.com>");
  lua_settable (L, -3);
  lua_pushliteral (L, "_DESCRIPTION");
  lua_pushliteral (L, "Matrix multiplication");
  lua_settable (L, -3);
  lua_pushliteral (L, "_NAME");
  lua_pushliteral (L, "Matrix");
  lua_settable (L, -3);
  lua_pushliteral (L, "_VERSION");
  lua_pushliteral (L, "0.1");
  lua_settable (L, -3);
  return 1;
}
