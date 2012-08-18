class LedMap extends Pixels {

  
  int[] strandSizes;

  LedMap(PApplet p) {
    super(p);
  
  }
 
  void initTotalControl()
  {
    strandSizes = new int[]
    {
      1250, //strand 0
      100, //strand 1
      100, //strand 2
      100, //strand 3
      100, //strand 4
      100, //strand 5
      100, //strand 6
      100, //strand 7
    };

    
    super.initTotalControl();
  }

  void mapStrandC(int sC) {
    xOffsetter = 0;
    yOffsetter = 16;
    
    ledSet(sC,0, 0, 0);
    ledSet(sC,4, 0, 4);
    ledSet(sC,5, 1, 4);
    ledSet(sC,9, 1, 0);
    ledSet(sC,10, 2, 0);
    ledSet(sC,16, 2, 6);
    ledSet(sC,17, 3, 6);
    ledSet(sC,22, 3, 1);
    ledSet(sC,23, 4, 1);
    ledSet(sC,30, 4, 8);
    ledSet(sC,31, 5, 8);
    ledSet(sC,38, 5, 1);
    ledSet(sC,39, 6, 1);
    ledSet(sC,48, 6, 10);
    ledSet(sC,49, 7, 10);
    ledSet(sC,58, 7, 1);
    ledSet(sC,59, 8, 1);
    ledSet(sC,70, 8, 12);
    ledSet(sC,71, 9, 12);
    ledSet(sC,82, 9, 1);
    ledSet(sC,83, 10, 1);
    ledSet(sC,95, 10, 13);
    ledSet(sC,96, 11, 13);
    ledSet(sC,108, 11, 1);
    ledSet(sC,109, 12, 1);
    ledSet(sC,122, 12, 14);
    ledSet(sC,123, 13, 14);
    ledSet(sC,137, 13, 0);
    ledSet(sC,138, 14, 0);
    ledSet(sC,153, 14, 15);
    ledSet(sC,154, 15, 15);
    ledSet(sC,169, 15, 0);
    ledSet(sC,170, 16, 0);
    ledSet(sC,187, 16, 17);
    ledSet(sC,188, 17, 17);
    ledSet(sC,205, 17, 0);
    ledSet(sC,206, 18, 0);
    ledSet(sC,224, 18, 18);
    ledSet(sC,225, 19, 18);
    ledSet(sC,241, 19, 2);
    ledMissing(sC,242);
    ledSet(sC,243, 19, 1);
    ledSet(sC,244, 19, 0);
    ledSet(sC,245, 20, 0);
    ledSet(sC,264, 20, 19);
    ledSet(sC,265, 21, 19);
    ledSet(sC,285, 21, -1);
    ledSet(sC,286, 22, -1);
    ledSet(sC,306, 22, 19);
    ledSet(sC,307, 23, 19);
    ledSet(sC,327, 23, -1);
    ledSet(sC,328, 24, -1);
    ledSet(sC,349, 24, 20);
    ledSet(sC,350, 25, 20);
    ledSet(sC,372, 25, -2);
    ledSet(sC,373, 26, -2);
    ledSet(sC,396, 26, 21);
    ledSet(sC,397, 27, 21);
    ledSet(sC,420, 27, -2);
    ledSet(sC,421, 28, -2);
    ledSet(sC,445, 28, 22);
    ledSet(sC,446, 29, 22);
    ledSet(sC,470, 29, -2);
    ledSet(sC,471, 30, -2);
    ledSet(sC,495, 30, 22);
    ledSet(sC,496, 31, 22);
    ledSet(sC,520, 31, -2);
    ledSet(sC,521, 32, -2);
    ledSet(sC,546, 32, 23);
    ledSet(sC,547, 33, 23);
    ledSet(sC,572, 33, -2);
    ledSet(sC,573, 34, -2);
    ledSet(sC,598, 34, 23);
    ledSet(sC,599, 35, 23);
    ledSet(sC,625, 35, -3);
    ledSet(sC,626, 36, -3);
    ledSet(sC,652, 36, 23);
    ledSet(sC,653, 37, 23);
    ledSet(sC,679, 37, -3);
    ledSet(sC,680, 38, -3);
    ledSet(sC,706, 38, 23);
    ledSet(sC,707, 39, 23);
    ledSet(sC,733, 39, -3);
    ledSet(sC,734, 40, -3);
    ledSet(sC,760, 40, 23);
    ledSet(sC,761, 41, 23);
    ledSet(sC,787, 41, -3);
    ledSet(sC,788, 42, -3);
    ledSet(sC,814, 42, 23);
    ledSet(sC,815, 43, 23);
    ledSet(sC,841, 43, -3);
    ledSet(sC,842, 44, -3);
    ledSet(sC,868, 44, 23);
    ledSet(sC,869, 45, 23);
    ledSet(sC,895, 45, -3);
    ledSet(sC,896, 46, -3);
    ledSet(sC,922, 46, 23);
    ledSet(sC,923, 47, 23);
    ledSet(sC,949, 47, -3);
    ledSet(sC,950, 48, -3);
    ledSet(sC,975, 48, 22);
    ledSet(sC,976, 49, 22);
    ledSet(sC,999, 49, -1);
    ledSet(sC,1000, 50, -1);
    ledSet(sC,1023, 50, 22);
    ledSet(sC,1024, 51, 22);
    ledSet(sC,1048, 51, -2);
    ledSet(sC,1049, 52, -2);
    ledSet(sC,1073, 52, 22);
    ledSet(sC,1074, 53, 22);
    ledSet(sC,1099, 53, -3);
    ledSet(sC,1100, 54, -3);
    ledSet(sC,1124, 54, 21);
    ledSet(sC,1125, 55, 21);
    ledSet(sC,1149, 55, -3);
    ledSet(sC,1150, 56, -3);
    ledSet(sC,1173, 56, 20);
    ledSet(sC,1174, 57, 20);
    ledSet(sC,1195, 57, -1);
    ledSet(sC,1196, 58, -1);
    ledSet(sC,1216, 58, 19);
    ledSet(sC,1217, 59, 19);
    ledSet(sC,1237, 59, -1);
    ledSet(sC,1238, 60, -1);
    ledSet(sC,1249, 60, 10);

  }
  
  
  void mapStrandA(int sA) {
    
    //897?
    
    ledMissing(sA, 0);
    ledSet(sA, 1, 0, 25);
    ledSet(sA, 10, 0, 16);
    ledSet(sA, 11, 1, 16);
    ledSet(sA, 20, 1, 25);

    if (true) {
      return;
    }
    
    ledSet(sA, 21, 2, 25);
    ledSet(sA, 33, 2, 13);
    ledSet(sA, 34, 3, 13);
    ledSet(sA, 46, 3, 25);
    ledSet(sA, 47, 4, 25);
    ledSet(sA, 65, 4, 7);
    ledSet(sA, 66, 5, 7);
    ledSet(sA, 84, 5, 25);
    ledSet(sA, 85, 6, 25);
    ledSet(sA, 102, 6, 8);
    ledSet(sA, 103, 7, 8);
    ledSet(sA, 120, 7, 25);
    ledSet(sA, 121, 8, 25);
    ledSet(sA, 129, 8, 17);
    ledSet(sA, 130, 9, 17);
    ledSet(sA, 138, 9, 25);
    ledSet(sA, 139, 10, 25);
    ledSet(sA, 148, 10, 16);
    ledSet(sA, 149, 11, 16);
    ledSet(sA, 158, 11, 25);
    ledSet(sA, 159, 12, 25);
    ledSet(sA, 169, 12, 15);
    ledSet(sA, 170, 13, 15);
    ledSet(sA, 180, 13, 25);
    ledSet(sA, 181, 14, 25);
    ledSet(sA, 193, 14, 13);
    ledSet(sA, 194, 15, 13);
    ledSet(sA, 198, 15, 17);
    ledMissing(sA, 199);
    ledSet(sA, 200, 15, 18);
    ledSet(sA, 206, 15, 24);
    ledSet(sA, 207, 16, 24);
    ledSet(sA, 219, 16, 12);
    ledSet(sA, 220, 17, 12);
    ledSet(sA, 232, 17, 24);
    ledSet(sA, 233, 18, 24);
    ledSet(sA, 247, 18, 10);
    ledSet(sA, 248, 19, 10);
    ledSet(sA, 262, 19, 24);
    ledSet(sA, 263, 20, 24);
    ledSet(sA, 277, 20, 10);
    ledSet(sA, 278, 21, 10);
    ledSet(sA, 292, 21, 24);
    ledSet(sA, 293, 22, 24);
    ledSet(sA, 307, 22, 10);
    ledSet(sA, 308, 23, 10);
    ledSet(sA, 321, 23, 23);
    ledSet(sA, 322, 24, 23);
    ledSet(sA, 335, 24, 10);
    ledSet(sA, 336, 25, 10);
    ledSet(sA, 349, 25, 23);
    ledSet(sA, 350, 26, 23);
    ledSet(sA, 363, 26, 10);
    ledSet(sA, 364, 27, 10);
    ledSet(sA, 377, 27, 23);
    ledSet(sA, 378, 28, 23);
    ledSet(sA, 389, 28, 12);
    ledSet(sA, 390, 29, 12);
    ledSet(sA, 400, 29, 22);
    ledSet(sA, 401, 30, 22);
    ledSet(sA, 410, 30, 13);
    ledSet(sA, 411, 31, 13);
    ledSet(sA, 420, 31, 22);
    ledSet(sA, 421, 32, 22);
    ledSet(sA, 432, 32, 11);
    ledSet(sA, 433, 33, 11);
    ledSet(sA, 444, 33, 22);
    ledSet(sA, 445, 34, 22);
    ledSet(sA, 457, 34, 10);
    ledSet(sA, 458, 35, 10);
    ledSet(sA, 470, 35, 22);
    ledSet(sA, 471, 36, 22);
    ledSet(sA, 483, 36, 10);
    ledSet(sA, 484, 37, 10);
    ledSet(sA, 496, 37, 22);
    ledSet(sA, 497, 38, 22);
    ledSet(sA, 509, 38, 10);
    ledSet(sA, 510, 39, 10);
    ledSet(sA, 522, 39, 22);
    ledSet(sA, 523, 40, 22);
    ledSet(sA, 532, 40, 13);
    ledSet(sA, 533, 41, 13);
    ledSet(sA, 542, 41, 22);
    ledSet(sA, 543, 42, 22);
    ledSet(sA, 552, 42, 13);
    ledSet(sA, 553, 43, 13);
    ledSet(sA, 562, 43, 22);
    ledSet(sA, 563, 44, 22);
    ledSet(sA, 571, 44, 14);
    ledSet(sA, 572, 45, 14);
    ledSet(sA, 580, 45, 22);
    ledSet(sA, 581, 46, 22);
    ledSet(sA, 589, 46, 14);
    ledSet(sA, 590, 47, 14);
    ledSet(sA, 598, 47, 22);
    ledSet(sA, 599, 48, 22);
    ledSet(sA, 608, 48, 13);
    ledSet(sA, 609, 49, 13);
    ledSet(sA, 620, 49, 24);
    ledSet(sA, 621, 50, 24);
    ledSet(sA, 645, 50, 0);
    ledSet(sA, 646, 51, 0);
    ledSet(sA, 669, 51, 23);
    ledSet(sA, 670, 52, 23);
    ledSet(sA, 692, 52, 1);
    ledSet(sA, 693, 53, 1);
    ledSet(sA, 714, 53, 22);
    ledSet(sA, 715, 54, 22);
    ledSet(sA, 734, 54, 3);
    ledSet(sA, 735, 55, 3);
    ledSet(sA, 746, 55, 14);
    ledMissing(sA, 747);
    ledSet(sA, 748, 55, 15);
    ledSet(sA, 754, 55, 21);
    ledSet(sA, 755, 56, 21);
    ledSet(sA, 772, 56, 4);
    ledSet(sA, 773, 57, 4);
    ledSet(sA, 791, 57, 22);
    ledSet(sA, 792, 58, 22);
    ledSet(sA, 809, 58, 5);
    ledSet(sA, 810, 59, 5);
    ledSet(sA, 829, 59, 24);
    ledSet(sA, 830, 60, 24);
    ledSet(sA, 848, 60, 6);
    ledSet(sA, 849, 61, 6);
    ledSet(sA, 866, 61, 23);
    ledSet(sA, 867, 62, 23);
    ledSet(sA, 882, 62, 8);
    ledSet(sA, 883, 63, 8);
    ledSet(sA, 896, 63, 21);
    
    
    //    int extraY = 20;
    
    //    ledMissing(sA,149);
    //    ledMissing(sA,148);
    //
    //    ledSet(sA,147,  0,0);
    //    ledSet(sA,133,  0,14);
    //
    //    ledMissing(sA,132);
    //
    //
    //    ledSet(sA,131,  1,14);
    //    ledSet(sA,117,  1,0);
    //    ledSet(sA,103,  2,0);
    //    ledSet(sA,89,   2,14);
    //    ledMissing(sA, 88);
    //    ledSet(sA,87,   3,14);
    //    ledSet(sA,77,   3,4);
    //    ledMissing(sA,76);
    //    ledSet(sA,75,   4,4);
    //    ledSet(sA,65,   4,14);
    //    ledMissing(sA,64);
    //    ledMissing(sA,53);
    //    ledSet(sA,63,   5,14);
    //    ledSet(sA,54,   5,5);
    //    ledSet(sA,52,   6,6);
    //    ledSet(sA,44,   6,14);
    //    ledMissing(sA,43);
    //
    //    ledSet(sA,42,   7,14);
    //    ledSet(sA,33,   7,5);
    //    ledMissing(sA,32);
    //    ledMissing(sA,31);
    //    ledMissing(sA,30);
    //    ledMissing(sA,29);
    //    ledMissing(sA,28);
    //    ledMissing(sA,27);
    //    ledMissing(sA,26);
    //    ledMissing(sA,25);
    //    ledMissing(sA,24);
    //    ledMissing(sA,23);
    //    ledMissing(sA,22);
    //    ledMissing(sA,21);
    //    ledMissing(sA,20);
    //    ledMissing(sA,19);
    //    ledMissing(sA,18);
    //    ledMissing(sA,17);
    //    ledMissing(sA,16);
    //    ledMissing(sA,15);
    //    ledMissing(sA,14);
    //    ledMissing(sA,13);
    //    ledMissing(sA,12);
    //    ledMissing(sA,11);
    //
    //    ledSet(sA,10,   8,4);
    //    ledSet(sA,0,    8,14);
  }
  
  
  void mapStrandB(int sB) {
    
    ledSet(sB,0,    0,4);
    
    ledSet(sB,4,    0,8);
    ledSet(sB,5,    1,8);
    
    ledSet(sB,9,    1,4);
    ledSet(sB,10,   2,4);

    if (true) {
      return;
    }
    
    ledSet(sB,16,   2,10);
    ledSet(sB,17,   3,10);
    
    ledSet(sB,22,   3,5);
    ledSet(sB,23,   4,5);
    
    ledSet(sB,30,   4,12);
    ledSet(sB,31,   5,12);
    
    ledSet(sB,38,   5,5);
    ledSet(sB,39,   6,5);
    
    ledSet(sB,48,   6,14);
    ledSet(sB,49,   7,14);
    
    ledSet(sB,58,   7,5);
    ledSet(sB,59,   8,5);
    
    ledSet(sB,70,   8,16);
    ledSet(sB,71,   9,16);
    
    ledSet(sB,82,   9,5);
    ledSet(sB,83,   10,5);
    
    ledSet(sB,95,   10,17);
    ledSet(sB,96,   11,17);
    
    ledSet(sB,108,  11,5);
    ledSet(sB,109,  12,5);
    
    ledSet(sB,122,  12,18);
    ledSet(sB,123,  13,18);
    
    ledSet(sB,137,  13,4);
    ledSet(sB,138,  14,4);
    
    ledSet(sB,153,  14,19);
    ledSet(sB,154,  15,19);
    
    ledSet(sB,169,  15,4);
    ledSet(sB,170,  16,4);
    
    ledSet(sB,187,  16,21);
    ledSet(sB,188,  17,21);
    
    ledSet(sB,205,  17,4);
    ledSet(sB,206,  18,4);
    
    ledSet(sB,224,  18,22);
    ledSet(sB,225,  19,22);
    
    ledMissing(sB, 242);
    
    ledSet(sB,244, 19,4);
    ledSet(sB,245, 20,4);
    
    ledSet(sB,264, 20,23);
    ledSet(sB,265, 21,23);
    //    ledSet(sB,0,   21,0);
    //    ledSet(sB,0,   22,0);
    //
    //    ledSet(sB,0,   22,0);
    //    ledSet(sB,0,   23,0);
    //
    //    ledSet(sB,0,   23,0);
    //    ledSet(sB,0,   24,0);
    //
    //    ledSet(sB,0,   24,0);
    //    ledSet(sB,0,   25,0);
    //
    //    ledSet(sB,0,   25,0);
    //    ledSet(sB,0,   26,0);
    //
    //    ledSet(sB,0,   26,0);
    //    ledSet(sB,0,   27,0);
    //
    //    ledSet(sB,0,   27,0);
    //    ledSet(sB,0,   28,0);
    //
    //    ledSet(sB,0,   28,0);
    //    ledSet(sB,0,   29,0);
    //
    //    ledSet(sB,0,   29,0);
    //    ledSet(sB,0,   30,0);
    //
    //    ledSet(sB,0,   0,0);
    //    ledSet(sB,0,   0,0);
    //
    //
  }
  
  
  
  
  int getStrandSize(int whichStrand) {
    println("strandSizes:" + strandSizes + " whichStrand:" + whichStrand);
    return strandSizes[whichStrand];
  }

  
  void mapAllLeds() {
    
    final int sA = 0;
    final int sB = 1;
    final int sC = 2;
    final int sD = 3;
    
//    mapStrandA(sC);
//    mapStrandB(sB);
    mapStrandC(sA);
    
    //    ledMapDump(sB,sB); //set which strands you want to dump
    
  }
  
  
  
}