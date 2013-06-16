// Class to detect beats
// Original Implementation by Greg Friedland in 2012 based on methods described by Simon Dixon in 
// "ONSET DETECTION REVISITED" Proc. of the 9th Int. Conference on Digital Audio Effects (DAFx-06), Montreal, Canada, September 18-20, 2006
// ( http://www.dafx.ca/proceedings/papers/p_133.pdf )

// re-engineed using logic from Henri David
// http://motscousus.com/stuff/2008-02_Processing.org_patterns/test_beat.pde


import java.util.HashMap;
import ddf.minim.analysis.*;

class BeatDetect {

  CircularArray[] fullSpec;
  boolean[] analyzeBands;
  float[] bandFreqs;
  float[] threshSensitivity;
  long[] lastOnsetTimes;
  int[] beatLength;
  int numBands;
  int historySize;
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

  public float beatSense         = 4;
  public float beatSenseSense    = 1;
  private long lastbeatTimestamp = 0;
  private float level            = 0;
  private float leveldB          = -100;
  private int lastBand           = 0;
  private int lastBandCount      = 0;
  private int nbAverage          = config_SAMPLERATE / config_BUFFERSIZE * 2 / 8 ; // adjusted for our overhead
  private float modulationSmooth = 0.30f;

  private int nbAverageLongTerm  = 8 * config_SAMPLERATE / config_BUFFERSIZE / 8 ; // adjusted for our overhead
  private int nbAverageShortTerm = config_SAMPLERATE / config_BUFFERSIZE / 3 / 8 ; // adjusted for our overhead
  // private int repeatDelay        = (int) ((60f / config_BPM / 4f) * (config_SAMPLERATE / config_BUFFERSIZE));

  public int numZones      = 0;
  public boolean zoneEnabled[];
  private float score2     = 0;
  private float modulation = 0;
  private float[][] zoneEnergy;
  private float[][] zoneEnergyShortTerm;
  private float[][] zoneScore;
  private float[] score         = new float[nbAverage];
  private float[] scoreLongTerm = new float[nbAverageLongTerm];

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
  BeatDetect(FFT fft, int numBands, int historySize) {

    output = createWriter("tranceporter.txt"); 

    // assign arguments to class members
    this.fft          = fft;
    this.historySize  = historySize;
    this.numBands = numBands;

    // create historical data objects
    
    // beatLength tells us how long a beat may last until we call it a new beat
    beatLength        = new int[numBands];

    // threshSensitivity is used to determine whether a band has enough volume to count as a beat
    threshSensitivity = new float[numBands];

    // assign the default values to all bands for now. They can be reset later.
    for (int i=0; i<numBands; i++) {
      beatLength[i]        = BEAT_LENGTH;
    }

    // analyzeBands is an array that tells us whether we care about a given band. 
    // For now they're all set to 'true'    
    analyzeBands = new boolean[numBands];
    for (int i=0; i<numBands; i++) {
        analyzeBands[i] = true;
    }

    // whether this is onset for the band
    isBandOnset = new boolean[numBands];

    lastOnsetTimes = new long[numBands];    

    numZones = fft.avgSize();

    zoneEnergy              = new float[numZones][];
    zoneEnergyShortTerm     = new float[numZones][];
    zoneScore               = new float[numZones][];
    zoneEnabled             = new boolean[numZones];
    
    for (int i = 0; i < numZones; i++) {
      zoneEnergy[i]          = new float[nbAverage];
      zoneScore[i]           = new float[nbAverage];
      zoneEnergyShortTerm[i] = new float[nbAverageShortTerm];
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

  /**
   * Set the FFT Window
   */
  void setFFTWindow() {
    fft.window(FFT.HAMMING);
  }
  
  /**
   * The workhorse method
   * This examines incoming audiobuffer data and decideds whether we are entering or leaving a beat
   * @arg AudioBuffer data the audio data for the moment we're examining
   */
  void update(AudioBuffer data) {

    fft.forward(data);
    
    // update our round robins heads
    int playhead2          = (playhead + 1) % nbAverage;
    int playheadLongTerm2  = (playheadLongTerm + 1) % nbAverageLongTerm;
    int playheadShortTerm2 = (playheadShortTerm + 1) % nbAverageShortTerm;

    int localAvg = 0;

    // loop through all zones
    for (int i = 0; i < numZones; i++) {
      // get energy
      zoneEnergy[i][playhead2] = fft.getAvg(i) * (linearEQIntercept + i * linearEQSlope);
      // System.out.println("ZONE " + i + " got zoneenergy for " + playhead2 + " of " + zoneEnergy[i][playhead2]);

      zoneEnergyShortTerm[i][playheadShortTerm2] = zoneEnergy[i][playhead2];
      // System.out.println(zoneEnergy[i][playhead2]+" "+average(zoneEnergy[i]));

      // compute a per band score
      if (zoneEnergy[i][playhead2] > 0.3 && average(zoneEnergy[i]) > 0.1) {
        zoneScore[i][playhead2] = zoneEnergy[i][playhead2] 
        / average(zoneEnergy[i])
        * zoneEnergyShortTerm[i][playheadShortTerm2]
        / average(zoneEnergyShortTerm[i]);
      }

      else {
        zoneScore[i][playhead2] = 0;
      }

      if (zoneEnabled[i]) {
        // println(zoneEnergy[i][playhead2]);
        localAvg += zoneEnergy[i][playhead2];
        if (zoneScore[i][playhead2] < 100) {
          score[playhead2] += zoneScore[i][playhead2];
        } else {
          score[playhead2] += 100;
        }
        // if(zoneScore[i][playhead2]>25) {
        // System.out.println(zoneScore[i][playhead2]);
        // }
      }
    } // end loop through all zones

    // pitch detect
    float maxE   = 0;
    int bandmaxE = 0;
    int minBand  = 0;
    int thres    = 0;
    for (int i = minBand; i < numZones; i++) {
      if (zoneEnergy[i][playhead2] > maxE && zoneEnabled[i]) {
        bandmaxE = i;
        maxE = zoneEnergy[i][playhead2];
      }
    }

    if (bandmaxE != lastBand) {

      // if (lastBandCount > thres) {
      //     // System.out.print(".\n");
      // }
      lastBandCount = 0;

    } else {

      // if (thres == lastBandCount) {
      //   // System.out.print(bandmaxE+" "+fft.getBandWidth()*bandmaxE+"Hz ");
      //   if (bandmaxE > 0) {
      //     for (int i = 0; i <= bandmaxE; i++) {
      //         // System.out.print("#");
      //     }
      //   }
      // }
      // if (lastBandCount > thres) {
      //     // System.out.print(".");
      // }
      lastBandCount++;
    }
    lastBand = bandmaxE;

    // compute a global score
    int numZoneEnabled = 0;
    for (int ii = 0; ii < numZones; ii++) {
      numZoneEnabled += (zoneEnabled[ii]) ? 1 : 0;
    }
    if (numZoneEnabled == 0) {
      score[playhead2] = 0;
      scoreLongTerm[playheadLongTerm2] = 0;
    } else {
      score[playhead2] = score[playhead2] / numZoneEnabled;
      scoreLongTerm[playheadLongTerm2] = score[playhead2]/ numZoneEnabled;
    }

    // are we on the beat ?
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

    // if (skipFrames > 0) {
    //   skipFrames--;
    // }

    // compute auto beat sense 
    float max = max(score);
    if (max > 30) {
      max = 30;
    }

    // float min = min(score);
    float avg = average(scoreLongTerm);
    if (avg < 1.5) {
      avg = 1.5f;
    }

    if (autoBeatSense && max > 1.1) {
      beatSense = beatSense * 0.995f + 0.002f * max * beatSenseSense + 0.003f * avg * beatSenseSense;
      if (beatSense < 1.1) {
        beatSense = 1.1f;
      }
    }

    // System.out.println(" max:"+max+" min:"+min+" avg:"+avg+" var:"+average(score));

    // make our round robin heads public
    playhead          = playhead2;
    playheadShortTerm = playheadShortTerm2;
    playheadLongTerm  = playheadLongTerm2;

    // int s = second();  // Values from 0 - 59
    // int m = minute();  // Values from 0 - 59
    // int h = hour();    // Values from 0 - 23
    // output.println("TIME: " + h + ":" + m + ":" + s);
    // output.println("max\t" + max + "\tavg\t" + avg + "\tbeatSense\t" + beatSense);
    // output.println("nbAverage\t" + nbAverage + "\tnbAverageShortTerm\t" + nbAverageShortTerm + "\tnbAverageLongTerm\t" + nbAverageLongTerm);

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

