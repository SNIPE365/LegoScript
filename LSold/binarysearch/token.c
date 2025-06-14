
Rule token[] = 
{//group //part id (LS) //part ID (LDRAW)          //description (LS)      //description (LDRAW)
	{1,     "26047",   "26047.dat\n"},             // part ID 26047      , part ID 26047
	{2,     "3024",    "3024.dat\n"},              // part ID 3024       , part ID 3024
	{3,     "32607",   "32607.dat\n"},             // part ID 32607      , part ID 32607
	{4,     "33291",   "33291.dat\n"},             // part ID 33291      , part ID 33291
	{5,     "3614a",   "3614a.dat\n"},             // part ID 3614a      , part ID 3614a
	{6,     "3661",    "3661.dat\n"},              // part ID 3661       , part ID 3661
	{7,     "4085a",   "4085a.dat\n"},             // part ID 4085a      , part ID 4085a
	{8,     "4085c",   "4085c.dat\n"},             // part ID 4085b      , part ID 4085b
	{9,     "4085b",   "4085b.dat\n"},             // part ID 4085c      , part ID 4085c
	{10,    "42688",   "42688.dat\n"},             // part ID 42688      , part ID 42688
	{11,    "49668",   "49668.dat\n"},             // part ID 49668      , part ID 49668
	{12,    "60897",   "60897.dat\n"},             // part ID 60897      , part ID 60897
	{13,    "6141",    "6141.dat\n"},              // part ID 6141       , part ID 6141
	{14,    "85861",   "85861.dat\n"},             // part ID 85861      , part ID 85861
	{15,    "61252",   "61252.dat\n"},             // part ID 61252      , part ID 61252
	{16,    "6019",    "6019.dat\n"},              // part ID 6019       , part ID 6019
	{17,    "14081a1", "14081a1.dat\n"},           // part ID 14081a1    , part ID 14081a1
	{18,    "14081b1", "14081b1.dat\n"},           // part ID 14081b1    , part ID 14081b1
	{19,    "78257",   "78257.dat\n"},             // part ID 78257      , part ID 78257
	{20,    "115070" , "115070.dat\n"},            // part ID 115070     , part ID 115070
	{1000,  "=",       ""},                        // equals             , null string
	{2000,  ";",       "\n"},                      // semicolon          , new line character
	{3000,  "P1",      ""},                        // plate 1            , null string
	{4000,  "P2",      ""},                        // plate 2            , null string
	{5000,  "s1",      "0  0 0"},                  // stud 1             , xpos  0  ypos  0  zpos  0
	{6000,  "c1",      "0 -8 0"},                  // clutch 1           , xpos  0  ypos -8  zpos  0
	{7000,  "s2",      "20 0 0"},                  // stud 2             , xpos  20 ypos  0  zpos  0
	{8000   "c2",      "20 -8 0"},                 // clutch 2           , xpos  20 ypos -8  zpos  0
	{9000,  "<2>",     "2"},                       // color 2 (green)    , color 2 (green)
	{10000, "<4>",     "4"},                       // color 4 (red)      , color 4 (red)
	{11000, "",        "1"},                       // null string        , line type
	{12000, "",        "0 0 0 1 0 0 0 1 0 0 0 1"}, // null string        , un-needed tokens for rotation, scaling, camera position, etc
	{13000, " ",       " "},                       // space character    , space character
	{14000, "\t",      "\t"},                      // tab character      , tab character
	{15000, "\n",      "\n"},                      // new line character , new line character
};