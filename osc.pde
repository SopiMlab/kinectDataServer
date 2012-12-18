
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

void setupOsc() {
  oscP5 = new OscP5(this, localPort);
  myRemoteLocation = new NetAddress(remoteHost, remotePort);
}

void oscEvent(OscMessage theOscMessage) {

  if (theOscMessage.checkAddrPattern("/save")==true) {
    frameSaving = theOscMessage.get(0).intValue();  
    saving = true;
    return;
  } 
    
  if (theOscMessage.checkAddrPattern("/play")==true) {
    frame = theOscMessage.get(0).intValue();
    return;
  } 
}
void sendPing() {
  OscMessage myMessage = new OscMessage("/ping");
  myMessage.add(K);
  myMessage.add(localPort);
  oscP5.send(myMessage, myRemoteLocation);
}

void sendCoMs() {
  if ( kinectData.coms.size() > 0) {
    OscMessage myMessage = new OscMessage("/com");

    myMessage.add(K);

    String s = "";
    for (COM c: kinectData.coms) {
      s += c.toString();
      s += ",";
    }

    myMessage.add(s);
    myMessage.add(frameCount);
    oscP5.send(myMessage, myRemoteLocation);
  }
}
void sendPCs() {
  byte[] bytes = new byte[1200];
  for (COM c: kinectData.coms) {
    int packect = 0;
    boolean hasData = true;
    while(hasData){
      OscMessage myMessage = new OscMessage("/pc");
      myMessage.add(K);
      myMessage.add(c.id);
      for(int i = 0; i < 1200; i++) bytes[i] = 0;
      int l = c.serializeToBytes(bytes, packect);
      myMessage.add(bytes);
      myMessage.add(l);
      myMessage.add(frameCount);
      oscP5.send(myMessage, myRemoteLocation);
      if(l < 200) hasData = false;
      packect += 1;
    }
  }
}

