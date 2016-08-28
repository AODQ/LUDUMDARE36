module Game_Manager;
static import AOD;
import std.string;

static import Entity.Map;
Entity.Map.Tile[][][] map;
Entity.Map.Tile player;
int map_width, map_height;
enum Turn {
  Player, AI
};
Turn current_turn;

bool Valid_Position_Light(int x, int y) {
  if ( x <= 0 || y <= 0 ) return false;
  if ( x >= map.length || y >= map[0].length ) return false;
  if ( map[x][y].length == 0 ) return false;
  return true;
}

bool Valid_Position(int x, int y) {
  if ( !Valid_Position_Light(x, y) ) return false;
  foreach ( i; 0 .. map[x][y].length ) {
    if ( !map[x][y][i].R_Collideable()  ) return false;
  }
  return true;
}


void Add(T)(T x) {
  AOD.Add(x);
}

void Add(T)(T x) {
  /* static if ( is(T == Paddle  )) { paddle     = x; } */
  AOD.Add(x);
  if ( tile_x < 0 || tile_y < 0 ) {
    // not a tile map
  }
}

// only purpose is to add things after menu
class Gmanage : AOD.Entity {
public:
  override void Added_To_Realm() {
  }
}

void Remove(T)(T x) {
  import std.algorithm : remove;
  template Rem(string container) { const char[] Rem =
    "for ( int i = 0; i != " ~ container ~ ".length; ++ i )" ~
      "if ( " ~ container ~ "[i] is x ) {" ~
        container ~ " = remove("~container~", i);"~
        "break;" ~
      "}";
  }
  /* static if ( is(T == Upgrade )) { mixin(Rem!("upgrades" )); } */
  AOD.Remove(x);
}

void Restart_Game() {
  static import Data;
  AOD.Clean_Up(Data.Construct_New_Menu);
}

void Generate_Map() {
  // -------------- generate textual map ---------------------------------------
  int[][] tmap;
  int[] trooms_x, trooms_y, trooms_w, trooms_h;
  int twidth = cast(int)AOD.R_Rand(50, 100);
  int theight = cast(int)AOD.R_Rand(50, 100);
  tmap.length = twidth;
  for ( int i = 0; i != tmap.length; ++ i )
    tmap[i].length = theight;
  // return true if room valid loc
  bool Room_Intersects(int rx, int ry, int rw, int rh) {
    int lx = rx - rw, ly = ry - rh,
        hx = rx + rw, hy = ry + rh;
    // map boundaries
    if ( lx < 0 ) return false;
    if ( ly < 0 ) return false;
    if ( hx >= twidth ) return false;
    if ( hy >= theight ) return false;
    // r boundaries
    for ( int i = rx - rw; i != rx + rw; ++ i ) {
      for ( int j = ry - rh; j != ry + rh; ++ j ) {
        if ( tmap[i][j] != 0 ) return false;
      }
    }
    return true;
  }
  bool Generate_Horiz(int sx, int sy, int ex, bool ni) {
    if ( ex < sx ) {
      sx ^= ex;
      ex ^= sx;
      sx ^= ex;
    }
    /* // -- DEBUG START */
    /* import std.stdio : writeln; */
    /* import std.conv : to; */
    /* writeln("GENERATE HORIZ. SX: " ~ to!string(sx) ~ " SY: " ~ to!string(sy) ~ */
    /*                        " EX: " ~ to!string(ex)); */
    /* // -- DEBUG END */
    for ( int i = sx; i != ex; ++ i ) {
      if ( tmap[i][sy] == 0 ) {
        tmap[i][sy] = -1;
      }
      else if ( ni ) return false;
    }
    return true;
  }
  bool Generate_Verti(int sy, int sx, int ey, bool ni) {
    if ( ey < sy ) {
      sy ^= ey;
      ey ^= sy;
      sy ^= ey;
    }
    /* // -- DEBUG START */
    /* import std.stdio : writeln; */
    /* import std.conv : to; */
    /* writeln("GENERATE VERTI. SY: " ~ to!string(sy) ~ " SY: " ~ to!string(sx) ~ */
    /*                        " EY: " ~ to!string(ey)); */
    /* // -- DEBUG END */
    for ( int i = sy; i != ey+1; ++ i ) {
      if ( tmap[sx][i] == 0 )
        tmap[sx][i] = -1;
      else if ( ni ) return false;
    }
    return true;
  }
  void Generate_Path(int i, int y, bool ni) {
    if ( i == y ) return;
    int srx = trooms_x [ i ] ,
        sry = trooms_y [ i ] ,
        srw = trooms_w [ i ] ,
        srh = trooms_h [ i ] ,
        erx = trooms_x [ y ] ,
        ery = trooms_y [ y ] ,
        erw = trooms_w [ y ] ,
        erh = trooms_h [ y ] ;
    int ox = cast(int)AOD.R_Rand(srx - srw, srx + srw),
        oy = cast(int)AOD.R_Rand(sry - srh, sry + srh),
        fx = cast(int)AOD.R_Rand(erx - erw, erx + erw),
        fy = cast(int)AOD.R_Rand(ery - ery, ery + erh);
    if ( AOD.R_Rand(0, 2) > 1.0f ) { // horiz?
      Generate_Horiz(srx, sry, erx, ni);
      Generate_Verti(sry, erx, ery, ni);
      Generate_Horiz(srx, sry+1, erx, ni);
      Generate_Verti(sry, erx+1, ery, ni);
      if ( AOD.R_Rand(0, 50) > 40 ) {
        Generate_Horiz(srx, sry-1, erx, ni);
        Generate_Verti(sry, erx-1, ery, ni);
      }
    } else {
      Generate_Verti(sry, srx, ery, ni);
      Generate_Horiz(srx, ery, erx, ni);
      Generate_Verti(sry+1, srx+1, ery-1, ni);
      Generate_Horiz(srx+1, ery+1, erx-1, ni);
      if ( AOD.R_Rand(0, 50) > 40 ) {
        Generate_Verti(sry+1, srx-1, ery-1, ni);
        Generate_Horiz(srx+1, ery-1, erx-1, ni);
      }
    }
  }
  // returns false if not enough room
  bool Create_Room(int room_id) {
    int rx, ry, rw, rh;
    int attempt = 0;
    do {
      rx = cast(int)AOD.R_Rand(0, twidth);
      ry = cast(int)AOD.R_Rand(0, theight);
      rw = cast(int)AOD.R_Rand(2, 5);
      rh = cast(int)AOD.R_Rand(2, 5);
      ++ attempt;
    } while ( !Room_Intersects(rx, ry, rw, rh) && attempt < 20 );
    if ( attempt >= 20 ) // not enough room
      return false;
    for ( int i = rx - rw; i != rx + rw; ++ i ) {
      for ( int j = ry - rh; j != ry + rh; ++ j ) {
        tmap[i][j] = -1;
      }
    }
    trooms_x ~= rx; trooms_y ~= ry;
    trooms_h ~= rh; trooms_w ~= rw;
    return true;
  }
  // gen rooms
  int rm_amt = cast(int)AOD.R_Rand(15, 30);
  for ( int rms = 0; rms != rm_amt; ++ rms ) {
    if ( !Create_Room(rms) ) {
      break;
    }
    if ( rms != 0 )
      Generate_Path(rms-1, rms, false);
  }

  uint rand_paths = cast(int)AOD.R_Rand(2, 3);
  for ( int i = 0; i != rand_paths; ++ i ) {
    int x, y;
    do {
      x = cast(int)AOD.R_Rand(1, trooms_x.length);
      y = cast(int)AOD.R_Rand(1, trooms_x.length);
    } while ( x != y );
    Generate_Path(i, y, true);
  }
  for(int i=0; i<tmap.length; ++ i) {
    tmap[i][0]   = -1;
    tmap[i][$-1] = -1;
  }
  for(int i=0; i < tmap[0].length-1; ++i) {
    tmap[0][i]   = -1;
    tmap[$-1][i] = -1;
  }
  // -- DEBUG START
  import std.stdio;
  import std.conv : to;
  writeln("WIDTH: " ~ to!string(tmap.length) ~ " HEIGHT: "
                    ~ to!string(tmap[0].length) ~ " ROOMS: "
                    ~ to!string(trooms_x.length));
  foreach ( i; 0 .. tmap.length ) {
    foreach ( j; 0 .. tmap[i].length ) {
      int z = tmap[i][j];
      char c;
      if ( z == 0 )
        c = ' ';
      else if ( z < 0 ) {
        /* if ( z == -1 ) */
          /* c = 'V'; */
        /* else */
          /* c = 'H'; */
        c = '0';
      } else
        c = cast(char)('0' + z);
      /* if ( z > 100 ) { */
      /*   if ( z > 200 ) */
      /*     c = cast(char)(cast(char)(z - 201) + 'a'); */
      /*   else */
      /*     c = cast(char)(cast(char)(z - 101) + 'A'); */
      /* } else { */
      /*   c = cast(char)(z - '0'); */
      /* } */
      write(c);
    }
    writeln("");
  }
  // -- DEBUG END

  // place player
  import Entity.Player;
  {
    int rx = trooms_x [ 1 ] ,
        ry = trooms_y [ 1 ] ;
    player = new Player(rx, ry);
  }

  // ensure tmap has boundaries
  tmap = [][]  ~ tmap ~ [][];
  foreach ( i; 0 .. tmap.length )
    tmap[i] = [] ~ tmap[i] ~ [];
  // generate wall
  bool Valid_Wall_Token(int x, int y) {
    return tmap[x][y] != 0 && tmap[x][y] > -100;
  }
  // --- first passthrough
  foreach ( i; 0 .. tmap.length ) {
    foreach ( j; 0 .. tmap[i].length ) {
      /* if ( tmap[i][j] != 0 ) continue; // empty */
      /*  [0, 0] [1, 0] [2, 0]
          [0, 1]        [2, 1]
          [0, 2] [1, 2] [2, 2]

          0 == nothing, 1 == floor
      */
      if ( tmap[i][j] != 0 ) continue;
      int[3][3] surroundings = [[0, 0, 0], [0, 0, 0], [0, 0, 0]];
      for ( int ii = cast(int) i-1; ii != i+2; ++ ii ) {
        if ( ii == -1 || ii == tmap.length ) continue; // lim
        for ( int jj = cast(int) j-1; jj != j+2; ++ jj ) {
          if ( jj == -1 || jj == tmap[ii].length ) continue; // lim
          int ti = ii - cast(int) i+1,
              tj = jj - cast(int) j+1;
          if ( tmap[ii][jj] == -1 )
            surroundings[ti][tj] = 1;
        }
      }
      static import Data;
      alias M = Data.Image.MapGrid;
      /* // --- corners */
      auto s = surroundings;
      /* if ( !s[2][1] && !s[1][2] && s[2][2] ) tmap[i][j] = M.wall_ctl; */
      /* if ( !s[2][1] && !s[1][2] && s[2][0] ) tmap[i][j] = M.wall_ctr; */
      /* if ( !s[1][1] && !s[1][2] && s[0][2] ) tmap[i][j] = M.wall_cll; */
      /* if ( !s[1][0] && !s[1][1] && s[0][0] ) tmap[i][j] = M.wall_clr; */
      // --- | - walls
      if ( tmap[i][j] > -100 ) {
        if ( s[1][0] ) {
          if ( !s[0][1] && !s[2][1] )
            tmap[i][j] = M.wall_t;
        }
        if ( s[1][2] ) {
          if ( !s[0][1] && !s[2][1] )
            tmap[i][j] = M.brick;
        }
        if ( s[2][1] ) {
          if ( !s[1][0] && !s[1][2] )
            tmap[i][j] = M.wall_r;
        }
        if ( s[0][1] ) {
          if ( !(s[1][0] || s[1][2]) )
            tmap[i][j] = M.wall_l;
        }
        /* if ( s[2][2] && !s[2][1] && !s[1][2] ) tmap[i][j] = M.wall_ctl; */
        /* if ( s[0][2] && !s[0][1] && !s[1][2] ) tmap[i][j] = M.wall_ctr; */
        if ( s[0][0] && !s[0][1] && !s[1][0] ) tmap[i][j] = M.wall_clr;
        if ( s[2][0] && !s[1][0] && !s[2][1] ) tmap[i][j] = M.wall_cll;
        if ( s[0][1] && s[1][2] )              tmap[i][j] = M.brick_l;
        if ( s[0][1] && s[1][0] )              tmap[i][j] = M.wall_ptl;
        if ( s[2][1] && s[1][0] )              tmap[i][j] = M.wall_ptr;
        if ( s[2][1] && s[1][2] )              tmap[i][j] = M.brick_r;
      }
    }
  }
  // --- second passthrough
  foreach ( i; 0 .. tmap.length ) {
    foreach ( j; 0 .. tmap[i].length ) {
      /*  [0, 0] [1, 0] [2, 0]
          [0, 1]        [2, 1]
          [0, 2] [1, 2] [2, 2]

          0 == nothing, 1 == floor, otherwise M
      */
      int[3][3] surroundings = [[0, 0, 0], [0, 0, 0], [0, 0, 0]];
      for ( int ii = cast(int) i-1; ii != i+2; ++ ii ) {
        if ( ii == -1 || ii == tmap.length ) continue; // lim
        for ( int jj = cast(int) j-1; jj != j+2; ++ jj ) {
          if ( jj == -1 || jj == tmap[ii].length ) continue; // lim
          int ti = ii - cast(int) i+1,
              tj = cast(int) jj - cast(int) j+1;
          if ( tmap[ii][jj] == -1 )
            surroundings[ti][tj] = 1;
          if ( tmap[ii][jj] <= -100 )
            surroundings[ti][tj] = tmap[ii][jj];
        }
      }
      static import Data;
      alias M = Data.Image.MapGrid;
      auto s = surroundings;


      bool Is_Brick(int x) {
        return x == M.brick || x == M.brick_r || x == M.brick_l;
      }
      if ( tmap[i][j] != M.brick && tmap[i][j] != M.brick_r
                                 && tmap[i][j] != M.brick_l ) {
        if ( Is_Brick(s[0][1]) ) {
          if ( tmap[i][j] != -1 )
            tmap[i][j] = M.wall_l;
        }
        if ( Is_Brick(s[2][1])) {
          if ( tmap[i][j] != -1 )
            tmap[i][j] = M.wall_r;
        }
      }

      if ( tmap[i][j] == 0 && s[0][1] != -1 && s[1][0] != -1 &&
                              s[1][2] != -1 && s[2][1] != -1 ) {
        // corner inside of wall
        if ( s[2][2] == M.brick && s[1][2] != M.brick ) {
          tmap[i][j] = M.wall_ctl; continue;
        }
        if ( s[0][2] == M.brick && s[1][2] != M.brick ) {
          tmap[i][j] = M.wall_ctr; continue;
        }
        if ( s[2][0] == M.brick ) {
          tmap[i][j] = M.wall_cll; continue;
        }
        if ( s[0][0] == M.brick ) {
          tmap[i][j] = M.wall_clr; continue;
        }
      }
        // top of wall
        if ( tmap[i][j] == 0 && s[1][2] == M.brick ) {
          tmap[i][j] = M.wall_b; continue;
        }
    }
  }

  // ------- third pass through { halls }
  foreach ( i; 0 .. tmap.length ) {
    foreach ( j; 0 .. tmap[i].length ) {
      /*  [0, 0] [1, 0] [2, 0]
          [0, 1]        [2, 1]
          [0, 2] [1, 2] [2, 2]

          0 == nothing, 1 == floor, otherwise M
      */
      int[3][3] surroundings = [[0, 0, 0], [0, 0, 0], [0, 0, 0]];
      for ( int ii = cast(int) i-1; ii != i+2; ++ ii ) {
        if ( ii == -1 || ii == tmap.length ) continue; // lim
        for ( int jj = cast(int) j-1; jj != j+2; ++ jj ) {
          if ( jj == -1 || jj == tmap[ii].length ) continue; // lim
          int ti = ii - cast(int) i+1,
              tj = jj - cast(int) j+1;
          if ( tmap[ii][jj] == -1 )
            surroundings[ti][tj] = 1;
          if ( tmap[ii][jj] <= -100 )
            surroundings[ti][tj] = tmap[ii][jj];
        }
      }
      static import Data;
      alias M = Data.Image.MapGrid;
      auto s = surroundings;
      // corner outside of wall
      if ( s[1][2] == M.brick_l ) {
        tmap[i][j] = M.wall_pll;
        if ( s[1][0] == 1 )
          tmap[i][j] = M.hall_capl;
      }
      if ( s[1][2] == M.brick_r ) {
        tmap[i][j] = M.wall_plr;
        if ( s[1][0] == 1 )
          tmap[i][j] = M.hall_capr;
      }
      if ( tmap[i][j] < -101 ) {
        if ( (s[1][0] == 1 && s[1][2] == 1) ) {
          tmap[i][j] = M.hall_horiz;
          if ( s[0][1] == 1 )
            tmap[i][j] = M.hall_capl;
          if ( s[2][1] == 1 )
            tmap[i][j] = M.hall_capr;
        }
        if ( (s[0][1] == 1 && s[2][1] == 1) ){
          tmap[i][j] = M.hall_vert;
          if ( s[1][0] == 1 )
            tmap[i][j] = M.hall_capu;
          if ( s[1][2] == 1 )
            tmap[i][j] = M.hall_capd;
        }
      }
    }
  }


  // ------- fourth pass through { floors }
  foreach ( i; 0 .. tmap.length ) {
    foreach ( j; 0 .. tmap[i].length ) {
      /*  [0, 0] [1, 0] [2, 0]
          [0, 1]        [2, 1]
          [0, 2] [1, 2] [2, 2]

          0 == nothing, 1 == floor, otherwise M
      */
      int[3][3] surroundings = [[0, 0, 0], [0, 0, 0], [0, 0, 0]];
      for ( int ii = cast(int) i-1; ii != cast(int) i+2; ++ ii ) {
        if ( ii == -1 || ii == tmap.length ) continue; // lim
        for ( int jj = cast(int) j-1; jj != j+2; ++ jj ) {
          if ( jj == -1 || jj == tmap[ii].length ) continue; // lim
          int ti = ii - cast(int) i+1,
              tj = jj - cast(int) j+1;
          if ( tmap[ii][jj] == -1 )
            surroundings[ti][tj] = 1;
          if ( tmap[ii][jj] <= -100 )
            surroundings[ti][tj] = tmap[ii][jj];
        }
      }

      bool Is_Wall(int x) {
        return x <= -100 && x >= -150;
      }

      static import Data;
      alias M = Data.Image.MapGrid;
      auto s = surroundings;
      if ( tmap[i][j] == -1 ) {
        tmap[i][j] = M.floor;
        // -- uld
        if ( Is_Wall(s[0][1]) ) tmap[i][j] = M.floor_left;
        if ( Is_Wall(s[2][1]) ) tmap[i][j] = M.floor_right;
        if ( Is_Wall(s[1][0]) ) tmap[i][j] = M.floor_up;
        /* if ( Is_Wall(s[1][2]) ) tmap[i][j] = M.floor_down; */
        // -- vertic/horiz
        if ( Is_Wall(s[0][1]) && Is_Wall(s[2][1]) )
          tmap[i][j] = M.floor_vert;
        /* if ( Is_Wall(s[1][0]) && Is_Wall(s[1][2]) ) */
          /* tmap[i][j] = M.floor_horiz; */
        // -- corner
        if ( Is_Wall(s[0][0]) && Is_Wall(s[1][0]) && Is_Wall(s[0][1]) )
          tmap[i][j] = M.floor_tl;
        if ( Is_Wall(s[2][0]) && Is_Wall(s[1][0]) && Is_Wall(s[2][1]) )
          tmap[i][j] = M.floor_tr;
        /* if ( Is_Wall(s[0][2]) && Is_Wall(s[0][1]) && Is_Wall(s[1][2]) ) */
        /*   tmap[i][j] = M.floor_ll; */
        /* if ( Is_Wall(s[2][2]) && Is_Wall(s[1][2]) && Is_Wall(s[2][1]) ) */
        /*   tmap[i][j] = M.floor_lr; */
        // -- shadow corner
        if ( Is_Wall(s[0][0]) && !Is_Wall(s[1][0]) && !Is_Wall(s[0][1]) )
          tmap[i][j] = M.floor_slr;
        if ( Is_Wall(s[2][0]) && !Is_Wall(s[1][0]) && !Is_Wall(s[2][1]) )
          tmap[i][j] = M.floor_sll;
        /* if ( Is_Wall(s[0][2]) && !Is_Wall(s[0][1]) && !Is_Wall(s[1][2]) ) */
        /*   tmap[i][j] = M.floor_str; */
        /* if ( Is_Wall(s[2][2]) && !Is_Wall(s[1][2]) && !Is_Wall(s[2][1]) ) */
        /*   tmap[i][j] = M.floor_stl; */

        if ( Is_Wall(s[0][1]) && !Is_Wall(s[0][0]) )
          tmap[i][j] = M.floor_str;
        if ( Is_Wall(s[2][1]) && !Is_Wall(s[2][0]) )
          tmap[i][j] = M.floor_stl;

        /* if ( Is_Wall(s[0][0]) && Is_Wall(s[2][1]) ) */
        /*   tmap[i][j] = M.floor_splittl; */
        /* if ( Is_Wall(s[2][0]) && Is_Wall(s[0][1]) ) */
        /*   tmap[i][j] = M.floor_splittr; */
      }
    }
  }

  /* /1* // generate mobs *1/ */
  /* for ( int i = 0; i != trooms_x.length; ++ i ){ */
  /*   int amt_mobs = cast(int)AOD.R_Rand(0, trooms_w[i] + trooms_h[i]); */
  /*   int srx = trooms_x [ i   ] , */
  /*       sry = trooms_y [ i   ] , */
  /*       srw = trooms_w [ i   ] , */
  /*       srh = trooms_h [ i   ] ; */
  /*   foreach ( m; 0 .. amt_mobs ) { */
  /*     REGEN_MOB: */
  /*     int mx = cast(int)AOD.R_Rand(srx - srw, srx + srw), */
  /*         my = cast(int)AOD.R_Rand(sry - srh, sry + srh); */
  /*     if ( tmap[mx][my] > 100 ) { // generate 'super' mob */
  /*       if ( cast(int)AOD.R_Rand(0, trooms_w[i] + trooms_h[i]) < 3 ) { */
  /*         tmap[mx][my] += 100; */
  /*       } */
  /*     } else { */
  /*       tmap[mx][my] = cast(int)AOD.R_Rand(101, 126); */
  /*     } */
  /*   } */
  /* } */

  map_width = cast(int) tmap.length;
  map_height = cast(int) tmap[0].length;
  // -------------- generate graphix map ---------------------------------------
  import Entity.Map, Entity.Mob;
  map.length = tmap.length;
  foreach ( i; 0 .. tmap.length) {
    map[i].length = tmap[0].length;
    foreach ( j;0 .. tmap[0].length ) {
      if ( tmap[i][j] != 0 && i>0 && i<tmap.length-1
                           && j>0 && j<tmap[i].length-1) {
        if ( tmap[i][j] > 100 ) {
          /* auto m = tmap[i][j] - 101; */
          /* AOD.Add(new Floor(i, j)); */
          /* AOD.Add(new Mob(i, j, m)); */
        } else if ( tmap[i][j] <= -100 ) {
          if ( tmap[i][j] > -200 ) {
            if ( j != 0 && j != tmap.length && tmap[i][j-1] <= -200 &&
                 tmap[i][j+1] > -200 ) {
              AOD.Add(new Wall( cast(int) i, cast(int) j, tmap[i][j], true));
            } else
              AOD.Add(new Wall( cast(int) i, cast(int) j, tmap[i][j], false));
          } else
            AOD.Add(new Floor( cast(int) i, cast(int) j, tmap[i][j]));
        }
      }
    }
  }
  AOD.Add(player);
  static import Entity.UI;
  AOD.Add(new Entity.UI.HUD);
  // -----  props
  import Entity.Map : Prop;
  int charger = cast(int)AOD.R_Rand(0, 10);
  foreach ( i; 0 .. map.length ) { // Fifth pass through ( props -- moss )
    foreach ( j; 0 .. map[i].length ) {
      if ( map[i][j].length == 0 ) continue;
      if ( map[i][j][$-1].R_Tile_Type() == Entity.Map.Tile_Type.Floor ) {
        if ( AOD.R_Rand(0, 100) > 70 && charger < 10 ) ++ charger;
        if ( AOD.R_Rand(0, 100)*(1 + charger/10) > 180 ) {
          charger = 0;
          if ( AOD.R_Rand(0, 100) > 40 )
            AOD.Add(new Prop(cast(int)i, cast(int)j, Prop.Type.Debris ));
        }
      }
    }
  }

  int amt_foilage = cast(int)AOD.R_Rand(40, 60);
  for ( int i = 0; i != amt_foilage; ++ i ) {
    int x, y;
    do {
      x = cast(int)AOD.R_Rand(2, map.length-2);
      y = cast(int)AOD.R_Rand(3, map[0].length-2);
    } while ( map[x][y].length == 0 || map[x][y+1].length == 0 ||
              tmap[x][y] != Data.Image.MapGrid.brick );
    AOD.Add(new Prop(x, y,   Prop.Type.Moss));
  }


  int amt_trees = cast(int)AOD.R_Rand(20, 25);
  for ( int i = 0; i != amt_trees; ++ i ){
    int x, y;
    do {
      x = cast(int)AOD.R_Rand(2, map.length);
      y = cast(int)AOD.R_Rand(3, map[0].length);
    } while ( map[x][y].length == 0 ||
              map[x][y][0].R_Tile_Type() != Entity.Map.Tile_Type.Floor );
    AOD.Add(new Prop(x, y, Prop.Type.Tree_Bot));
    AOD.Add(new Prop(x, y-1, Prop.Type.Tree_Mid));
    AOD.Add(new Prop(x, y-2, Prop.Type.Tree_Top));
  }

  int amt_switches = cast(int)AOD.R_Rand(2, 5);
  for ( int i = 0; i != amt_switches; ++ i ) {
    int x, y;
    bool pass_once = false;
    DOAGAIN:
    do {
      x = cast(int)AOD.R_Rand(2, map.length);
      y = cast(int)AOD.R_Rand(3, map[0].length);
    } while ( map[x][y].length == 0 ||
              map[x][y][0].R_Tile_Type() != Entity.Map.Tile_Type.Floor );
    if ( pass_once )
      AOD.Add(new Prop(x, y, Prop.Type.Switch));
    else {
      AOD.Add(new Prop(x, y-1, Prop.Type.Block_Top));
      AOD.Add(new Prop(x, y, Prop.Type.Block_Bot));
      pass_once = true;
      goto DOAGAIN;
    }
  }

  { // --- door ---
    int x, y;
    do {
      x = cast(int)AOD.R_Rand(2, map.length);
      y = cast(int)AOD.R_Rand(3, map[0].length);
    } while ( map[x][y].length == 0 ||
              map[x][y][0].R_Tile_Type() != Entity.Map.Tile_Type.Floor );
    AOD.Add(new Prop(x, y, Entity.Map.Prop.Type.Closed_Door_Bot));
    AOD.Add(new Prop(x, y-1, Entity.Map.Prop.Type.Closed_Door_Top));
    writeln("Door x: " ~ to!string(x) ~ " y: " ~ to!string(y));
  }
}

void Update() {
  import std.math;
  auto px = player.R_Tile_Pos.x, py = player.R_Tile_Pos.y;
  int rlx = cast(int)AOD.Util.R_Max(0, px - 10),
      rhx = cast(int)AOD.Util.R_Min(Game_Manager.map.length, px + 10);
  int rly = cast(int)AOD.Util.R_Max(0, py - 10),
      rhy = cast(int)AOD.Util.R_Min(Game_Manager.map[0].length, py + 10);
  int cnt = 0;
  Entity.Map.Prop[] props_to_vis;
  for ( int i = rlx; i != rhx; ++ i)
  for ( int j = rly; j != rhy; ++ j ) {
    auto l = AOD.Util.Bresenham_Line(cast(int)px, cast(int)py, i, j);
    bool dark = false;
    foreach ( l_i; 1 .. l.length-1 ) {
      auto cx = cast(int)l[l_i].x, cy = cast(int)l[l_i].y;
      if ( Game_Manager.map[cx][cy].length == 0 ) {
        dark = true;
        break;
      }
      if ( Game_Manager.map[cx][cy][$-1].Blocks_Vision() ) {
        dark = true;
        break;
      }
    }
    if ( dark ) {
      if ( map[i][j].length > 0 )
        map[i][j][0].Set_Colour(0.5, 0.5, 0.5, 1.0);
      foreach ( k; 1 .. map[i][j].length )
        map[i][j][k].Set_Visible(false);
    } else {
      alias M = Entity.Map;
      if ( map[i][j].length > 0 ) {
        map[i][j][0].Set_Colour(1.0, 1.0, 1.0, 1.0);
        foreach ( k;  1 .. map[i][j].length ) {
          map[i][j][k].Set_Visible(true);
          if ( map[i][j][k].R_Tile_Type() == M.Tile_Type.Prop ) {
            auto c = cast(M.Prop)(map[i][j][k]);
            switch ( c.R_Prop_Type() ) {
              default: break;
              case M.Prop.Type.Block_Bot: case M.Prop.Type.Tree_Mid:
                props_to_vis ~= c.R_Top();
              break;
              case M.Prop.Type.Tree_Bot:
                auto d = c.R_Top();
                props_to_vis ~= d;
                props_to_vis ~= d.R_Top();
              break;
            }
          }
        }
      }
    }
  }
  foreach ( p; props_to_vis )
    if ( p !is null )
      p.Set_Visible(true);
  player.Set_Visible(true);
}
