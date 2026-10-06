!//------------------------------------------------------------------------------------------
!// Ausgabe aller Systemvariablen. Damit kann man Einstellungen protokollieren.

WriteLine("___________________________________________________________________________");
WriteLine("System Variablen zum Heizkalender\n");

string svVarList = "string _CM_VarList = \"";
string svListStr = "";
string vid;
var svIDs = dom.GetObject(ID_SYSTEM_VARIABLES).EnumIDs();

foreach(vid, svIDs){
    var sysVar = dom.GetObject(vid);
    if (sysVar.Name().StartsWith("_CM_")) {
      if ((!svVarList.EndsWith(";")) && (!svVarList.EndsWith("\""))){
        svVarList = svVarList # ";";
      }
      string name = sysVar.Name()
                .Replace(" ","_")
                .Replace("ß","ss")
                .Replace("ä","ae")
                .Replace("Ä","Ae")
                .Replace("ö","oe")
                .Replace("Ö","Oe")
                .Replace("ü","ue")
                .Replace("Ü","Ue");
      if (sysVar!="_CM_diagrams_"){
        svVarList = svVarList # name;
      }
      svListStr = svListStr # "string " # name # "=" #  "\"" # sysVar.Value() # "\";\n";
    }
}
svVarList = svVarList # "\";";

WriteLine(svVarList);
WriteLine(svListStr);

WriteLine("___________________________________________________________________________");
