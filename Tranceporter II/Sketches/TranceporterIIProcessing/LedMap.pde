class LedMap extends Pixels {

  
  int[] strandSizes;

  LedMap(PApplet p) {
    super(p);
    strandSizes = new int[]
    {
      1250, //strand 0
      900, //strand 1
      900, //strand 2
      100, //strand 3
      100, //strand 4
      100, //strand 5
      100, //strand 6
      100, //strand 7
    };
  }
 
  void setup() {
    super.setup();

  }

  
  void mapDriverSideLower(int panel) {
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
    ledSet(panel,868, 44, 23);
    ledSet(panel,869, 45, 23);
    ledSet(panel,895, 45, -3);
    ledSet(panel,896, 46, -3);
    ledSet(panel,922, 46, 23);
    ledSet(panel,923, 47, 23);
    ledSet(panel,949, 47, -3);
    ledSet(panel,950, 48, -3);
    ledSet(panel,975, 48, 22);
    ledSet(panel,976, 49, 22);
    ledSet(panel,999, 49, -1);
    ledSet(panel,1000, 50, -1);
    ledSet(panel,1023, 50, 22);
    ledSet(panel,1024, 51, 22);
    ledSet(panel,1048, 51, -2);
    ledSet(panel,1049, 52, -2);
    ledSet(panel,1073, 52, 22);
    ledSet(panel,1074, 53, 22);
    ledSet(panel,1099, 53, -3);
    ledSet(panel,1100, 54, -3);
    ledSet(panel,1124, 54, 21);
    ledSet(panel,1125, 55, 21);
    ledSet(panel,1149, 55, -3);
    ledSet(panel,1150, 56, -3);
    ledSet(panel,1173, 56, 20);
    ledSet(panel,1174, 57, 20);
    ledSet(panel,1195, 57, -1);
    ledSet(panel,1196, 58, -1);
    ledSet(panel,1216, 58, 19);
    ledSet(panel,1217, 59, 19);
    ledSet(panel,1237, 59, -1);
    ledSet(panel,1238, 60, -1);
    ledSet(panel,1249, 60, 10);

  }

  void mapDriverSideUpper(int panel) {
  }

  void mapPassengerSideUpper(int panel) {
  }

  void mapPassengerSideLower(int panel) {
  }

  
  int getStrandSize(int whichStrand) {
    return strandSizes[whichStrand];
  }

  int getNumStrands() {
    return 3;
  }


  void mapAllLeds() {
    
    final int s0 = 0;
    final int s1 = 1;
    final int s2 = 2;
    final int s3 = 3;
    final int s4 = 4;
    final int s5 = 5;
    final int s6 = 6;
    final int s7 = 7;
    
    mapDriverSideLower(s0);
    mapDriverSideUpper(s1);
    mapPassengerSideLower(s2);
    mapPassengerSideUpper(s3);
  }
  
  
  
}