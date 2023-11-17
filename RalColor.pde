class RalColor implements Comparable {
  String rgb;
  String cmyk;
  String url;
  boolean dark;
  String ral;
  String nameDE;
  String nameEN;
  String range;
  int rank;
  
  RalColor(String rgb, String cmyk, String url, boolean dark, String ral, String nameDE, String nameEN, String range) {
    this.rgb = rgb;
    this.cmyk = cmyk;
    this.url = url;
    this.dark = dark;
    this.ral = ral;
    this.nameDE = nameDE;
    this.nameEN = nameEN;
    this.range = range;
  }
  
  int difference(String compareRgb) {
    String rs = this.rgb.substring(0,2);
    int r = unhex(rs);
    String gs = this.rgb.substring(2,4);
    int g = unhex(gs);
    String bs = this.rgb.substring(4,6);
    int b = unhex(bs);
    String crs = compareRgb.substring(0,2);
    int cr = unhex(crs);
    String cgs = compareRgb.substring(2,4);
    int cg = unhex(cgs);
    String cbs = compareRgb.substring(4,6);
    int cb = unhex(cbs);
    int diff = abs(r-cr) + abs(g-cg) + abs(b-cb);
    return diff;
  }
  
  public int compareTo(Object c) {
    return rank - ((RalColor)c).rank;
  }
  
  void display() {
    println(nameDE);
  }
}
