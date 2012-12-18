String settingsFile = "mySettings.txt";
HashMap settings = new HashMap();

String loadSetting(String id, String defaultValue){
  String v = (String)settings.get(id);
  if(v == null) return defaultValue;
  return v; 
}
int loadSetting(String id, int defaultValue){
  String v = (String)settings.get(id);
  if(v == null) return defaultValue;
  return int(v); 
}
boolean loadSetting(String id, boolean defaultValue){
  String v = (String)settings.get(id);
  if(v == null) return defaultValue;
  return boolean(v); 
}

void saveSetting(String id, String value){
  settings.put(id, value);
  saveSettings();
}
void saveSetting(String id, int value){
  settings.put(id, (new Integer(value)).toString());
  saveSettings();
}

void loadSettings(){
  String[] list = loadStrings(settingsFile);
  for(int i = 0; i < list.length; i++){
    String[] tokens = list[i].split(" ");
    settings.put(tokens[0], tokens[1]);
  }
}
void saveSettings(){
  PrintWriter output;
  output = createWriter(settingsFile);
  
  Iterator i = settings.entrySet().iterator();  
  while (i.hasNext()) {
    Map.Entry me = (Map.Entry)i.next();
    output.println(me.getKey() + " " + me.getValue());
  }
}
