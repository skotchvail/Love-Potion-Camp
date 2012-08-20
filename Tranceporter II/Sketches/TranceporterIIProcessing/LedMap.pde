class LedMap extends Pixels {

  
  int[] strandSizes;

  LedMap(PApplet p) {
    super(p);
    strandSizes = new int[]
    {
      850, //strand 0(1)
      850, //strand 1(2)
      500, //strand 2(3)
      100, //strand 3(4)
      100, //strand 4(5)
      100, //strand 5(6)
      100, //strand 6(7)
      100, //strand 7(8)
    };
  }
 
  void setup() {
    super.setup();
  }

  
  void mapDriverSideLowerPart1(int panel) {
    assert (panel < getNumStrands());

    xOffsetter = 0;
    yOffsetter = 16;
    
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
    yOffsetter = 16;
    
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
    assert (panel < getNumStrands());

    /*
     
     */
    
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);
//    ledSet(panel,0, 0, 0);

    
    
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