class LedMap extends Pixels {
  
  
  int[] strandSizes;
  
  LedMap(PApplet p) {
    super(p);
    strandSizes = new int[]
    {
      1001, //mapUpperHalfTopDriverSide
      400, //mapDriverSideLowerPart2
      850, //mapDriverSideLowerPart1
      997, //mapLowerHalfTopDriverSide
      775, //mapPassengerSideUpperTop1
      849, //mapPassengerSideLower1
      250, //mapPassengerSideLower2
      973, //mapLowerHalfTopPassengerSide
    };
  }
  
  void setup() {
    super.setup();
  }
  
  
  void mapDriverSideLowerPart1(int panel) {
    assert (panel < getNumStrands());
    
    //highest y is 28
    
    xOffsetter = 21;
    yOffsetter = 32;
    ordinalOffsetter = 0;
    
    ledSet(panel,0, 0, 0);
    ledSet(panel,4, 0, 4);
    ledSet(panel,5, 1, 4);
    ledSet(panel,9, 1, 0);
    ledSet(panel,10, 2, 0);
    ledSet(panel,16, 2, 6);
    ledSet(panel,17, 3, 6);
    ledSet(panel,22, 3, 1);
    ledSet(panel,23, 4, 1);
    ledSet(panel,30, 4, 8);
    ledSet(panel,31, 5, 8);
    ledSet(panel,38, 5, 1);
    ledSet(panel,39, 6, 1);
    ledSet(panel,48, 6, 10);
    ledSet(panel,49, 7, 10);
    ledSet(panel,58, 7, 1);
    ledSet(panel,59, 8, 1);
    ledSet(panel,70, 8, 12);
    ledSet(panel,71, 9, 12);
    ledSet(panel,82, 9, 1);
    ledSet(panel,83, 10, 1);
    ledSet(panel,95, 10, 13);
    ledSet(panel,96, 11, 13);
    ledSet(panel,108, 11, 1);
    ledSet(panel,109, 12, 1);
    ledSet(panel,122, 12, 14);
    ledSet(panel,123, 13, 14);
    ledSet(panel,137, 13, 0);
    ledSet(panel,138, 14, 0);
    ledSet(panel,153, 14, 15);
    ledSet(panel,154, 15, 15);
    ledSet(panel,169, 15, 0);
    ledSet(panel,170, 16, 0);
    ledSet(panel,187, 16, 17);
    ledSet(panel,188, 17, 17);
    ledSet(panel,205, 17, 0);
    ledSet(panel,206, 18, 0);
    ledSet(panel,224, 18, 18);
    ledSet(panel,225, 19, 18);
    ledSet(panel,241, 19, 2);
    ledMissing(panel,242);
    ledSet(panel,243, 19, 1);
    ledSet(panel,244, 19, 0);
    ledSet(panel,245, 20, 0);
    ledSet(panel,264, 20, 19);
    ledSet(panel,265, 21, 19);
    ledSet(panel,285, 21, -1);
    ledSet(panel,286, 22, -1);
    ledSet(panel,306, 22, 19);
    ledSet(panel,307, 23, 19);
    ledSet(panel,327, 23, -1);
    ledSet(panel,328, 24, -1);
    ledSet(panel,349, 24, 20);
    ledSet(panel,350, 25, 20);
    ledSet(panel,372, 25, -2);
    ledSet(panel,373, 26, -2);
    ledSet(panel,396, 26, 21);
    ledSet(panel,397, 27, 21);
    ledSet(panel,420, 27, -2);
    ledSet(panel,421, 28, -2);
    ledSet(panel,445, 28, 22);
    ledSet(panel,446, 29, 22);
    ledSet(panel,470, 29, -2);
    ledSet(panel,471, 30, -2);
    ledSet(panel,495, 30, 22);
    ledSet(panel,496, 31, 22);
    ledSet(panel,520, 31, -2);
    ledSet(panel,521, 32, -2);
    ledSet(panel,546, 32, 23);
    ledSet(panel,547, 33, 23);
    ledSet(panel,572, 33, -2);
    ledSet(panel,573, 34, -2);
    ledSet(panel,598, 34, 23);
    ledSet(panel,599, 35, 23);
    ledSet(panel,625, 35, -3);
    ledSet(panel,626, 36, -3);
    ledSet(panel,652, 36, 23);
    ledSet(panel,653, 37, 23);
    ledSet(panel,679, 37, -3);
    ledSet(panel,680, 38, -3);
    ledSet(panel,706, 38, 23);
    ledSet(panel,707, 39, 23);
    ledSet(panel,733, 39, -3);
    ledSet(panel,734, 40, -3);
    ledSet(panel,760, 40, 23);
    ledSet(panel,761, 41, 23);
    ledSet(panel,787, 41, -3);
    ledSet(panel,788, 42, -3);
    ledSet(panel,814, 42, 23);
    ledSet(panel,815, 43, 23);
    ledSet(panel,841, 43, -3);
    ledSet(panel,842, 44, -3);
    ledSet(panel,849, 44, 4);
  }
  
  void mapDriverSideLowerPart2(int panel) {
    assert (panel < getNumStrands());
    
    xOffsetter = 21;
    yOffsetter = 32;
    ordinalOffsetter = 0;
    
    ledSet(panel,0, 44, 5);
    ledSet(panel,18, 44, 23);
    ledSet(panel,19, 45, 23);
    ledSet(panel,45, 45, -3);
    ledSet(panel,46, 46, -3);
    ledSet(panel,72, 46, 23);
    ledSet(panel,73, 47, 23);
    ledSet(panel,99, 47, -3);
    ledSet(panel,100, 48, -3);
    ledSet(panel,125, 48, 22);
    ledSet(panel,126, 49, 22);
    ledSet(panel,149, 49, -1);
    ledSet(panel,150, 50, -1);
    ledSet(panel,173, 50, 22);
    ledSet(panel,174, 51, 22);
    ledSet(panel,198, 51, -2);
    ledSet(panel,199, 52, -2);
    ledSet(panel,223, 52, 22);
    ledSet(panel,224, 53, 22);
    ledSet(panel,249, 53, -3);
    ledSet(panel,250, 54, -3);
    ledSet(panel,274, 54, 21);
    ledSet(panel,275, 55, 21);
    ledSet(panel,299, 55, -3);
    ledSet(panel,300, 56, -3);
    ledSet(panel,323, 56, 20);
    ledSet(panel,324, 57, 20);
    ledSet(panel,345, 57, -1);
    ledSet(panel,346, 58, -1);
    ledSet(panel,366, 58, 19);
    ledSet(panel,367, 59, 19);
    ledSet(panel,387, 59, -1);
    ledSet(panel,388, 60, -1);
    ledSet(panel,399, 60, 10);
  }
  
  void mapDriverSideUpper(int panel) {
    //800 pixels
    assert (panel < getNumStrands());
 
    //OBSOLETE?????
    
    xOffsetter = 0;
    yOffsetter = 10;
    ordinalOffsetter = -1;
    
    ledSet(panel,1, 5, 12);
    ledSet(panel,5, 5, 16);
    ledSet(panel,6, 6, 16);
    ledSet(panel,15, 6, 7);
    ledSet(panel,16, 7, 7);
    ledSet(panel,25, 7, 16);
    ledSet(panel,26, 8, 16);
    ledSet(panel,36, 8, 6);
    ledSet(panel,37, 9, 6);
    ledSet(panel,47, 9, 16);
    ledSet(panel,48, 10, 16);
    ledSet(panel,59, 10, 5);
    ledSet(panel,60, 11, 5);
    ledSet(panel,71, 11, 16);
    ledSet(panel,72, 12, 16);
    ledSet(panel,85, 12, 3);
    ledSet(panel,86, 13, 3);
    ledSet(panel,97, 13, 14);
    ledSet(panel,98, 14, 14);
    ledSet(panel,110, 14, 2);
    ledSet(panel,111, 15, 2);
    ledSet(panel,123, 15, 14);
    ledSet(panel,124, 16, 14);
    ledSet(panel,138, 16, 0);
    ledSet(panel,139, 17, 0);
    ledSet(panel,153, 17, 14);
    ledSet(panel,154, 18, 14);
    ledSet(panel,168, 18, 0);
    ledSet(panel,169, 19, 0);
    ledSet(panel,183, 19, 14);
    ledSet(panel,184, 20, 14);
    ledSet(panel,198, 20, 0);
    ledSet(panel,199, 21, 0);
    ledSet(panel,213, 21, 14);
    ledSet(panel,214, 22, 14);
    ledSet(panel,228, 22, 0);
    ledSet(panel,229, 23, 0);
    ledSet(panel,242, 23, 13);
    ledSet(panel,243, 24, 13);
    ledSet(panel,255, 24, 1);
    ledSet(panel,256, 25, 1);
    ledSet(panel,267, 25, 12);
    ledSet(panel,268, 26, 12);
    ledSet(panel,279, 26, 1);
    ledSet(panel,280, 27, 1);
    ledSet(panel,291, 27, 12);
    ledSet(panel,292, 28, 12);
    ledSet(panel,301, 28, 3);
    ledSet(panel,302, 29, 3);
    ledSet(panel,311, 29, 12);
    ledSet(panel,312, 30, 12);
    ledSet(panel,322, 30, 2);
    ledSet(panel,323, 31, 2);
    ledSet(panel,333, 31, 12);
    ledSet(panel,334, 32, 12);
    ledSet(panel,346, 32, 0);
    ledSet(panel,347, 33, 0);
    ledSet(panel,359, 33, 12);
    ledSet(panel,360, 34, 12);
    ledSet(panel,371, 34, 1);
    ledSet(panel,372, 35, 1);
    ledSet(panel,383, 35, 12);
    ledSet(panel,384, 36, 12);
    ledSet(panel,394, 36, 2);
    ledSet(panel,395, 37, 2);
    ledSet(panel,405, 37, 12);
    ledSet(panel,406, 38, 12);
    ledSet(panel,415, 38, 3);
    ledSet(panel,416, 39, 3);
    ledSet(panel,425, 39, 12);
    ledSet(panel,426, 40, 12);
    ledSet(panel,435, 40, 3);
    ledSet(panel,436, 41, 3);
    ledSet(panel,445, 41, 12);
    ledSet(panel,446, 42, 12);
    ledSet(panel,454, 42, 4);
    ledSet(panel,455, 43, 4);
    ledSet(panel,463, 43, 12);
    ledSet(panel,464, 44, 12);
    ledSet(panel,472, 44, 4);
    ledSet(panel,473, 45, 4);
    ledSet(panel,481, 45, 12);
    ledSet(panel,482, 46, 12);
    ledSet(panel,490, 46, 4);
    ledSet(panel,491, 47, 4);
    ledSet(panel,499, 47, 12);
    ledSet(panel,500, 48, 12);
    ledSet(panel,509, 48, 3);
    ledSet(panel,510, 49, 3);
    ledSet(panel,521, 49, 14);
    ledSet(panel,522, 50, 14);
    ledSet(panel,546, 50, -10);
    ledSet(panel,547, 51, -10);
    ledSet(panel,570, 51, 13);
    ledSet(panel,571, 52, 13);
    ledSet(panel,593, 52, -9);
    ledSet(panel,594, 53, -9);
    ledSet(panel,615, 53, 12);
    ledSet(panel,616, 54, 12);
    ledSet(panel,636, 54, -8);
    ledSet(panel,637, 55, -8);
    ledSet(panel,657, 55, 12);
    ledSet(panel,658, 56, 12);
    ledSet(panel,676, 56, -6);
    ledSet(panel,677, 57, -6);
    ledSet(panel,695, 57, 12);
    ledSet(panel,696, 58, 12);
    ledSet(panel,713, 58, -5);
    ledSet(panel,714, 59, -5);
    ledSet(panel,733, 59, 14);
    ledSet(panel,734, 60, 14);
    ledSet(panel,752, 60, -4);
    ledSet(panel,753, 61, -4);
    ledSet(panel,770, 61, 13);
    ledSet(panel,771, 62, 13);
    ledSet(panel,786, 62, -2);
    ledSet(panel,787, 63, -2);
    ledSet(panel,800, 63, 11);
  }
  
  void mapPassengerSideLower1(int panel) {
    assert (panel < getNumStrands());
    //    Passenger Side Part 1:
    xOffsetter = 20;
    yOffsetter = 32;
    ordinalOffsetter = 0;
    
    ledMissing(panel,0);
    ledSet(panel,1, 0, 0);
    ledSet(panel,6, 0, 5);
    ledSet(panel,7, 1, 5);
    ledSet(panel,12, 1, 0);
    ledSet(panel,13, 2, 0);
    ledSet(panel,20, 2, 7);
    ledSet(panel,21, 3, 7);
    ledSet(panel,28, 3, 0);
    ledSet(panel,29, 4, 0);
    ledSet(panel,38, 4, 9);
    ledSet(panel,39, 5, 9);
    ledSet(panel,48, 5, 0);
    ledSet(panel,49, 6, 0);
    ledSet(panel,60, 6, 11);
    ledSet(panel,61, 7, 11);
    ledSet(panel,72, 7, 0);
    ledSet(panel,73, 8, 0);
    ledSet(panel,85, 8, 12);
    ledSet(panel,86, 9, 12);
    ledSet(panel,98, 9, 0);
    ledSet(panel,99, 10, 0);
    ledSet(panel,112, 10, 13);
    ledSet(panel,113, 11, 13);
    ledSet(panel,126, 11, 0);
    ledSet(panel,127, 12, 0);
    ledSet(panel,142, 12, 15);
    ledSet(panel,143, 13, 15);
    ledSet(panel,158, 13, 0);
    ledSet(panel,159, 14, 0);
    ledSet(panel,175, 14, 16);
    ledSet(panel,176, 15, 16);
    ledSet(panel,192, 15, 0);
    ledSet(panel,193, 16, 0);
    ledSet(panel,210, 16, 17);
    ledSet(panel,211, 17, 17);
    ledSet(panel,226, 17, 2);
    ledSet(panel,227, 18, 2);
    ledSet(panel,243, 18, 18);
    ledSet(panel,244, 19, 18);
    ledSet(panel,262, 19, 0);
    ledSet(panel,263, 20, 0);
    ledSet(panel,282, 20, 19);
    ledSet(panel,283, 21, 19);
    ledSet(panel,302, 21, 0);
    ledSet(panel,303, 22, 0);
    ledSet(panel,323, 22, 20);
    ledSet(panel,324, 23, 20);
    ledSet(panel,344, 23, 0);
    ledSet(panel,345, 24, 0);
    ledSet(panel,365, 24, 20);
    ledSet(panel,366, 25, 20);
    ledSet(panel,386, 25, 0);
    ledSet(panel,387, 26, 0);
    ledSet(panel,408, 26, 21);
    ledSet(panel,409, 27, 21);
    ledSet(panel,430, 27, 0);
    ledSet(panel,431, 28, 0);
    ledSet(panel,452, 28, 21);
    ledSet(panel,453, 29, 21);
    ledSet(panel,475, 29, -1);
    ledSet(panel,476, 30, -1);
    ledSet(panel,499, 30, 22);
    ledSet(panel,500, 31, 22);
    ledSet(panel,523, 31, -1);
    ledSet(panel,524, 32, -1);
    ledSet(panel,547, 32, 22);
    ledSet(panel,548, 33, 22);
    ledSet(panel,571, 33, -1);
    ledSet(panel,572, 34, -1);
    ledSet(panel,596, 34, 23);
    ledSet(panel,597, 35, 23);
    ledSet(panel,621, 35, -1);
    ledSet(panel,622, 36, -1);
    ledSet(panel,646, 36, 23);
    ledSet(panel,647, 37, 23);
    ledSet(panel,671, 37, -1);
    ledSet(panel,672, 38, -1);
    ledSet(panel,698, 38, 25);
    ledSet(panel,699, 39, 25);
    ledSet(panel,725, 39, -1);
    ledSet(panel,726, 40, -1);
    ledSet(panel,752, 40, 25);
    ledSet(panel,753, 41, 25);
    ledSet(panel,779, 41, -1);
    ledSet(panel,780, 42, -1);
    ledSet(panel,805, 42, 24);
    ledSet(panel,806, 43, 24);
    ledSet(panel,831, 43, -1);
    ledSet(panel,832, 44, -1);
    ledSet(panel,848, 44, 15);
  }
  
  void mapPassengerSideLower2(int panel) {
    assert (panel < getNumStrands());

    xOffsetter = 0;
    yOffsetter = 10;
    ordinalOffsetter = 0;
    
    ledSet(panel,0, 44, 16);
    ledSet(panel,8, 44, 24);
    ledSet(panel,9, 45, 24);
    ledSet(panel,34, 45, -1);
    ledSet(panel,35, 46, -1);
    ledSet(panel,59, 46, 23);
    ledSet(panel,60, 47, 23);
    ledSet(panel,83, 47, 0);
    ledSet(panel,84, 48, 0);
    ledMissing(panel, 85);
    ledMissing(panel, 86);
    ledSet(panel,87, 48, 2);
    ledSet(panel,107, 48, 22);
    ledSet(panel,108, 49, 22);
    ledSet(panel,129, 49, 1);
    ledSet(panel,130, 50, 1);
    ledSet(panel,151, 50, 22);
    ledSet(panel,152, 51, 22);
    ledSet(panel,173, 51, 1);
    ledSet(panel,174, 52, 1);
    ledSet(panel,194, 52, 21);
    ledSet(panel,195, 53, 21);
    ledSet(panel,215, 53, 1);
    ledSet(panel,216, 54, 1);
    ledSet(panel,236, 54, 21);
    ledSet(panel,237, 55, 21);
    ledSet(panel,249, 55, 9);
  }
  
  
  void mapLowerHalfTopDriverSide(int panel) {
    assert (panel < getNumStrands());

    xOffsetter = 0;
    yOffsetter = 0;
    ordinalOffsetter = 0;
    
    ledSet(panel,0, 14, 31);
    ledSet(panel,1, 15, 31);
    ledSet(panel,3, 15, 33);
    ledSet(panel,4, 14, 33);
    ledSet(panel,5, 14, 32);
    ledSet(panel,6, 13, 32);
    ledSet(panel,8, 13, 34);
    ledSet(panel,9, 12, 34);
    ledSet(panel,11, 12, 32);
    ledSet(panel,12, 11, 32);
    ledSet(panel,15, 11, 35);
    ledSet(panel,16, 10, 35);
    ledSet(panel,19, 19, 32);
    ledSet(panel,20, 9, 32);
    ledSet(panel,24, 9, 36);
    ledSet(panel,25, 8, 36);
    ledSet(panel,29, 8, 32);
    ledSet(panel,30, 7, 32);
    ledSet(panel,35, 7, 37);
    ledSet(panel,36, 6, 37);
    ledSet(panel,41, 6, 32);
    ledSet(panel,42, 5, 32);
    ledSet(panel,47, 5, 37);
    for (int i = 48; i <= 63; i++) {
      ledMissing(panel,i);
    }
    ledSet(panel,64, 0, 22);
    ledSet(panel,65, 0, 23);
    ledMissing(panel,66);
    ledSet(panel,67, 1, 24);
    ledSet(panel,69, 1, 22);
    ledSet(panel,70, 2, 22);
    ledSet(panel,75, 2, 27);
    ledSet(panel,76, 3, 27);
    ledSet(panel,82, 3, 21);
    ledSet(panel,83, 4, 21);
    ledSet(panel,93, 4, 31);
    ledSet(panel,94, 5, 31);
    ledSet(panel,98, 5, 27);
    ledMissing(panel,99);
    ledSet(panel,100, 5, 26);
    ledSet(panel,107, 5, 19);
    ledSet(panel,108, 6, 19);
    ledSet(panel,120, 6, 31);
    ledSet(panel,121, 7, 31);
    ledSet(panel,135, 7, 17);
    ledSet(panel,136, 8, 17);
    ledSet(panel,150, 8, 31);
    ledSet(panel,151, 9, 31);
    ledSet(panel,170, 9, 12);
    ledSet(panel,171, 10, 12);
    ledSet(panel,190, 10, 31);
    ledSet(panel,191, 11, 31);
    ledSet(panel,214, 11, 8);
    ledSet(panel,215, 12, 8);
    ledSet(panel,238, 12, 31);
    ledSet(panel,239, 13, 31);
    ledSet(panel,262, 13, 8);
    ledSet(panel,263, 14, 8);
    ledSet(panel,285, 14, 30);
    ledSet(panel,286, 15, 30);
    ledSet(panel,295, 15, 21);
    ledSet(panel,296, 16, 21);
    ledMissing(panel, 299);
    ledSet(panel,306, 16, 31);
    ledSet(panel,307, 17, 31);
    ledSet(panel,316, 17, 22);
    ledSet(panel,317, 18, 22);
    ledSet(panel,326, 18, 31);
    ledSet(panel,327, 19, 31);
    ledSet(panel,336, 19, 22);
    ledSet(panel,337, 20, 22);
    ledSet(panel,346, 20, 31);
    ledSet(panel,347, 21, 31);
    ledMissing(panel, 348);
    ledSet(panel,360, 21, 18);
    ledSet(panel,361, 22, 18);
    ledSet(panel,374, 22, 31);
    ledSet(panel,375, 23, 31);
    ledSet(panel,393, 23, 13);
    ledSet(panel,394, 24, 13);
    
    //strand starts at 397
    ledSet(panel,413, 24, 32);
    ledSet(panel,414, 25, 32);
    ledSet(panel,432, 25, 14);
    ledSet(panel,433, 26, 14);
    ledSet(panel,451, 26, 32);
    ledSet(panel,452, 27, 32);
    ledSet(panel,461, 27, 23);
    ledSet(panel,462, 28, 23);
    ledSet(panel,471, 28, 32);
    ledSet(panel,472, 29, 32);
    ledSet(panel,482, 29, 22);
    ledSet(panel,483, 30, 22);
    ledSet(panel,493, 30, 32);
    ledSet(panel,494, 31, 32);
    ledSet(panel,505, 31, 21);
    ledSet(panel,506, 32, 21);
    ledSet(panel,517, 32, 32);
    ledSet(panel,518, 33, 32);
    ledSet(panel,531, 33, 19);
    ledSet(panel,532, 34, 19);
    ledSet(panel,543, 34, 30);
    ledSet(panel,544, 35, 30);
    ledSet(panel,556, 35, 18);
    ledSet(panel,557, 36, 18);
    ledSet(panel,569, 36, 30);
    ledSet(panel,570, 37, 30);
    ledSet(panel,584, 37, 16);
    ledSet(panel,585, 38, 16);
    ledSet(panel,599, 38, 30);
    ledSet(panel,600, 39, 30);
    ledSet(panel,614, 39, 16);
    ledSet(panel,615, 40, 16);
    ledSet(panel,629, 40, 30);
    ledSet(panel,630, 41, 30);
    ledSet(panel,644, 41, 16);
    ledSet(panel,645, 42, 16);
    ledSet(panel,659, 42, 30);
    ledSet(panel,660, 43, 30);
    ledSet(panel,674, 43, 16);
    ledSet(panel,675, 44, 16);
    ledSet(panel,688, 44, 29);
    ledSet(panel,689, 45, 29);
    ledSet(panel,701, 45, 17);
    ledSet(panel,702, 46, 17);
    ledSet(panel,713, 46, 28);
    ledSet(panel,714, 47, 28);
    ledSet(panel,725, 47, 17);
    ledSet(panel,726, 48, 17);
    ledSet(panel,737, 48, 28);
    ledSet(panel,738, 49, 28);
    ledSet(panel,747, 49, 19);
    ledSet(panel,748, 50, 19);
    ledSet(panel,757, 50, 28);
    ledSet(panel,758, 51, 28);
    ledSet(panel,768, 51, 18);
    ledSet(panel,769, 52, 18);
    ledSet(panel,779, 52, 28);
    ledSet(panel,780, 53, 28);
    ledSet(panel,792, 53, 16);
    ledSet(panel,793, 54, 16);
    ledSet(panel,805, 54, 28);
    ledSet(panel,806, 55, 28);
    ledSet(panel,817, 55, 17);
    ledSet(panel,818, 56, 17);
    ledSet(panel,829, 56, 28);
    ledSet(panel,830, 57, 28);
    ledSet(panel,840, 57, 18);
    ledSet(panel,841, 58, 18);
    ledSet(panel,851, 58, 28);
    ledSet(panel,852, 59, 28);
    //possible split point
    ledSet(panel,861, 59, 19);
    ledSet(panel,862, 60, 19);
    ledSet(panel,871, 60, 28);
    ledSet(panel,872, 61, 28);
    ledSet(panel,881, 61, 19);
    ledSet(panel,882, 62, 19);
    ledSet(panel,891, 62, 28);
    ledSet(panel,892, 63, 28);
    ledSet(panel,900, 63, 20);
    ledSet(panel,901, 64, 20);
    ledSet(panel,909, 64, 28);
    ledSet(panel,910, 65, 28);
    ledSet(panel,918, 65, 20);
    ledSet(panel,919, 66, 20);
    ledSet(panel,927, 66, 28);
    ledSet(panel,928, 67, 28);
    ledSet(panel,936, 67, 20);
    ledSet(panel,937, 68, 20);
    ledSet(panel,945, 68, 28);
    ledSet(panel,946, 69, 28);
    ledSet(panel,955, 69, 19);
    ledSet(panel,956, 70, 19);
    ledSet(panel,967, 70, 30);
    ledSet(panel,968, 71, 30);
    ledSet(panel,992, 71, 6);
    ledSet(panel,993, 72, 6);
    ledSet(panel,996, 72, 9);
  }
  
  
  void mapLowerHalfTopPassengerSide(int panel) {
    assert (panel < getNumStrands());
    xOffsetter = 18;
    yOffsetter = 15;
    ordinalOffsetter = 0;
    
    //    all offsets=?
    ledSet(panel,  0, 0, 24);
    ledSet(panel,  1, 0, 23);
    ledSet(panel,  2, 1, 23);
    ledSet(panel,  7, 1, 28);
    ledSet(panel,  8, 2, 28);
    ledSet(panel,  14, 2, 22);
    ledSet(panel,  15, 3, 22);
    ledSet(panel,  31, 3, 38);
    ledSet(panel,  32, 4, 38);
    ledSet(panel,  51, 4, 19);
    ledSet(panel,  52, 5, 19);
    ledSet(panel,  70, 5, 37);
    ledSet(panel,  71, 6, 37);
    ledSet(panel,  97, 6, 11);
    ledSet(panel,  98, 7, 11);
    ledSet(panel,  123, 7, 36);
    ledSet(panel,  124, 8, 36);
    ledSet(panel,  152, 8, 8);
    ledSet(panel,  153, 9, 8);
    ledSet(panel,  180, 9, 35);
    ledSet(panel,  181, 10, 35);
    ledSet(panel,  209, 10, 7);
    ledSet(panel,  210, 11, 7);
    ledSet(panel,  238, 11, 35);
    ledSet(panel,  239, 12, 35);
    ledSet(panel,  253, 12, 21);
    ledSet(panel,  254, 13, 21);
    ledSet(panel,  264, 13, 31);
    ledSet(panel,  265, 14, 31);
    ledSet(panel,  274, 14, 22);
    ledSet(panel,  275, 15, 22);
    ledSet(panel,  283, 15, 30);
    ledSet(panel,  284, 16, 30);
    ledSet(panel,  292, 16, 22);
    ledSet(panel,  293, 17, 22);
    ledSet(panel,  301, 17, 30);
    ledSet(panel,  302, 18, 30);
    ledSet(panel,  310, 18, 22);
    ledSet(panel,  311, 19, 22);
    ledSet(panel,  320, 19, 31);
    ledSet(panel,  321, 20, 31);
    ledSet(panel,  336, 20, 16);
    ledSet(panel,  337, 21, 16);
    ledMissing(panel, 349);
    ledSet(panel,350, 21, 28);
    ledSet(panel,  353, 21, 31);
    ledSet(panel,  354, 22, 31);
    ledSet(panel,  369, 22, 16);
    ledSet(panel,  370, 23, 16);
    ledSet(panel,  385, 23, 31);
    ledSet(panel,  386, 24, 31);
    ledSet(panel,  399, 24, 18);
    ledSet(panel,  400, 25, 18);
    ledSet(panel,  413, 25, 31);
    ledSet(panel,  414, 26, 31);
    ledSet(panel,  423, 26, 22);
    ledSet(panel,  424, 27, 22);
    ledSet(panel,  433, 27, 31);
    ledSet(panel,  434, 28, 31);
    ledSet(panel,  442, 28, 23);
    ledSet(panel,  443, 29, 23);
    ledSet(panel,  451, 29, 31);
    ledSet(panel,  452, 30, 31);
    ledSet(panel,  459, 30, 24);
    ledSet(panel,  460, 31, 24);
    ledSet(panel,  467, 31, 31);
    ledSet(panel,  468, 32, 31);
    ledSet(panel,  484, 32, 15);
    ledSet(panel,  485, 33, 15);
    ledSet(panel,  501, 33, 31);
    ledSet(panel,  502, 34, 31);
    ledSet(panel,  518, 34, 15);
    ledSet(panel,  519, 35, 15);
    ledSet(panel,  535, 35, 31);
    ledSet(panel,  536, 36, 31);
    ledSet(panel,  552, 36, 15);
    ledSet(panel,  553, 37, 15);
    ledSet(panel,  569, 37, 31);
    ledMissing(panel, 570);
    ledMissing(panel, 571);
    ledSet(panel,572, 38, 15);
    ledSet(panel,  588, 38, 31);
    ledSet(panel,  589, 39, 31);
    ledSet(panel,  605, 39, 15);
    ledSet(panel,  606, 40, 15);
    ledSet(panel,  622, 40, 31);
    ledSet(panel,  623, 41, 31);
    ledSet(panel,  636, 41, 18);
    ledSet(panel,  637, 42, 18);
    ledSet(panel,  650, 42, 31);
    ledSet(panel,  651, 43, 31);
    ledSet(panel,  661, 43, 21);
    ledSet(panel,  662, 44, 21);
    ledSet(panel,  672, 44, 31);
    ledSet(panel,  673, 45, 31);
    ledSet(panel,  683, 45, 21);
    ledSet(panel,  684, 46, 21);
    ledSet(panel,  694, 46, 31);
    ledSet(panel,  695, 47, 31);
    ledSet(panel,  709, 47, 17);
    ledSet(panel,  710, 48, 17);
    ledSet(panel,  724, 48, 31);
    ledSet(panel,  725, 49, 31);
    ledSet(panel,  740, 49, 16);
    ledSet(panel,  741, 50, 16);
    ledSet(panel,  754, 50, 29);
    ledSet(panel,  755, 51, 29);
    ledSet(panel,  768, 51, 16);
    ledSet(panel,  769, 52, 16);
    ledSet(panel,  782, 52, 29);
    ledSet(panel,  783, 53, 29);
    ledSet(panel,  796, 53, 16);
    ledSet(panel,  797, 54, 16);
    ledSet(panel,  810, 54, 29);
    ledSet(panel,  811, 55, 29);
    ledSet(panel,  824, 55, 16);
    ledSet(panel,  825, 56, 16);
    ledSet(panel,  838, 56, 29);
    ledSet(panel,  839, 57, 29);
    ledSet(panel,  851, 57, 17);
    ledSet(panel,  852, 58, 17);
    ledSet(panel,  864, 58, 29);
    ledSet(panel,  865, 59, 29);
    ledSet(panel,  875, 59, 19);
    ledSet(panel,  876, 60, 19);
    ledSet(panel,  886, 60, 29);
    ledSet(panel,  887, 61, 29);
    ledSet(panel,  895, 61, 21);
    ledSet(panel,  896, 62, 21);
    ledSet(panel,  904, 62, 29);
    ledSet(panel,  905, 63, 29);
    ledSet(panel,  912, 63, 22);
    ledSet(panel,  913, 64, 22);
    ledSet(panel,  920, 64, 29);
    ledSet(panel,  921, 65, 29);
    ledSet(panel,  929, 65, 21);
    ledSet(panel,  930, 66, 21);
    ledSet(panel,  938, 66, 29);
    ledSet(panel,  939, 67, 29);
    ledSet(panel,  961, 67, 7);
    ledSet(panel,  962, 68, 7);
    ledSet(panel,  972, 68, 17);
  }
  
  void mapUpperHalfTopDriverSide(int panel) {
    assert (panel < getNumStrands());

    //top of top driver side
    xOffsetter = 15;
    yOffsetter = 0;
    ordinalOffsetter = 0;
    
    ledSet(panel,0, 0, 6);
    ledSet(panel,3, 0, 9);
    ledSet(panel,4, 0, 11);
    ledSet(panel,5, 0, 13);
    ledSet(panel,8, 0, 16);
    ledSet(panel,9, 1, 16);
    ledSet(panel,12, 1, 13);
    ledSet(panel,13, 1, 11);
    ledSet(panel,14, 1, 9);
    ledSet(panel,18, 1, 5);
    ledSet(panel,19, 2, 5);
    ledSet(panel,24, 2, 10);
    ledSet(panel,25, 2, 12);
    ledSet(panel,28, 2, 15);
    ledSet(panel,29, 3, 14);
    ledSet(panel,30, 3, 13);
    ledSet(panel,31, 3, 12);
    ledSet(panel,32, 3, 11);
    ledSet(panel,38, 3, 5);
    ledSet(panel,39, 4, 5);
    ledSet(panel,46, 4, 12);
    ledSet(panel,47, 5, 12);
    ledSet(panel,55, 5, 4);
    ledSet(panel,56, 6, 4);
    ledSet(panel,63, 6, 11);
    ledSet(panel,64, 7, 11);
    ledSet(panel,71, 7, 4);
    ledSet(panel,72, 8, 4);
    ledSet(panel,80, 8, 12);
    ledSet(panel,81, 9, 12);
    ledSet(panel,89, 9, 4);
    ledSet(panel,90, 10, 4);
    ledSet(panel,99, 10, 13);
    ledSet(panel,100, 11, 13);
    ledSet(panel,111, 11, 2);
    ledSet(panel,112, 12, 2);
    ledSet(panel,123, 12, 13);
    ledSet(panel,124, 13, 13);
    ledSet(panel,136, 13, 1);
    ledSet(panel,137, 14, 1);
    ledSet(panel,149, 14, 13);
    ledSet(panel,150, 15, 13);
    ledSet(panel,162, 15, 1);
    ledSet(panel,163, 16, 1);
    ledSet(panel,176, 16, 14);
    ledSet(panel,177, 17, 14);
    ledSet(panel,191, 17, 0);
    ledSet(panel,192, 18, 0);
    ledSet(panel,207, 18, 15);
    ledSet(panel,208, 19, 15);
    ledSet(panel,223, 19, 0);
    ledSet(panel,224, 20, 0);
    ledSet(panel,241, 20, 17);
    ledSet(panel,242, 21, 17);
    ledSet(panel,259, 21, 0);
    ledSet(panel,260, 22, 0);
    ledSet(panel,275, 22, 15);
    ledSet(panel,276, 23, 15);
    ledSet(panel,291, 23, 0);
    ledSet(panel,292, 24, 0);
    ledSet(panel,307, 24, 15);
    ledSet(panel,308, 25, 15);
    ledSet(panel,323, 25, 0);
    ledSet(panel,324, 26, 0);
    ledSet(panel,339, 26, 15);
    ledSet(panel,340, 27, 15);
    ledSet(panel,355, 27, 0);
    ledSet(panel,356, 28, 0);
    ledSet(panel,371, 28, 15);
    ledSet(panel,372, 29, 15);
    ledSet(panel,387, 29, 0);
    ledSet(panel,388, 30, 0);
    //note: 400 has double
    ledSet(panel,399, 30, 11);
    ledMissing(panel,400);
    ledMissing(panel,401);
    ledSet(panel,402, 30, 12);
    ledSet(panel,406, 30, 16);
    ledSet(panel,407, 31, 16);
    ledSet(panel,423, 31, 0);
    ledSet(panel,424, 32, 0);
    ledSet(panel,435, 32, 11);
    ledSet(panel,436, 33, 11);
    ledSet(panel,447, 33, 0);
    ledSet(panel,448, 34, 0);
    ledSet(panel,459, 34, 11);
    ledSet(panel,460, 35, 11);
    //460 on double mesh
    ledSet(panel,471, 35, 0);
    ledSet(panel,472, 36, 0);
    ledSet(panel,483, 36, 11);
    ledSet(panel,484, 37, 11);
    ledSet(panel,495, 37, 0);
    ledSet(panel,496, 38, 1);
    //500 is final light of strand
    ledSet(panel,508, 38, 13);
    ledSet(panel,509, 39, 13);
    ledSet(panel,521, 39, 1);
    ledSet(panel,522, 40, 1);
    ledSet(panel,537, 40, 16);
    ledSet(panel,538, 41, 16);
    ledSet(panel,553, 41, 1);
    ledSet(panel,554, 42, 1);
    ledSet(panel,570, 42, 17);
    ledSet(panel,571, 43, 17);
    ledSet(panel,587, 43, 1);
    ledSet(panel,588, 44, 1);
    ledSet(panel,605, 44, 18);
    ledSet(panel,606, 45, 18);
    ledSet(panel,622, 45, 2);
    ledSet(panel,623, 46, 2);
    ledSet(panel,632, 46, 11);
    ledSet(panel,633, 47, 11);
    ledSet(panel,641, 47, 3);
    ledSet(panel,642, 48, 3);
    ledSet(panel,650, 48, 11);
    ledSet(panel,651, 49, 10);
    ledSet(panel,658, 49, 3);
    ledSet(panel,659, 50, 4);
    ledSet(panel,666, 50, 11);
    ledSet(panel,667, 51, 11);
    ledSet(panel,674, 51, 4);
    ledSet(panel,675, 52, 5);
    ledSet(panel,681, 52, 11);
    ledMissing(panel,682);
    ledMissing(panel,683);
    ledMissing(panel,684);
    ledMissing(panel,685);
    ledSet(panel,686, 54, 7);
    ledSet(panel,692, 54, 13);
    ledSet(panel,693, 55, 13);
    ledSet(panel,700, 55, 6);
    ledSet(panel,701, 57, 10);
    ledSet(panel,  720, 57, 29);
    ledSet(panel,  721, 58, 29);
    ledSet(panel,  743, 58, 7);
    ledSet(panel,  744, 59, 7);
    ledSet(panel,  765, 59, 28);
    ledSet(panel,  766, 60, 28);
    ledSet(panel,  786, 60, 8);
    ledSet(panel,  787, 61, 8);
    ledSet(panel,  807, 61, 27);
    ledSet(panel,  808, 62, 27);
    ledSet(panel,  826, 62, 10);
    ledSet(panel,  827, 63, 10);
    ledSet(panel,  845, 63, 28);
    ledSet(panel,  846, 64, 28);
    ledSet(panel,  863, 64, 11);
    ledSet(panel,  864, 65, 11);
    ledSet(panel,  883, 65, 30);
    ledSet(panel,  884, 66, 30);
    ledSet(panel,  902, 66, 12);
    ledSet(panel,  903, 67, 12);
    ledSet(panel,  920, 67, 29);
    ledSet(panel,  921, 68, 29);
    ledSet(panel,  936, 68, 14);
    ledSet(panel,  937, 69, 14);
    ledSet(panel,  950, 69, 27);
    ledSet(panel,  951, 70, 27);
    ledSet(panel,  962, 70, 16);
    ledSet(panel,  963, 71, 16);
    ledSet(panel,  973, 71, 26);
    ledSet(panel,  974, 72, 26);
    ledSet(panel,  982, 72, 18);
    ledSet(panel,  983, 73, 18);
    ledSet(panel,  989, 73, 24);
    ledSet(panel,  990, 74, 24);
    ledSet(panel,  994, 74, 20);
    ledSet(panel,  995, 75, 20);
    ledSet(panel,  998, 75, 23);
    ledSet(panel,  999, 76, 23);
    ledSet(panel,  1000, 76, 22);
  }
  
  
  void mapPassengerSideUpperTop1(int panel) {
    assert (panel < getNumStrands());
    
    //top of top driver side
    xOffsetter = 0;
    yOffsetter = 0;
    ordinalOffsetter = 0;
    
    ledMissing(panel,0);
    ledMissing(panel,1);
    ledMissing(panel,2);
    
    ledSet(panel,3, 14, 4);
    ledSet(panel,4, 13, 4);
    ledSet(panel,5, 12, 5);
    ledSet(panel,16, 12, 16);
    ledSet(panel,17, 13, 16);
    ledSet(panel,29, 13, 5);
    ledSet(panel,30, 14, 5);
    ledSet(panel,41, 14, 16);
    ledSet(panel,42, 15, 16);
    ledSet(panel,54, 15, 4);
    ledSet(panel,55, 16, 4);
    ledSet(panel,66, 16, 15);
    ledSet(panel,67, 17, 15);
    ledSet(panel,78, 17, 4);
    ledSet(panel,79, 18, 3);
    ledSet(panel,91, 18, 15);
    ledSet(panel,92, 19, 15);
    ledSet(panel,106, 19, 1);
    ledSet(panel,107, 20, 1);
    ledSet(panel,121, 20, 15);
    ledSet(panel,122, 21, 15);
    ledSet(panel,136, 21, 1);
    ledSet(panel,137, 22, 1);
    ledSet(panel,151, 22, 15);
    ledSet(panel,152, 23, 15);
    ledSet(panel,166, 23, 1);
    ledSet(panel,167, 24, 1);
    ledSet(panel,183, 24, 17);
    ledSet(panel,184, 25, 17);
    ledSet(panel,200, 25, 1);
    ledSet(panel,201, 26, 1);
    ledSet(panel,217, 26, 17);
    ledSet(panel,218, 27, 17);
    ledSet(panel,235, 27, 0);
    ledSet(panel,236, 28, 0);
    ledSet(panel,252, 28, 16);
    ledSet(panel,253, 29, 16);
    ledSet(panel,269, 29, 0);
    ledSet(panel,270, 30, 0);
    ledSet(panel,285, 30, 15);
    ledSet(panel,286, 31, 15);
    ledSet(panel,301, 31, 0);
    ledSet(panel,302, 32, 0);
    ledSet(panel,316, 32, 14);
    ledSet(panel,317, 33, 14);
    ledSet(panel,331, 33, 0);
    ledSet(panel,332, 34, 0);
    ledSet(panel,346, 34, 14);
    ledSet(panel,347, 35, 14);
    ledSet(panel,361, 35, 0);
    ledSet(panel,362, 36, 0);
    ledSet(panel,376, 36, 14);
    ledSet(panel,377, 37, 14);
    ledSet(panel,391, 37, 0);
    ledSet(panel,392, 38, 0);
    ledSet(panel,406, 38, 14);
    ledSet(panel,407, 39, 14);
    ledSet(panel,421, 39, 0);
    ledSet(panel,422, 40, 0);
    ledSet(panel,436, 40, 14);
    ledSet(panel,437, 41, 14);
    ledSet(panel,451, 41, 0);
    ledSet(panel,452, 42, 0);
    ledSet(panel,467, 42, 15);
    ledSet(panel,468, 43, 15);
    ledSet(panel,483, 43, 0);
    ledSet(panel,484, 44, 0);
    ledSet(panel,498, 44, 14);
    ledSet(panel,499, 45, 14);
    ledSet(panel,513, 45, 0);
    ledSet(panel,514, 45, 0);
    ledSet(panel,528, 46, 14);
    ledSet(panel,529, 46, 14);
    ledSet(panel,542, 47, 1);
    ledSet(panel,543, 47, 1);
    ledSet(panel,557, 48, 15);
    ledSet(panel,558, 48, 15);
    ledSet(panel,573, 49, 1);
    ledSet(panel,574, 49, 1);
    ledSet(panel,587, 50, 15);
    ledSet(panel,588, 50, 15);
    ledSet(panel,602, 51, 1);
    ledSet(panel,603, 51, 1);
    ledSet(panel,617, 52, 15);
    ledSet(panel,618, 52, 15);
    ledSet(panel,631, 53, 2);
    ledSet(panel,632, 53, 2);
    ledSet(panel,645, 54, 15);
    ledSet(panel,646, 54, 15);
    ledSet(panel,658, 55, 3);
    ledSet(panel,659, 55, 3);
    ledSet(panel,671, 56, 15);
    ledSet(panel,672, 56, 15);
    ledSet(panel,684, 57, 3);
    ledSet(panel,685, 57, 3);
    
    ledSet(panel,697, 58, 15);
    ledMissing(panel, 698);
    ledSet(panel,699, 58, 14);
    ledSet(panel,710, 59, 3);
    ledSet(panel,711, 59, 4);
    ledSet(panel,719, 60, 12);
    ledSet(panel,720, 60, 12);
    ledSet(panel,728, 61, 4);
    ledSet(panel,729, 61, 4);
    ledSet(panel,735, 62, 10);
    ledSet(panel,736, 62, 10);
    ledSet(panel,741, 63, 5);
    ledSet(panel,742, 63, 5);
    ledSet(panel,749, 64, 12);
    ledSet(panel,750, 64, 12);
    ledSet(panel,756, 65, 6);
    for (int i = 757; i <= 774; i++) {
      ledMissing(panel,i);
    }

  }
  
  void allOnePixel(int panel) {
    assert (panel < getNumStrands());
    
    //top of top driver side
    xOffsetter = 0;
    yOffsetter = 0;
    ordinalOffsetter = 0;

    for (int i = 0; i < getStrandSize(panel); i++) {
      ledSet(panel,i,ledWidth-1,ledHeight-1);
    }
  }
  
  
  int getStrandSize(int whichStrand) {
    return strandSizes[whichStrand];
  }
  
  int getNumStrands() {
    return 8;
  }
  
  void mapAllLeds() {

    mapUpperHalfTopDriverSide(0);
    mapDriverSideLowerPart2(1);
    mapDriverSideLowerPart1(2);
    mapLowerHalfTopDriverSide(3);
    
    mapPassengerSideUpperTop1(4);
    mapPassengerSideLower1(5);
    mapPassengerSideLower2(6);
    mapLowerHalfTopPassengerSide(7);
    
    
  }
  
  
  
}