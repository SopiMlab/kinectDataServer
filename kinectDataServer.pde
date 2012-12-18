import SimpleOpenNI.*;
SimpleOpenNI context;

float  zoomF =0.15f;
float  rotX = radians(180);                        
float  rotY = radians(0);
PVector[] realWorldMap;
int[]   depthMap;
int userCount;
int[] userMap;

int K; 
int frame = 0, maxFrame = 0;
int frameSaving = 0;

color[]   userColors = { 
  color(255, 0, 0), 
  color(0, 255, 0), 
  color(0, 0, 255), 
  color(255, 255, 0), 
  color(255, 0, 255), 
  color(0, 255, 255)
};

int   steps;  
KinectData kinectData;

String remoteHost;
int remotePort, localPort;
String folder;
boolean bSendCOMData, bSendPCData, bOnline;

boolean saving = false;

PFont font; 
String msg = "";

void setup()
{

  loadSettings();
  K = loadSetting("KINECT_ID", 0);
  remoteHost = loadSetting("REMOTE_HOST", "localhost");
  localPort = loadSetting("LOCAL_PORT", 12000);
  remotePort = loadSetting("REMOTE_PORT", 12000);
  steps = loadSetting("STEPS", 6);
  bSendCOMData =  loadSetting("SEND_COM_DATA", true);
  bSendPCData =  loadSetting("SEND_PC_DATA", true);
  bOnline =  loadSetting("ONLINE", true);
  folder =  loadSetting("FOLDER", "");
  maxFrame =  loadSetting("N_FRAMES", 0);

  size(800, 600, P3D);

  if (bOnline)
    setupKinect();

  perspective(radians(45), 
  float(width)/float(height), 
  10, 150000);

  setupOsc();

  kinectData = new KinectData();

  font = loadFont("mono.vlw");
  textFont(font);
}

void draw()
{
  background(0, 0, 0);

  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);
  translate(0, 0, -2000);
  
  kinectData.resetState();
  if (bOnline) {
    context.update();
    depthMap = context.depthMap();

    processAndDrawRawData();

    context.drawCamFrustum();

    if (saving) {
      String fileName = "snapshot_" + frameSaving + ".ply";
      kinectData.saveFrame(fileName);
      msg = "Saved " + fileName;
      saving = false;
    }
  }
  else {
    String fileName = folder + frame + ".ply";
    try{
      BufferedReader reader = createReader(fileName);    
      if(reader != null){
        processAndDrawFileData(reader);
        reader.close();
      }
    } 
    catch (IOException e) {
      println(fileName + " do not exist");
    }
  }
  
  kinectData.drawCoM();
  
  if (frameCount % 30 == 0) sendPing(); 
  if (bSendCOMData) sendCoMs();
  if (bSendPCData) sendPCs();

  textMode(SCREEN);
  fill(255);
  textSize(12);
  text("[ONLINE] "+ bOnline + " FPS " + frameRate, 10, 10);
  text("Kinect ID " + K, 10, 25);
  if(!bOnline)
    text("folder" + folder + "" + frame + "/" + maxFrame, 10, 40);
  text("Local host " + oscP5.ip() + " " + oscP5.properties().listeningPort(), 10, 55);
  text("Remote host " + remoteHost + " " + remotePort, 10, 70);
  text("Detail  [a/q] " + steps, 10, 85);
  text("Sending Com data [c]: " + bSendCOMData + " nCOMS: " + kinectData.getNumberCOMS(), 10, 100); 
  text("Sending Point Cloud [k]: " + bSendPCData, 10, 115); 
  text(msg, 10, 130);
}

void keyPressed()
{
  if (key == 'k') bSendPCData = !bSendPCData;
  if (key == 'c') bSendCOMData = !bSendCOMData;
  if (key == 'q') {
    steps += 1;
    saveSetting("STEP", steps);
  }
  if (key == 'a') {
    steps -= 1;
    saveSetting("STEP", steps);
  }
  switch(keyCode)
  {
  case LEFT:
    rotY += 0.1f;
    break;
  case RIGHT:
    // zoom out
    rotY -= 0.1f;
    break;
  case UP:
    if (keyEvent.isShiftDown())
      zoomF += 0.02f;
    else
      rotX += 0.1f;
    break;
  case DOWN:
    if (keyEvent.isShiftDown())
    {
      zoomF -= 0.02f;
      if (zoomF < 0.01)
        zoomF = 0.01;
    }
    else
      rotX -= 0.1f;
    break;
  }
}

void processAndDrawRawData() {
 

  realWorldMap = context.depthMapRealWorld();
  userCount = context.getNumberOfUsers();
  userMap = null;
  if (userCount > 0)
    userMap = context.getUsersPixels(SimpleOpenNI.USERS_ALL);

  for (int y=0;y < context.depthHeight();y+=steps)
  {
    for (int x=0;x < context.depthWidth();x+=steps)
    {
      int index = x + y * context.depthWidth();
      if (depthMap[index] > 0)
      { 
        PVector realWorldPoint = context.depthMapRealWorld()[index];
        if (userMap != null && userMap[index] != 0) {
          int userIndex = userMap[index];
          stroke(userColors[userIndex % userColors.length]); 
          point(realWorldPoint.x, realWorldPoint.y, realWorldPoint.z);
          kinectData.addPoint(userIndex, realWorldPoint);
        }
      }
    }
  }
}
void processAndDrawFileData(BufferedReader reader) {
  String line = null;
  try {
      line = reader.readLine();
    } 
    catch (IOException e) {
      println(line);
  }
  while (!line.equals ("end_header")) {
    try {
      line = reader.readLine();
    } 
    catch (IOException e) {
    }
  }
  while (line !=null) {
    try {
      line = reader.readLine();
    } 
    catch (IOException e) {
      line = null;
      
    }
    if(line == null) break;
    String[] pieces = split(line, " ");
    PVector p = new PVector(float(pieces[0]), 
                float(pieces[1]), 
                float(pieces[2]));
    int idx = int(pieces[3]);
    stroke(userColors[idx % userColors.length]); 
    kinectData.addPoint(idx, p);
    point(p.x, p.y, p.z);
  }
}

