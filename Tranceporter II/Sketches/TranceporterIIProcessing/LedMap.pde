class LedMap extends Pixels {

  
  int[] strandSizes;

  LedMap(PApplet p) {
    super(p);
    strandSizes = new int[]
    {
      850, //strand 0(1)
      400, //strand 1(2)
      800, //strand 2(3)
      200, //strand 3(4)
      200, //strand 4(5)
      200, //strand 5(6)
      200, //strand 6(7)
      200, //strand 7(8)
    };
  }
 
  void setup() {
    super.setup();
  }

  
  void mapDriverSideLowerPart1(int panel) {
    assert (panel < getNumStrands());

    //highest y is 28
    
    xOffsetter = 0;
    yOffsetter = 23+3;
    
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

    xOffsetter = 0;
    yOffsetter = 23+3;
    
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

  void mapPassengerSideUpper(int panel) {
    assert (panel < getNumStrands());
  }

  void mapPassengerSideLower(int panel) {
    assert (panel < getNumStrands());
  }

  
  int getStrandSize(int whichStrand) {
    return strandSizes[whichStrand];
  }

  int getNumStrands() {
    return 3;
  }

  void mapAllLeds() {
    
    mapDriverSideLowerPart1(0);
    mapDriverSideLowerPart2(1);
    mapDriverSideUpper(2);
//    mapPassengerSideLower(3);
//    mapPassengerSideUpper(4);
  }
  
  
  
}