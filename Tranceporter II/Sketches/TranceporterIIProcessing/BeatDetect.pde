// Class to detect beats
// Original Implementation by Greg Friedland in 2012 based on methods described by Simon Dixon in 
// "ONSET DETECTION REVISITED" Proc. of the 9th Int. Conference on Digital Audio Effects (DAFx-06), Montreal, Canada, September 18-20, 2006
// ( http://www.dafx.ca/proceedings/papers/p_133.pdf )

// re-engineed using logic from Henri David
// http://motscousus.com/stuff/2008-02_Processing.org_patterns/test_beat.pde


import java.util.HashMap;
import ddf.minim.analysis.*;

class BeatDetect {

  // CircularArray[] fullSpec;   // @REVIEW may be unused
  boolean[] analyzeBands;
  // float[] bandFreqs;   // @REVIEW may be unused
  // float[] threshSensitivity;   // @REVIEW may be unused
  long[] lastOnsetTimes;
  int[] beatLength;
 
  // number of bands we're using 
  int numBands;

  int[] minFrequency;
  int[] maxFrequency;
  int[] minBandIndex;
  int[] maxBandIndex;

  // int historySize;   // @REVIEW may be unused
  FFT fft;

  int BEAT_LENGTH           = 150;

  boolean[] isBandOnset;

  int config_SAMPLERATE        = 44100;
  int config_BUFFERSIZE        = 512;
  int config_BPM               = 140;
  int config_FFT_BAND_PER_OCT  = 12;
  int config_FFT_BASE_FREQ     = 55;
  private boolean scaleEq      = true;
  public boolean onBeat        = false;
  public boolean oscOnBeat     = false;
  public boolean autoBeatSense = true;

  public float beatSense         = 4; // the threshold for beat intensity
  public float beatSenseFloor    = 1.1; // our minimum threshold for beat intensity
  public float beatSenseSense    = 1; // @REVIEW not sure of the purpose - only used as a multiplier
  private long lastbeatTimestamp = 0;
  private float level            = 0;
  private float leveldB          = -100;
  private int lastBand           = 0;
  private int lastBandCount      = 0;

  // private float modulationSmooth = 0.30f; // @REVIEW appears unused

  private int historySize          = config_SAMPLERATE / config_BUFFERSIZE * 2 / 8 ; // adjusted for our overhead
  private int historySizeLongTerm  = 8 * config_SAMPLERATE / config_BUFFERSIZE / 8 ; // adjusted for our overhead
  private int historySizeShortTerm = config_SAMPLERATE / config_BUFFERSIZE / 3 / 8 ; // adjusted for our overhead
  // private int repeatDelay        = (int) ((60f / config_BPM / 4f) * (config_SAMPLERATE / config_BUFFERSIZE));

  // number of specific frequency ranges we're sampling
  public int numZones      = 0;
  public boolean zoneEnabled[];
  private float score2     = 0;
  private float modulation = 0;
  private float[][] zoneEnergy;
  private float[][] zoneEnergyShortTerm;
  private float[][] zoneScore;
  private float[] score         = new float[historySize];
  private float[] scoreLongTerm = new float[historySizeLongTerm];
  private float maxScore        = 100;
  private float maxMaxScore     = 30;
  private float minAvg          = 1.5f;

  private int playhead          = 0;
  private int playheadShortTerm = 0;
  private int playheadLongTerm  = 0;
  private int skipFrames        = 0;

  private float linearEQIntercept = 0.8f; // reduced gain at lowest frequency
  private float linearEQSlope     = 0.2f; // increasing gain at higher frequencies

  PrintWriter output;

  /**
   * BeatDetect Class Constructor Method
   *
   * @arg FFT fft Fast Forier Transform object
   * @arg int numBands number of bands we'll be reading
   * @arg int historySize number of historical data points we keep in memory
   * 
   */
  // @REVIEW historySize may be unused
  BeatDetect(FFT fft, int numBands, int historySize) {

    output = createWriter("tranceporter.txt"); 

    // assign arguments to class members
    this.fft          = fft;
    // this.historySize  = historySize;    // @REVIEW may be unused
    this.numBands = numBands;

    // create historical data objects
    
    // threshSensitivity is used to determine whether a band has enough volume to count as a beat
    // @REVIEW may be unused
    // threshSensitivity = new float[numBands];

    // beatLength tells us how long a beat may last until we call it a new beat
    beatLength        = new int[numBands];
    // assign the default values to all bands for now. They can be reset later.
    for (int i=0; i<numBands; i++) {
      beatLength[i]        = BEAT_LENGTH;
    }

    // define our band frequency min/max in hertz
    minFrequency = new int[numBands];
    maxFrequency = new int[numBands];
    minBandIndex = new int[numBands];
    maxBandIndex = new int[numBands];
    // this is kind of awful, but for now it's what we're doing
    // This should stay fairly stable
    minFrequency[0] = 16; // lowest audible
    maxFrequency[0] = 250; 
    minFrequency[1] = 251; 
    minFrequency[1] = 523; // lowest note for a piccolo
    minFrequency[2] = 524;
    minFrequency[2] = 16000; // highest audible

    // analyzeBands is an array that tells us whether we care about a given band. 
    // For now they're all set to 'true'    
    analyzeBands = new boolean[numBands];
    for (int i=0; i<numBands; i++) {
        analyzeBands[i] = true;
    }

    // whether this is onset for the band
    isBandOnset = new boolean[numBands];

    // the last time this band had an onset (in milliseconds)
    lastOnsetTimes = new long[numBands];    

    // the number of averages currently being calculated - the sub-bands
    numZones = fft.avgSize();

    // create data structures to hold sound data for each our our zones
    zoneEnergy              = new float[numZones][];
    zoneEnergyShortTerm     = new float[numZones][];
    zoneScore               = new float[numZones][];
    zoneEnabled             = new boolean[numZones];
    
    // loop through all our zones
    // create data structures to hold sound data for our bands/sub-zones
    for (int i = 0; i < numZones; i++) {
      zoneEnergy[i]          = new float[historySize];
      zoneScore[i]           = new float[historySize];
      zoneEnergyShortTerm[i] = new float[historySizeShortTerm];
      zoneEnabled[i]         = true;
    }
  }

  /**
   * Set the object's thresholdSensititivy and beatLength for the given band
   *
   * @arg int band  the band we're setting values for
   * @arg int beatLength    The beat length to set
   */
  void setBeatLength(int band, int beatLength) {
    this.beatLength[band] = beatLength;
  }

  // @REVIEW now done in TranceporterIIProcessing.pde where we create the fft object
  /**
   * Set the FFT Window
   */
  // void setFFTWindow() {
  //   fft.window(FFT.HAMMING);
  // }
  
  /**
   * The workhorse method
   * This examines incoming audiobuffer data and decideds whether we are entering or leaving a beat
   * @arg AudioBuffer data the audio data for the moment we're examining
   */
  void update(AudioBuffer data) {

    fft.forward(data);
    
    // update our round-robin heads - 
    // these track where in our history arrays structures we currently are
    // the counter wraps to zero at the end of our history length 
    // the "2" values represent the current value
    // the non-2 values represent the previous iteration
    int playhead2          = (playhead + 1) % historySize;
    int playheadLongTerm2  = (playheadLongTerm + 1) % historySizeLongTerm;
    int playheadShortTerm2 = (playheadShortTerm + 1) % historySizeShortTerm;

    int localAvg = 0;

    // loop through all zones/sub-bands
    for (int i = 0; i < numZones; i++) {

      // get energy for band - adjusted for eqIntercept and eqSlope
      zoneEnergy[i][playhead2] = fft.getAvg(i) * (linearEQIntercept + i * linearEQSlope);
      // System.out.println("ZONE " + i + " got zoneenergy for " + playhead2 + " of " + zoneEnergy[i][playhead2]);

      // set the short-term zone energy to that value
      zoneEnergyShortTerm[i][playheadShortTerm2] = zoneEnergy[i][playhead2];
      // System.out.println(zoneEnergy[i][playhead2]+" "+average(zoneEnergy[i]));

      // if the current energy value is inside some random range...
      // compute a per-zone/sub-band score
      if (zoneEnergy[i][playhead2] > 0.3 && average(zoneEnergy[i]) > 0.1) {
        zoneScore[i][playhead2] = 
            (zoneEnergy[i][playhead2] / average(zoneEnergy[i]) )
            * 
            (zoneEnergyShortTerm[i][playheadShortTerm2] / average(zoneEnergyShortTerm[i]) );
      }
      // otherwise zero the score
      else {
        zoneScore[i][playhead2] = 0;
      }

      // if the zone is enabled...
      if (zoneEnabled[i]) {
        // println(zoneEnergy[i][playhead2]);

        // increment the localAvg value
        localAvg += zoneEnergy[i][playhead2];

        // if the zone score is less than the maximum, increment the score by that much
        if (zoneScore[i][playhead2] < maxScore) {
          score[playhead2] += zoneScore[i][playhead2];
        } else {
          // otherwise, increment by maxScore
          score[playhead2] += maxScore;
        }

        // if(zoneScore[i][playhead2]>25) {
        // System.out.println(zoneScore[i][playhead2]);
        // }
      }
    } // end loop through all zones

    // pitch detect
    float maxEnergy   = 0;
    int maxEnergyZone = 0;
    int firstZone     = 0;
    // int thres    = 0; // @REVIEW appears to be unused
    for (int i = firstZone; i < numZones; i++) {
      if (zoneEnergy[i][playhead2] > maxEnergy && zoneEnabled[i]) {
        maxEnergyZone = i;
        maxEnergy = zoneEnergy[i][playhead2];
      }
    }

    // @REVIEW - this entire block appears to only be used for printing/debugging
    // if (maxEnergyZone != lastBand) {
    //
    //   if (lastBandCount > thres) {
    //       // System.out.print(".\n");
    //   }
    //   lastBandCount = 0;
    //
    // } else {
    //   // otherwise, increment the band count
    //
    //   if (thres == lastBandCount) {
    //     // System.out.print(maxEnergyZone+" "+fft.getBandWidth()*maxEnergyZone+"Hz ");
    //     if (maxEnergyZone > 0) {
    //       for (int i = 0; i <= maxEnergyZone; i++) {
    //           System.out.print("#");
    //       }
    //     }
    //   }
    //   if (lastBandCount > thres) {
    //       System.out.print(".");
    //   }
    //   lastBandCount++;
    // }
    // lastBand = maxEnergyZone;

    // compute a global score

    // first calculate the number of zones we have enabled
    // @REVIEW - why do we do this every time? It should remain constant
    int numZoneEnabled = 0;
    for (int ii = 0; ii < numZones; ii++) {
      numZoneEnabled += (zoneEnabled[ii]) ? 1 : 0;
    }

    // this is where we need to set score and scoreLongTerm for each band

    // if we don't have enabled zones, set the score and long-term score to 0
    if (numZoneEnabled == 0) {
      score[playhead2] = 0;
      scoreLongTerm[playheadLongTerm2] = 0;
    } else {
      // if we have enabled zones, set the score/longTermScore to averages instead of sums
      score[playhead2] = score[playhead2] / numZoneEnabled;
      scoreLongTerm[playheadLongTerm2] = score[playhead2]/ numZoneEnabled;
    }

    // are we on the beat?
    // first determine if our score exceeds our beatSenseThreshold
    // this used "skipframes" to induce a delay in the original code,
    // but that code doesn't have our overhead and runs much faster, so we don't really need it
    // if (skipFrames <= 0 && score[playhead2] > beatSense) {
    if (score[playhead2] > beatSense) {

      // if we weren't already on the beat, this is the onset
      if(!onBeat) {
        for(int i=0;i<numBands;i++) {
          if(isBandOnset[i]) { 
            isBandOnset[i] = false;
          } else {
            isBandOnset[i] = true;
          }
        }
      }

      onBeat = true;
      // skipFrames = repeatDelay;
    }
    else {
      for(int i=0;i<numBands;i++) {
        isBandOnset[i] = false;
      }
      onBeat = false;
    }

    // @REVIEW unused
    // if (skipFrames > 0) {
    //   skipFrames--;
    // }

    // find the highest score we found this round (with ceiling)
    float max = max(score);
    if (max > maxMaxScore) {
      max = maxMaxScore;
    }

    // float min = min(score); // @REVIEW used only for debugging
    // find the average score we've had in the long-term with ceiling
    float avg = average(scoreLongTerm);
    if (avg < minAvg) {
      avg = minAvg;
    }

    // if we're using autoBeatSense our and max is greater than some arbitrary value...
    // update our beatSense threshhold to take our recent max into account
    if (autoBeatSense && max > beatSenseFloor) {
      beatSense = beatSense * 0.995f + 0.002f * max * beatSenseSense + 0.003f * avg * beatSenseSense;

      // beatSense has a minimum value
      if (beatSense < beatSenseFloor) {
        beatSense = beatSenseFloor;
      }
    }

    // System.out.println(" max:"+max+" min:"+min+" avg:"+avg+" var:"+average(score));

    // we're all done - update our round-robin playheads to match each other 
    playhead          = playhead2;
    playheadShortTerm = playheadShortTerm2;
    playheadLongTerm  = playheadLongTerm2;

    // int s = second();  // Values from 0 - 59
    // int m = minute();  // Values from 0 - 59
    // int h = hour();    // Values from 0 - 23
    // output.println("TIME: " + h + ":" + m + ":" + s);
    // output.println("max\t" + max + "\tavg\t" + avg + "\tbeatSense\t" + beatSense);
    // output.println("historySize\t" + historySize + "\thistorySizeShortTerm\t" + historySizeShortTerm + "\thistorySizeLongTerm\t" + historySizeLongTerm);

    // output.println("skipFrames " + skipFrames + " left of " + repeatDelay);
    // output.println("threshold : "     + this.beatSense);
    // output.println("current score : " + score[playhead2]);
    // output.println("on Beat :"        + this.onBeat);
    // output.flush(); // Writes the remaining data to the file

    // System.out.println("TIME: " + h + ":" + m + ":" + s);
    // System.out.println("threshold : "     + this.beatSense);
    // System.out.println("current score : " + score[playhead2]);
    // System.out.println("on Beat :"        + this.onBeat);

    // set all our bands to this band's value
    for (int i=0; i< main.NUM_BANDS; i++) {
      if(onBeat) {
        int myMillis = millis();
        lastOnsetTimes[i] = myMillis;
      }
    }
  }
  
  /**
   * Set the "analyzeBands" flag for the given band
   * @arg int band the band to set the value for
   * @arg boolean the value to set
   */
  void analyzeBand(int band, boolean on) { 
    analyzeBands[band] = on; 
  }
  
  // unused
  // double getMetric(String type, int band, int index) {
  //   return getArray("metric", type, band).get(index);
  // }
  
  // unused
  // double getMetricMean(String type, int band, int index) {
  //   return getArrayAvgs("metric", type, band).getEMA1(index);
  // }
  
  // unused
  // double getThreshold(String type, int band, int index) {
  //   return getArray("threshold", type, band).get(index);
  // }
  
  // unused
  // double getMetricMax(String type, int band) {
  //   return getArray("metric", type, band).maxVal();
  // }
  
  /**
   * Get the onset history value for the type, band and index
   */
  boolean isOnset(String type, int band, int index) {
    // return getArray("onsetHist", type, band).get(index) == 1;
    return isBandOnset[band];
  }
    
  /**
   * Is the given type and band currently in a beat
   */
  boolean isBeat(String type, int band) { 
    return (millis() - lastOnsetTimes[band]) < beatLength[band]; 
  }

  /**
   * Where in the beat are we? How long as this beat been going on?
   * Will be a value between 0 and 1. Some mathemagic is done to stir the values up a bit
   */
  float beatPos(String type, int band) {
    float diff = (millis() - lastOnsetTimes[band]) / float(beatLength[band]);
    if (diff <= 1) { 
      // println("Band " + band + " Got diff  " + diff + " from millis " + millis() + " lOT: " + lastOnsetTimes[band] + " bl: " + beatLength[band]);
      float val = sin(diff*PI/2);
      //float val = 1 - abs(diff-0.5) * 2; //exp(-pow(diff - 0.5, 2.0)*25);
      // println("Returning val " + val + " from diff " + diff);
      return val;
    }
    else {
      return 0;
    }
  }
  
  /**
   * Where in the beat are we? How long as this beat been going on?
   * Will be a value between 0 and 1. The raw value is returned without any math performed
   */
  float beatPosSimple(String type, int band) {
    float diff = (millis() - lastOnsetTimes[band]) / float(beatLength[band]);
    if (diff <= 1) return diff;
    else return 0;
  }

  // ///////////////// New Stuff
  // method average
  private float average(float[] array) {
    float sum = 0;
    for (int i = 0; i < array.length; i++) {
      sum += array[i];
    }
    return (sum / array.length);
  } // end method average

  // method sum
  private float[] sum(float[] array, float[] array2) {
    float[] array3 = new float[array.length];
    for (int i = 0; i < array.length; i++) {
      array3[i] += array[i] + array2[i];
    }
    return (array3);
  } // end method sum

}

