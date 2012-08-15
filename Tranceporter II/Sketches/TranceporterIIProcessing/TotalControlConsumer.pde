import TotalControl.*;

/*
 Writes to the p9813 on a separate thread to increase our frame rate
 */

class TotalControlConcurrent implements Runnable {
  private PixelDataAndMapQueue q;
  private int lastError;
  
  TotalControlConcurrent(int numStrands, int pixelsPerStrand) {
    q = new PixelDataAndMapQueue();
    
    lastError = TotalControl.open(numStrands, pixelsPerStrand);
    if(lastError != 0) {
      TotalControl.printError(lastError);
    }
    TotalControl.setGamma(2.4);
    new Thread(this, "TotalControlConcurrent").start();
  }
  
  PixelDataAndMapQueue getQueue() {
    return q;
  }

  int getLastError() {
    return lastError;
  }
  
  void put(int[] strandMap, color[] pixelData) {
    q.put(strandMap,pixelData);
  }
  
  public void run() {
    while(true) {
      PixelDataAndMap dm = q.get();
      //println("dm.pixelData: " + dm.pixelData.length + " dm.strandMap: " + dm.strandMap.length);
      int status = TotalControl.refresh(dm.pixelData, dm.strandMap);
      if(status != lastError) {
        TotalControl.printError(status);
      }
      lastError = status;
      
      if (frameCount % (FRAME_RATE * 3) == 0) {
        TotalControl.printStats();
      }
    }
  }
  
  class PixelDataAndMap {
    color[] pixelData;
    int[] strandMap;
  }
  
  class PixelDataAndMapQueue {
    
    PixelDataAndMap n;
    boolean valueSet = false;
    
    synchronized PixelDataAndMap get() {
      if(!valueSet) {
        try {
          wait();
        } catch(InterruptedException e) {
          System.out.println("InterruptedException caught");
        }
      }
      valueSet = false;
      notify();
      return n;
    }
    
    synchronized void put(int[] strandMap, color[] pixelData) {
      PixelDataAndMap newDM = new PixelDataAndMap();
      newDM.strandMap = strandMap; //strandMap should point to static data
      newDM.pixelData = pixelData.clone(); //pixelData changes each frame
      if(valueSet)
        try {
          wait();
        } catch(InterruptedException e) {
          System.out.println("InterruptedException caught");
        }
      this.n = newDM;
      valueSet = true;
      notify();
    }
  }
}

  
  