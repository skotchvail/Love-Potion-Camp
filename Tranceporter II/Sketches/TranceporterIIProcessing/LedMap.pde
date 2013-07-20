/*
 This class initializes:
 1. The pixel metadata: including mapping of LEDs to x/y coordinates and vice versa
    This is accomplished by reading metadata from a set of csv files
 2. The LCD hardware
 3. The data structure that instructs the hardware how to illuminate the LED strands
 
 var pixelData: 
    contains the colors for each pixel as they are drawn on screen (in the 2D double sided view).
    The starboard side is indexed as [length - x - 1]. The data is sent as is to the hardware
    without modification.
 
 var strandMap:
    contains the x, y coordinates of each LED. It is effectively a 2D array, where each
    strand is one dimension, and the ordinal is another. The X,Y coordinates for each LED
    are encoded in an integer. These map to the same coordinates used by pixel Data. This
    data is sent to the hardware without modification.

 var trainingStrandMap: 
    an alternate strandmap used by HardwareTest, which is also sent to the hardware without
    modification.

 */

class LedMap {
  
  // TCL settings
  final boolean runConcurrent = true;
  final boolean kUseBitBang = true;

  // array of data representing the current color for each given pixel in our flat array
  color[] pixelData;

  // array of values for the actual length of each strand
  int[] strandSizes;

  // the longest strand we'll tolerate
  int maxPixelsPerStrand;

  // array of integers that maps a strand index to a coordinate pair
  private int[] strandMap;

  // same thing, but a reduced "training" version
  private int[] trainingStrandMap;

  // "Table" (2d array) of data we've read from the csv files
  private Table[] strandTables;

  // static final String kCommandOffsetter = "offsetter";
  // the legal commands we can find in our LED-defining csv files
  static final String kCommandMap = "map";
  static final String kCommandMissing = "missing";
  static final String kCommandUnprogrammed = "unprogrammed";
  
  // the columns in our LED-defining csv files
  static final String kColumnCommand = "command";
  static final String kColumnOrdinal = "ordinalStart";
  static final String kColumnOrdinalEnd = "ordinalEnd";
  static final String kColumnCoordX = "x";
  static final String kColumnCoordY = "y";
  
  // constructor
  LedMap() {

    // initialize class variables
    strandSizes        = new int[getNumStrands()];    
    strandTables       = new Table[getNumStrands()];
    int totalPixels    = 0;
    maxPixelsPerStrand = 0;

    // loop through each strand and read data from csv files
    for (int i = 0; i < getNumStrands(); i++) {
      
      Table table = loadTable(fileNameForStrand(i), "header");
      strandTables[i] = table;
      TableRow lastRow = table.getRow(table.lastRowIndex());
      strandSizes[i] = lastRow.getInt(kColumnOrdinalEnd) + 1;
      System.out.println("Strand " + (i + 1) + " has length " + strandSizes[i]);
      int strandSize = getStrandSize(i);
      if (strandSize > maxPixelsPerStrand) {
        maxPixelsPerStrand = strandSize;
      }
      totalPixels += strandSize;
    }

    // make sure we haven't exceeded our maximum number of pixels
    assert (totalPixels < ledWidth * ledHeight);

    // set the total number of pixels we're dealing with
    int pixelDataSize = max(totalPixels, ledWidth * ledHeight);

    // initialize more class variables
    pixelData = new color[pixelDataSize];    
    strandMap = new int[getNumStrands() * maxPixelsPerStrand];
    trainingStrandMap = new int[getNumStrands() * maxPixelsPerStrand];
    
    // initialize TCL interface
    initTotalControl();

  }

  /*
   Data Format csv:
   'Offsetter', ordinal, 0, x, y (delta to previous offsetters)
   'set',       ordinal, 0, x, y
   'missing',   ordinalStart, ordinalEnd
   'unprogrammed', ordinalStart, ordinalEnd (not sure we need this)
   */
  
  // get the filename for a given strand
  String fileNameForStrand(int whichStrand) {
    return "strand" + (whichStrand + 1) + ".csv";
  }
  
  // write strand data to a csv file
  void writeOneStrandToDisk(int whichStrand) {
    println("================== writeOneStrandToDisk " + (whichStrand + 1));
    assert whichStrand < getNumStrands() : "not this many strands";
    
    int strandSize = getStrandSize(whichStrand);
    Table table = new Table();
    table.addColumn(kColumnCommand, Table.STRING);
    table.addColumn(kColumnOrdinal, Table.INT);
    table.addColumn(kColumnOrdinalEnd, Table.INT);
    table.addColumn(kColumnCoordX, Table.INT);
    table.addColumn(kColumnCoordY, Table.INT);
    
    TableRow row = null;
    
    for (int whichLed = 0; whichLed < strandSize; whichLed++) {
      
      int index = (whichStrand * maxPixelsPerStrand) + whichLed;
      assert index < strandMap.length : "strand: " + whichStrand + " whichLed: " + 
        whichLed + " goes beyond end of strandMap (" + index + " >= " + strandMap.length + ")";
      int value = strandMap[index];

      if (value >= 0) {
        Point p = indexToCoordinate(value);
        p = convertDoubleSidedPoint(p, whichStrand);
        
        // TODO: this can probably be cleaned up to not have so many else row = null statements.
        if (row != null) {
          if (!row.getString(kColumnCommand).equals(kCommandMap)) {
            row = null;
          }
          else {
            int ordinalEnd = row.getInt(kColumnOrdinalEnd);
            if (ordinalEnd + 1 != whichLed) {
              row = null;
            }
            else {
              int numRows = table.getRowCount();
              if (numRows >= 2) {
                
                TableRow startRow = table.getRow(numRows - 2);
                if (startRow.getString(kColumnCommand).equals(kCommandMap)) {
                  int startX = startRow.getInt(kColumnCoordX);
                  int startY = startRow.getInt(kColumnCoordY);
                  int endX = row.getInt(kColumnCoordX);
                  int endY = row.getInt(kColumnCoordY);
                  
                  int deltaX = endX - startX;
                  int deltaY = endY - startY;
                  int ordinalStart = startRow.getInt(kColumnOrdinal);
                  int deltaOrdinal = whichLed - ordinalStart;
                  
                  if ((deltaX == 0) == (deltaY == 0)) {
                    row = null;
                  }
                  else if ((p.y == endY) && ((endX > startX && p.x == endX + 1 && p.x == startX + deltaOrdinal) ||
                           (endX < startX && p.x == endX - 1 && p.x == startX - deltaOrdinal))) {
                    assert(startY == endY) : "startY = " + startY + " endY = " + endY + " whichLed = " + whichLed;
                    row.setInt(kColumnCoordX, p.x);
                    row.setInt(kColumnOrdinalEnd, whichLed);
                  }
                  else if ((p.x == endX) && ((endY > startY && p.y == endY + 1 && p.y == startY + deltaOrdinal) ||
                      (endY < startY && p.y == endY - 1 && p.y == startY - deltaOrdinal))) {
                    assert(startX == endX) : "startX = " + startX + " endX = " + endX + " whichLed = " + whichLed + " whichStrand = " + whichStrand;
                    row.setInt(kColumnCoordY, p.y);
                    row.setInt(kColumnOrdinalEnd, whichLed);
                  }
                  else {
                    row = null;
                  }
                }
                else {
                  row = null;
                }
              }
              else {
                row = null;
              }
            }
          }
        }
        
        if (row == null) {
          row = table.addRow();
          row.setString(kColumnCommand, kCommandMap);
          row.setInt(kColumnOrdinal, whichLed);
          row.setInt(kColumnOrdinalEnd, whichLed);
          row.setInt(kColumnCoordX, p.x);
          row.setInt(kColumnCoordY, p.y);
        }
      }
      else if (value == TC_PIXEL_UNUSED) {
        
        if (row != null) {
          if (!row.getString(kColumnCommand).equals(kCommandMissing)) {
            row = null;
          }
          else {
            int ordinalEnd = row.getInt(kColumnOrdinalEnd);
            if (ordinalEnd + 1 == whichLed) {
              row.setInt(kColumnOrdinalEnd, whichLed);
            }
          }
        }
          
        if (row == null) {
          row = table.addRow();
          row.setString(kColumnCommand, kCommandMissing);
          row.setInt(kColumnOrdinal, whichLed);
          row.setInt(kColumnOrdinalEnd, whichLed);
        }
      }
      else {
        assert (value == TC_PIXEL_DISCONNECTED || value == TC_PIXEL_UNDEFINED) : "unexpected value is " + value + " for ordinal " + whichLed;
      }
    }
    saveTable(table, "data/" + fileNameForStrand(whichStrand));
  }
  
  // read strand data to a csv file
  void readOneStrandFromDisk(int whichStrand) {

    // println("Reading Strand " + whichStrand);    
    assert whichStrand < getNumStrands() : "not this many strands";

    // first pass - fill in all legal values with "UNDEFINED"
    int start = whichStrand * maxPixelsPerStrand;
    int boundary = (whichStrand + 1) * maxPixelsPerStrand;
    for (int i = start; i < boundary; i++) {
      // println("index: " + i + " Undefined ");
      strandMap[i] = TC_PIXEL_UNDEFINED;
    }

    // unused    
    // xOffsetter = 0;
    // yOffsetter = 0;
    // ordinalOffsetter = 0;
    
    Table table = strandTables[whichStrand];
//    println("strand " + (whichStrand + 1) + " rows: " + table.getRowCount());
    assert table.getRowCount() > 0 : "rowCount = 0 for strand " + (whichStrand + 1);
    
    for (TableRow row : table.rows()) {

      // get the "command" for this row      
      String command = row.getString(kColumnCommand);
      int ordinalStart = row.getInt(kColumnOrdinal); // + ordinalOffsetter;
      int ordinalEnd = row.getInt(kColumnOrdinalEnd); // + ordinalOffsetter;

//      if (whichStrand == 0) {
//        println("Strand " + whichStrand + "\t" + command + "," + ordinalStart
//           + "," + ordinalEnd + "," + row.getInt(kColumnCoordX) + "," + row.getInt(kColumnCoordY) );
//      }
      if (command.equals(kCommandMap)) {
        Point coord = new Point(row.getInt(kColumnCoordX), row.getInt(kColumnCoordY));
        // coord.x += xOffsetter;
        // coord.y += yOffsetter;
        
        lowestX = min(coord.x, lowestX);
        lowestY = min(coord.y, lowestY);
        biggestX = max(coord.x, biggestX);
        biggestY = max(coord.y, biggestY);
        int index = (whichStrand * maxPixelsPerStrand) + ordinalEnd;
        assert(strandMap[index] == TC_PIXEL_UNDEFINED) : "led " + ordinalEnd + " on strand " + whichStrand + " is already defined: " + strandMap[index];
        coord = convertDoubleSidedPoint(coord, whichStrand);
        int pixelDataIndex = coordToIndex(coord);
        strandMap[index] = pixelDataIndex;
//        if (whichStrand == 0) {
//          println("index: " + index + " pixelDataIndex: " + pixelDataIndex);
//        }
      }
      else if (command.equals(kCommandMissing)) {
        for (int ordinal = ordinalStart; ordinal <= ordinalEnd; ordinal++) {
          int index = (whichStrand * maxPixelsPerStrand) + ordinal;
          assert(strandMap[index] == TC_PIXEL_UNDEFINED) : "led " + ordinal + " on strand " + whichStrand + " is already defined: " + strandMap[index];
          strandMap[index] = TC_PIXEL_UNUSED;
//          if (whichStrand == 0) {
//            println("index: " + index + " Unused ");
//          }
        }
      }
      else {
        assert false : "unimplemented command: " + command;
      }
    }
  }
  
  // write passed data array to pixelData array
  void copyPixels(int[] pixels, DrawType drawType) {
    final int halfWidth = ledWidth / 2;
    
    if (drawType == DrawType.MirrorSides) {
      // Image is mirrored
      for (int y = 0; y < ledHeight; y++) {
        final int baseY = y * halfWidth;
        final int baseYData = y * ledWidth;
        for (int x = 0; x < halfWidth; x++) {
          color pixel = pixels[baseY + x];
          pixelData[baseYData + x] = pixel;
          pixelData[baseYData + (ledWidth - x - 1)] = pixel;
        }
      }
    }
    else if (drawType == DrawType.RepeatingSides) {
      // Image is repeated
      for (int y = 0; y < ledHeight; y++) {
        final int baseY = y * halfWidth;
        final int baseYData = y * ledWidth;
        for (int x = 0; x < halfWidth; x++) {
          color pixel = pixels[baseY + x];
          pixelData[baseYData + x] = pixel;
          pixelData[baseYData + x + halfWidth] = pixel;
        }
      }
    }
    else if (drawType == DrawType.TwoSides) {
      arrayCopy(pixels, 0, pixelData, 0, pixels.length);
    }
    else {
      assert false : "unknown drawType = " + drawType;
    }
  }

  // get number of pixels in a given strand  
  int getStrandSize(int whichStrand) {
    int result = strandSizes[whichStrand];
    assert result >= 0 : "strand " + (whichStrand + 1) + "size = " + result;
    return result;
  }
  
  // get the total number of strands we have
  int getNumStrands() {
    return 8;
  }
  
  ////////////////////////////////////////////////////////////////////
  //Total Control
  
  /*
   spreadsheet
   
   for each led:
   which strand, offset x, y, which shape
   
   strand1:
   1: 3, 10, shapeA
   2: 16, 10, shapeA
   3: 55, 9, shapeB
   4: unused
   3: 59, 49, shapeB
   
   strand2:
   1: 77, 14, shapeA
   2: 46, 98, shapeA
   3: 3, 12, shapeB
   
   */
  
  
  /*
   ..    00      01      02      03      04      05      06      07      08      09      10
   00    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   01    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   02    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   03    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   04    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   05    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   
   ..   00      01      02      03      04      05      06      07      08      09      10      11      12      13      14
   sA: (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00)
   sB  (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00)
   sC  (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00)
   
   
   */
  
  // Convert coordinates into index into pixelData index
  private int coordToIndex(Point p) {
    return (p.y * ledWidth) + p.x;
  }

  // Convert index into pixel coordinates  
  private Point indexToCoordinate(int index) {
    Point p = new Point();
    p.y = index / ledWidth;
    p.x = index % ledWidth;
    return p;
  }

  // Call to convert a single sided point to a double sided point,
  // or vice versa. Works both ways.
  // TODO: not sure if this method is needed
  Point convertDoubleSidedPoint(Point p, int whichStrand) {
    Point result = new Point(p);
    if (p.x >= 0 && !isStrandPortSide(whichStrand)) {
      result.x = ledWidth - p.x - 1;
    }
    return result;
  }

  // write passed point data to specified strand and index
  void ledProgramCoordinate(int whichStrand, int ordinal, Point p) {
    if (p.x >= 0) {
      if (isStrandPortSide(whichStrand)) {
        assert p.x < ledWidth / 2 : " invalid x: " + p.x + " for portside strand " + (whichStrand + 1);
      }
      else {
        assert (p.x > ledWidth / 2) || (p.x < ledWidth): " invalid x: " + p.x + " for starboard strand " + (whichStrand + 1);
      }
    }
    assert(whichStrand < getNumStrands()) : "not this many strands";
    assert(ordinal < getStrandSize(whichStrand)) : "whichStrand exceeds number of leds per strand";
    int index = (whichStrand * maxPixelsPerStrand) + ordinal;
    int newIndex = coordToIndex(p);
    // println("LPC: index " + index + " pixelDataIndex " + newIndex);
    strandMap[index] = newIndex;
  }
  
  // write "Unused" data to a strand and index
  void ledProgramMissing(int whichStrand, int ordinal) {
    ledProgramCoordinate(whichStrand, ordinal, indexToCoordinate(TC_PIXEL_UNUSED));
  }


  boolean ledProgramCoordinateOffset(int whichStrand, int startOrdinal, Point delta) {
    int strandSize = getStrandSize(whichStrand);
    for (int i = startOrdinal; i < strandSize; i++) {
      Point point = ledGet(whichStrand, i, false);
      Point originalPoint = (Point)point.clone();
      if (point.x >= 0) {
        point.translate(delta.x, delta.y);
        Point checker = convertDoubleSidedPoint(point, whichStrand);
        if (checker.x < 0 || checker.x >= ledWidth / 2 || checker.y < 0 || checker.y >= ledHeight) {
          println("Cannot offset coordinate: " + i + " " + originalPoint + " -> " + point);
          // Need to unroll the action, because we cannot go off the edge
          for (int j = startOrdinal; j < i; j++) {
            point = ledGet(whichStrand, j, false);
            if (point.x >= 0) {
              point.translate(-delta.x, -delta.y);
              println("unrolling ordinal " + j + " to " + point);
              ledProgramCoordinate(whichStrand, j, point); // Put the point back to where it was before
            }
          }
          return false;
        }
        println("offset ordinal " + i + " originalPoint " + originalPoint + " to " + point);
        ledProgramCoordinate(whichStrand, i, point);
      }
    }
    return true;
  }

  boolean ledProgramOrdinalOffset(int whichStrand, int startOrdinal, int deltaOrdinal) {
    
    println("ledProgramOrdinalOffset() " + deltaOrdinal);
    
    int oldStrandSize = getStrandSize(whichStrand);
    int newStrandSize = oldStrandSize + deltaOrdinal;
    if (newStrandSize > maxPixelsPerStrand || newStrandSize < 0 || deltaOrdinal == 0) {
      return false;
    }

    if (newStrandSize > oldStrandSize) {
      // Strand grows
      strandSizes[whichStrand] = newStrandSize;
      
      // Move existing pixels to new ordinals
      for (int i = oldStrandSize - 1; i >= startOrdinal; i--) {
        Point point = ledGet(whichStrand, i, false);
        ledProgramCoordinate(whichStrand, i + deltaOrdinal, point);
      }
      
      // Set new ordinals to missing pixels
      for (int i = startOrdinal; i < startOrdinal + deltaOrdinal; i++) {
        ledProgramMissing(whichStrand, i);
      }
    }
    else {
      // Strand shrinks
      for (int i = startOrdinal; i < oldStrandSize; i++) {
        Point point = ledGet(whichStrand, i, false);
        ledProgramCoordinate(whichStrand, i + deltaOrdinal, point);
      }

      for(int i = newStrandSize; i < oldStrandSize; i++) {
        ledProgramCoordinate(whichStrand, i, indexToCoordinate(TC_PIXEL_UNDEFINED));
      }

      strandSizes[whichStrand] = newStrandSize;
    }
  
    setupTrainingStrandMap();
    return true;
  }

  
  // int xOffsetter; // TODO: not sure we need the offsetters anymore
  // int yOffsetter;
  // int ordinalOffsetter;
  
  int lowestX = Integer.MAX_VALUE;
  int lowestY = Integer.MAX_VALUE;
  int biggestX = Integer.MIN_VALUE;
  int biggestY = Integer.MIN_VALUE;
  
  // get data for a given strand and index - specify training mode
  Point ledGet(int whichStrand, int ordinal, boolean useTrainingMode) {
    assert whichStrand < getNumStrands() : "not this many strands";
    assert ordinal < getStrandSize(whichStrand) : "ordinal exceeds number of leds per strand";
    int[] map = useTrainingMode?trainingStrandMap:strandMap;
    int index = (whichStrand * maxPixelsPerStrand) + ordinal;
    assert index < map.length : "strand: " + whichStrand + " ordinal: " + ordinal + " goes beyond end of map (" + index + " >= " + map.length + ")";
    int value = map[index];
    return indexToCoordinate(value);
  }
  
  // get data for a given strand and index
  Point ledGet(int whichStrand, int ordinal) {
    return ledGet(whichStrand, ordinal, main.currentMode().isTrainingMode());
  }

  // go back through the strand data we read from disk
  // fill in the missing values  
  void ledInterpolate() {
    int available = 0;
    
    for (int strand = 0; strand < getNumStrands(); strand++) {
      int start = strand * maxPixelsPerStrand;
      int lastIndexWithCoord = -1;
      available = 0;
      int strandSize = getStrandSize(strand);
      for (int i = start; i < start + strandSize; i++) {
        int value = strandMap[i];
        if (value == TC_PIXEL_UNDEFINED) {
          available++;
        }
        else if (value >= 0) {
          
          if (lastIndexWithCoord < 0) {
            
          }
          else {
            Point a = indexToCoordinate(strandMap[lastIndexWithCoord]);
            Point b = indexToCoordinate(value);
            int writable = abs(b.y - a.y) + abs(b.x - a.x) - 1;
            //println ("writable(" + writable + ") = abs(" + b.y + " - " + a.y + ") + abs(" + b.x + " - " + a.x + ")");
            
            if (writable == available) {
              if (!(a.x != b.x && a.y != b.y)) {
                
                int xChange = 0;
                int yChange = 0;
                if (b.x > a.x)
                  xChange = 1;
                else if (b.x < a.x)
                  xChange = -1;
                if (b.y > a.y)
                  yChange = 1;
                else if (b.y < a.y)
                  yChange = -1;
                
                int inc = 0;
                for (int j = lastIndexWithCoord + 1; j < i; j++) {
                  int jVal = strandMap[j];
                  if (jVal == TC_PIXEL_UNDEFINED) {
                    inc++;
                    int x = a.x + inc * xChange;
                    int y = a.y + inc * yChange;
                    strandMap[j] = coordToIndex(new Point(x, y));
                    // println("LI: index " + j + " pixelDataIndex " + strandMap[j]);
                  }
                }
              }
            }
          }
          lastIndexWithCoord = i;
          available = 0;
        }
      }
    }
  }
  
  // dump the strand data we've read from disk for the specified range of strands
  void ledMapDump(int minStrand, int maxStrand) {
    if (maxStrand < minStrand) {
      return;
    }
    
    assert(minStrand < getNumStrands());
    assert(maxStrand < getNumStrands());
    
    for (int whichStrand = minStrand; whichStrand <= maxStrand; whichStrand++) {
      int minX = 10000;
      int minY = 10000;
      int maxX = -10000;
      int maxY = -10000;
      
      println ("strand " + whichStrand);
      int strandSize = getStrandSize(whichStrand);
      StringBuilder s = new StringBuilder(200);
      
      int start = whichStrand  * maxPixelsPerStrand;
      for (int ordinal = 0; ordinal < strandSize; ordinal++) {
        int index = ordinal + start;
        if ((ordinal % 10) == 0)
        {
          println(s);
          s = new StringBuilder(200);
        }
        s.append(String.format(" %04d:", ordinal));
        int value = strandMap[index];
        if (value == TC_PIXEL_DISCONNECTED) {
          s.append(" DISC  ");
        } else if (value == TC_PIXEL_UNUSED) {
          s.append("UNUSED ");
        } else if (value == TC_PIXEL_UNDEFINED) {
          s.append("(??,??)");
        }
        else {
          assert (value >= 0) : "can't print unrecognized value " + value;
          Point p = indexToCoordinate(value);
          s.append(String.format("(%02d,%02d) ", p.x, p.y));
          minX = min(minX, p.x);
          minY = min(minY, p.y);
          maxX = max(maxX, p.x);
          maxY = max(maxY, p.y);
        }
      }
      s.append("\n");
      println(s);
      println("min (" + minX + ", " + minY + ") max ("  + maxX + ", " + maxY + ")");
    }
  }
  
  // is the strand on the port side of the bus?
  boolean isStrandPortSide(int whichStrand) {
    return whichStrand < getNumStrands() / 2;
  }
  
  // get coordinate points for a given strand
  Point[] pointsForStrand(int whichStrand) {
    assert whichStrand < getNumStrands();
    int strandSize = getStrandSize(whichStrand);
    ArrayList<Point> points = new ArrayList<Point>();
    int start = whichStrand * maxPixelsPerStrand;
    for (int ordinal = 0; ordinal < strandSize; ordinal++) {
      int index = ordinal + start;
      int value = strandMap[index];
      if (value >= 0) {
        Point p = indexToCoordinate(value);
        points.add(p);
      }
    }
    return (Point[]) points.toArray(new Point[0]);
  }
  
  TotalControlConsumer totalControlConsumer;
  TotalControlConcurrent totalControlConcurrent;
  boolean hardwareAlreadySetup = false;
  
  // create "training strand" data map
  void setupTrainingStrandMap() {
    int stealPixel = 0;
    for (int whichStrand = 0; whichStrand < getNumStrands(); whichStrand++) {
      int numPixels = getStrandSize(whichStrand);
      int start = whichStrand * maxPixelsPerStrand;
      int boundary = start + numPixels;
      int j;
      for (j = start; j < boundary; j++) {
        trainingStrandMap[j] = stealPixel++;
        Point tester = indexToCoordinate(trainingStrandMap[j]);
        assert(tester.x < ledWidth && trainingStrandMap[j] < pixelData.length) : 
            "Strands have more LEDs than we have pixels to assign them\n" + " x:" + tester.x + " y:" + tester.y + 
            " strand: " + whichStrand + " ordinal:" + (j-start) + " rawValue:" + trainingStrandMap[j];
        
      }
      if (true) {
        int end = start + maxPixelsPerStrand;
        for (; j < end; j++) {
          trainingStrandMap[j] = TC_PIXEL_DISCONNECTED;
        }
      }
    }
  }
  
  // initialize the total control hardware
  void initTotalControl() {
    setupTrainingStrandMap();
    
    for (int i = 0; i < getNumStrands(); i++) {
      readOneStrandFromDisk(i);
    }
    
    ledInterpolate();
//    ledMapDump(2, 7); //set which strands you want to dump
    
    println("" + lowestX + " <= x <= " + biggestX + ", " + lowestY + " <= y <= " + biggestY);
    if (lowestX == 0) {
      println("ERROR: lowest LED should be X == 0, instead of " + lowestX);
    }
    if (lowestY == 0) {
      println ("ERROR: lowest LED should be Y == 0, instead of " + lowestY);
    }
    if ((biggestX + 1) * 2 == ledWidth) {
      println("ERROR: biggest LED should be X == " + (ledWidth / 2) + " instead of " + biggestX);
    }
    if (biggestY + 1 == ledHeight) {
      println("ERROR: biggest LED should be Y == " + ledHeight + " instead of " + biggestY);
    }
    
    if (!useTotalControlHardware) {
      return;
    }
    
    hardwareAlreadySetup = true;
    
    if (runConcurrent) {
      totalControlConcurrent = new TotalControlConcurrent(getNumStrands(), maxPixelsPerStrand, kUseBitBang);
    }
    else {
      totalControlConsumer = new TotalControlConsumer();
      int status = totalControlConsumer.setupTotalControl(getNumStrands(), maxPixelsPerStrand, kUseBitBang);
      if (status != 0) {
        //useTotalControlHardware = false;
        println("Total Control error during initialization " + status);
      }
    }
  }
  
  // This function loads the screen-buffer and sends it to the TotalControl p9813 driver
  void drawToLeds() {
    if (!useTotalControlHardware) {
      return;
    }
    
    if (!hardwareAlreadySetup) {
      initTotalControl();
    }
    
    int[] theStrandMap = main.currentMode().isTrainingMode()?trainingStrandMap:strandMap;
    color[] thePixelData = pixelData;
    //println("sending pixelData: " + pixelData.length + " strandMap: " + theStrandMap.length);
    if (runConcurrent) {
      totalControlConcurrent.put(thePixelData, theStrandMap);
    }
    else {
      int status = totalControlConsumer.writeOneFrame(thePixelData, theStrandMap);
    }
  }
  
  void shutdown() {
    TotalControl.close();
    println("closed TotalControl driver");
  }
  
}
