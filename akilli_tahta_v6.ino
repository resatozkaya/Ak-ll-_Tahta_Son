// =============================================================
//  AKILLI TAHTA v6.0
//  WiFi AP + HTTP + BLE + Serial + IR
//  ─────────────────────────────────────────────────────────────
//  WiFi  : "AkilliTahta-AP" / sifre: 12345678 / IP: 192.168.4.1
//  BLE   : "AkilliTahta" (flutter_blue_plus ile baglanir)
//  ─────────────────────────────────────────────────────────────
//  YENİ v6 komutları:
//    delText       : metin sil  {"delText":2}
//    moveText      : sirala     {"moveText":{"from":0,"to":3}}
//    clearTexts    : hepsini sil {"clearTexts":true}
//    saveTexts     : sadece metinleri EEPROM'a yaz {"saveTexts":true}
//    saveAll       : her seyi yaz {"saveAll":true}
//    factoryReset  : fabrika sifirla {"factoryReset":true}
//    playInterval  : playlist gecis suresi (sn) {"playInterval":5}
//    figureMode    : ozel figur 0-11 {"figureMode":1}
//    sceneMode     : sahne modu 0-7 {"sceneMode":2}
//    fxSpeed       : efekt hizi 1-100 {"fxSpeed":60}
//    fxIntensity   : efekt yogunlugu {"fxIntensity":50}
//    figureSize    : figur boyutu 1-8 {"figureSize":3}
// =============================================================

#include <Adafruit_GFX.h>
#include <Adafruit_NeoMatrix.h>
#include <Adafruit_NeoPixel.h>
#include <IRremote.hpp>
#include <Preferences.h>
#include <WiFi.h>
#include <WebServer.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define LED_PIN  23
#define IR_PIN   22
#define MW       30
#define MH       20

const char* AP_SSID = "AkilliTahta-AP";
const char* AP_PASS = "12345678";

Adafruit_NeoMatrix matrix(
  MH, MW, LED_PIN,
  NEO_MATRIX_BOTTOM + NEO_MATRIX_LEFT +
  NEO_MATRIX_COLUMNS + NEO_MATRIX_PROGRESSIVE,
  NEO_GRB + NEO_KHZ800
);

WebServer server(80);

// ─── BLE ─────────────────────────────────────────────────────
#define SVC_UUID  "12345678-1234-1234-1234-123456789abc"
#define CMD_UUID  "12345678-1234-1234-1234-123456789ab0"
#define STS_UUID  "12345678-1234-1234-1234-123456789ab1"
BLEServer*         bleServer = nullptr;
BLECharacteristic* cmdChar   = nullptr;
BLECharacteristic* stsChar   = nullptr;
bool               bleCon    = false;
String             bleCmd    = "";
bool               bleNew    = false;

// ─── IR ──────────────────────────────────────────────────────
const uint32_t IR_CH_M=0xBA45FF00,IR_CH=0xB946FF00,IR_CH_P=0xB847FF00;
const uint32_t IR_PRV=0xBB44FF00,IR_NXT=0xBF40FF00,IR_PLY=0xBC43FF00;
const uint32_t IR_VM=0xF807FF00,IR_VP=0xEA15FF00,IR_EQ=0xF609FF00;
const uint32_t IR_0=0xE916FF00,IR_FM=0xE619FF00,IR_FP=0xF20DFF00;
const uint32_t IR_1=0xF30CFF00,IR_2=0xE718FF00,IR_3=0xA15EFF00;
const uint32_t IR_4=0xF708FF00,IR_5=0xE31CFF00,IR_6=0xA55AFF00;
const uint32_t IR_7=0xBD42FF00,IR_8=0xAD52FF00,IR_9=0xB54AFF00;

// ─── METİN LİSTESİ ───────────────────────────────────────────
#define MAX_CUSTOM 16   // v5: 8 → v6: 16 (daha fazla metin)
String customTexts[MAX_CUSTOM] = {
  "TOPRAKSIZ MARKET ","HIDROPONIK SET ","TOPRAKSIZ TARIM ",
  "BESIN COZUMU ","HOBI SETLERI ","DIKEY KULE ",
  "BALKONDA URET ","MUTFAKTA TUKET "
};
uint8_t textCount = 8;

// ─── ENUM'lar ────────────────────────────────────────────────
enum TextAnim   : uint8_t { TA_SCROLL=0,TA_BLINK=1,TA_WAVE=2,TA_RAINBOW=3,TA_GLOW=4,TA_TYPING=5 };
enum BorderAnim : uint8_t { BA_NONE=0,BA_SOLID=1,BA_CHASE=2,BA_RAINBOW=3,BA_PULSE=4,BA_SNAKE=5,BA_SPARKLE=6,BA_GRADIENT=7 };
enum BgFill     : uint8_t { BG_OFF=0,BG_SOLID=1,BG_RAINBOW=2,BG_TWINKLE=3,BG_MATRIX=4,BG_FIRE=5,BG_WAVE=6,BG_STARS=7 };
enum Orient     : uint8_t { OR_H=0,OR_V_UP=1,OR_V_DOWN=2 };

// ─── DEĞIŞKENLER ─────────────────────────────────────────────
Preferences prefs;
uint8_t  brightness=160; bool blackout=false;
int      scrollSpeed=40; Orient orient=OR_H; int8_t dirLR=-1;
uint8_t  baseHue=0; uint8_t textSize=1; int textY=6;
uint8_t  rotSteps=0; bool playlistMode=false;
uint8_t  activeIdx=0; String activeText=customTexts[0];
int16_t  textX=0,textW=0;
TextAnim   textAnim=TA_SCROLL;
BorderAnim borderAnim=BA_NONE;
uint8_t  borderHue=0,borderWidth=1;
BgFill   bgFill=BG_OFF;
uint32_t lastStep=0; uint16_t frame=0;
uint8_t  chasePos=0,snakePos=0;
static uint8_t twR[MH][MW]={},twG[MH][MW]={},twB[MH][MW]={};
static uint8_t mDropY[MW]={},mDropL[MW]={},mDropS[MW]={};
static uint8_t fireG[MH+2][MW]={};
String serialBuf="";

// ─── v6 YENİ DEĞİŞKENLER ─────────────────────────────────────
uint8_t  figureMode=0;    // 0=yok 1=kalp 2=yildiz 3=hexpetek 4=spiral...
uint8_t  sceneMode=0;     // hazir sahne modu
uint8_t  playInterval=5;  // playlist gecis suresi (saniye)
uint8_t  fxSpeed=50;
uint8_t  fxIntensity=50;
uint8_t  figureSize=3;
uint32_t lastPlayMs=0;

// ─── RENK ────────────────────────────────────────────────────
uint16_t hsv(uint8_t h,uint8_t s=255,uint8_t v=255){
  h=255-h;
  if(h<85) return matrix.Color((uint8_t)((255-h*3)*v/255),0,(uint8_t)(h*3*v/255));
  if(h<170){h-=85;return matrix.Color(0,(uint8_t)(h*3*v/255),(uint8_t)((255-h*3)*v/255));}
  h-=170;return matrix.Color((uint8_t)(h*3*v/255),(uint8_t)((255-h*3)*v/255),0);
}
void hsv3(uint8_t h,uint8_t&r,uint8_t&g,uint8_t&b){uint16_t c=hsv(h);r=(c>>16)&0xFF;g=(c>>8)&0xFF;b=c&0xFF;}

// ─── ARKAPLAN ────────────────────────────────────────────────
void drawBg(){
  if(bgFill==BG_OFF) return;
  if(bgFill==BG_SOLID){
    uint16_t c=hsv(baseHue);uint8_t r=(((c>>16)&0xFF)*200)/255,g=(((c>>8)&0xFF)*200)/255,b=((c&0xFF)*200)/255;
    matrix.fillRect(borderWidth,borderWidth,MW-2*borderWidth,MH-2*borderWidth,matrix.Color(r,g,b));return;
  }
  if(bgFill==BG_RAINBOW){
    for(int x=borderWidth;x<MW-borderWidth;x++){
      uint16_t c=hsv((baseHue+x*6+frame)&0xFF);uint8_t r=(c>>16)&0xFF,g=(c>>8)&0xFF,b=c&0xFF;
      for(int y=borderWidth;y<MH-borderWidth;y++) matrix.drawPixel(x,y,matrix.Color(r,g,b));
    }return;
  }
  if(bgFill==BG_TWINKLE){
    for(int y=0;y<MH;y++) for(int x=0;x<MW;x++){twR[y][x]=(twR[y][x]*220)/255;twG[y][x]=(twG[y][x]*220)/255;twB[y][x]=(twB[y][x]*220)/255;}
    for(int i=0;i<4;i++){int x=random(borderWidth,MW-borderWidth),y=random(borderWidth,MH-borderWidth);uint8_t r,g,b;hsv3((baseHue+random(255))&0xFF,r,g,b);twR[y][x]=r;twG[y][x]=g;twB[y][x]=b;}
    for(int y=0;y<MH;y++) for(int x=0;x<MW;x++) matrix.drawPixel(x,y,matrix.Color(twR[y][x],twG[y][x],twB[y][x]));return;
  }
  if(bgFill==BG_MATRIX){
    for(int x=0;x<MW;x++){if((frame%mDropS[x])==0)mDropY[x]=(mDropY[x]+1)%MH;for(int i=0;i<mDropL[x];i++){int y=(mDropY[x]-i+MH)%MH;matrix.drawPixel(x,y,matrix.Color(0,255-((i*255)/mDropL[x]),0));}}return;
  }
  if(bgFill==BG_FIRE){
    for(int x=0;x<MW;x++) fireG[MH+1][x]=random(160,255);
    for(int y=0;y<MH+1;y++) for(int x=0;x<MW;x++){int v=(int)fireG[y+1][x]+(int)fireG[y+1][(x-1+MW)%MW]+(int)fireG[y+1][(x+1)%MW]+(int)fireG[y][x];v=v/4-random(0,6);fireG[y][x]=(uint8_t)(v<0?0:v);}
    for(int y=0;y<MH;y++) for(int x=0;x<MW;x++){uint8_t v=fireG[y][x];matrix.drawPixel(x,(MH-1)-y,matrix.Color(min(255,v*2),(v>128)?(v-128)*2:0,0));}return;
  }
  if(bgFill==BG_WAVE){
    for(int x=borderWidth;x<MW-borderWidth;x++){int cy=(MH/2)+(int)(sin((x+frame)*0.4f)*((MH/2)-borderWidth-1));for(int w=-1;w<=1;w++){int y=cy+w;if(y>=borderWidth&&y<MH-borderWidth)matrix.drawPixel(x,y,hsv((baseHue+x*8+frame)&0xFF));}}return;
  }
  if(bgFill==BG_STARS){for(int i=0;i<3;i++){int x=random(borderWidth,MW-borderWidth),y=random(borderWidth,MH-borderWidth);uint8_t v=random(100,255);matrix.drawPixel(x,y,matrix.Color(v,v,v));}return;}
}

// ─── ÇERÇEVE ─────────────────────────────────────────────────
void drawBorder(){
  if(borderAnim==BA_NONE||borderWidth==0) return;
  int perimeter=2*(MW+MH)-4;
  for(int bw=0;bw<borderWidth;bw++){
    int pos=0;
    for(int x=bw;x<MW-bw;x++){
      uint16_t c=0;
      if(borderAnim==BA_SOLID) c=hsv(borderHue);
      else if(borderAnim==BA_CHASE) c=(pos==chasePos%perimeter)?0xFFFF:hsv(borderHue,255,50);
      else if(borderAnim==BA_RAINBOW) c=hsv((borderHue+pos*4+frame*2)&0xFF);
      else if(borderAnim==BA_PULSE){uint8_t v=(uint8_t)(128+127*sin(frame*0.08f));c=hsv(borderHue,255,v);}
      else if(borderAnim==BA_SNAKE) c=(abs(pos-snakePos%perimeter)<4)?hsv((borderHue+frame)&0xFF):0;
      else if(borderAnim==BA_SPARKLE) c=(random(20)==0)?0xFFFF:hsv(borderHue,255,80);
      else if(borderAnim==BA_GRADIENT) c=hsv((borderHue+pos*255/perimeter)&0xFF);
      matrix.drawPixel(x,bw,c);pos++;
    }
    for(int y=bw+1;y<MH-bw;y++){
      uint16_t c=0;
      if(borderAnim==BA_SOLID) c=hsv(borderHue);
      else if(borderAnim==BA_CHASE) c=(pos==chasePos%perimeter)?0xFFFF:hsv(borderHue,255,50);
      else if(borderAnim==BA_RAINBOW) c=hsv((borderHue+pos*4+frame*2)&0xFF);
      else if(borderAnim==BA_PULSE){uint8_t v=(uint8_t)(128+127*sin(frame*0.08f));c=hsv(borderHue,255,v);}
      else if(borderAnim==BA_SNAKE) c=(abs(pos-snakePos%perimeter)<4)?hsv((borderHue+frame)&0xFF):0;
      else if(borderAnim==BA_SPARKLE) c=(random(20)==0)?0xFFFF:hsv(borderHue,255,80);
      else if(borderAnim==BA_GRADIENT) c=hsv((borderHue+pos*255/perimeter)&0xFF);
      matrix.drawPixel(MW-1-bw,y,c);pos++;
    }
    for(int x=MW-2-bw;x>=bw;x--){
      uint16_t c=0;
      if(borderAnim==BA_SOLID) c=hsv(borderHue);
      else if(borderAnim==BA_CHASE) c=(pos==chasePos%perimeter)?0xFFFF:hsv(borderHue,255,50);
      else if(borderAnim==BA_RAINBOW) c=hsv((borderHue+pos*4+frame*2)&0xFF);
      else if(borderAnim==BA_PULSE){uint8_t v=(uint8_t)(128+127*sin(frame*0.08f));c=hsv(borderHue,255,v);}
      else if(borderAnim==BA_SNAKE) c=(abs(pos-snakePos%perimeter)<4)?hsv((borderHue+frame)&0xFF):0;
      else if(borderAnim==BA_SPARKLE) c=(random(20)==0)?0xFFFF:hsv(borderHue,255,80);
      else if(borderAnim==BA_GRADIENT) c=hsv((borderHue+pos*255/perimeter)&0xFF);
      matrix.drawPixel(x,MH-1-bw,c);pos++;
    }
    for(int y=MH-2-bw;y>bw;y--){
      uint16_t c=0;
      if(borderAnim==BA_SOLID) c=hsv(borderHue);
      else if(borderAnim==BA_CHASE) c=(pos==chasePos%perimeter)?0xFFFF:hsv(borderHue,255,50);
      else if(borderAnim==BA_RAINBOW) c=hsv((borderHue+pos*4+frame*2)&0xFF);
      else if(borderAnim==BA_PULSE){uint8_t v=(uint8_t)(128+127*sin(frame*0.08f));c=hsv(borderHue,255,v);}
      else if(borderAnim==BA_SNAKE) c=(abs(pos-snakePos%perimeter)<4)?hsv((borderHue+frame)&0xFF):0;
      else if(borderAnim==BA_SPARKLE) c=(random(20)==0)?0xFFFF:hsv(borderHue,255,80);
      else if(borderAnim==BA_GRADIENT) c=hsv((borderHue+pos*255/perimeter)&0xFF);
      matrix.drawPixel(bw,y,c);pos++;
    }
  }
  if(frame%2==0) chasePos++;
  if(frame%3==0) snakePos++;
}

// ─── v6 ÖZEL FİGÜRLER ────────────────────────────────────────
// cx,cy: merkez   sz: boyut (1-4)   hue: renk
void drawHeart(int cx,int cy,int sz,uint8_t hue){
  // Kalp: iki daire + alt üçgen
  uint16_t c=hsv(hue);
  for(int dy=-sz;dy<=sz;dy++) for(int dx=-sz*2;dx<=sz*2;dx++){
    float nx=(float)dx/sz, ny=(float)dy/sz;
    // Kalp formülü: (x²+y²-1)³ ≤ x²y³
    float v=nx*nx+ny*ny-1;
    if(v*v*v <= nx*nx*ny*ny*ny){
      int px=cx+dx, py=cy-dy;
      if(px>=0&&px<MW&&py>=0&&py<MH) matrix.drawPixel(px,py,c);
    }
  }
}
void drawStar(int cx,int cy,int sz,uint8_t hue){
  uint16_t c=hsv(hue);
  int r1=sz, r2=sz/2+1;
  for(int i=0;i<5;i++){
    float a1=(i*72-90)*PI/180.0f;
    float a2=((i*72+36)-90)*PI/180.0f;
    int x1=cx+(int)(r1*cos(a1)), y1=cy+(int)(r1*sin(a1));
    int x2=cx+(int)(r2*cos(a2)), y2=cy+(int)(r2*sin(a2));
    // Piksel çizgisi
    int dx=x2-x1, dy=y2-y1, steps=max(abs(dx),abs(dy));
    for(int s=0;s<=steps;s++){
      int px=x1+dx*s/max(steps,1), py=y1+dy*s/max(steps,1);
      if(px>=0&&px<MW&&py>=0&&py<MH) matrix.drawPixel(px,py,c);
    }
    // Çekirdeğe dön
    int x3=cx+(int)(r1*cos(a1+72*PI/180.0f)), y3=cy+(int)(r1*sin(a1+72*PI/180.0f));
    dx=x3-x2; dy=y3-y2; steps=max(abs(dx),abs(dy));
    for(int s=0;s<=steps;s++){
      int px=x2+dx*s/max(steps,1), py=y2+dy*s/max(steps,1);
      if(px>=0&&px<MW&&py>=0&&py<MH) matrix.drawPixel(px,py,c);
    }
  }
}
void drawSnowflake(int cx,int cy,int sz,uint8_t hue){
  uint16_t c=hsv(hue);
  for(int arm=0;arm<6;arm++){
    float angle=arm*60*PI/180.0f;
    for(int r=0;r<=sz;r++){
      int px=cx+(int)(r*cos(angle)), py=cy+(int)(r*sin(angle));
      if(px>=0&&px<MW&&py>=0&&py<MH) matrix.drawPixel(px,py,c);
      // Yan dallar
      if(r==sz/2){
        for(int b=-1;b<=1;b+=2){
          float ba=(arm*60+b*45)*PI/180.0f;
          for(int br=0;br<=sz/3;br++){
            int bx=px+(int)(br*cos(ba)), by=py+(int)(br*sin(ba));
            if(bx>=0&&bx<MW&&by>=0&&by<MH) matrix.drawPixel(bx,by,c);
          }
        }
      }
    }
  }
}
void drawArrow(int cx,int cy,int sz,uint8_t hue){
  uint16_t c=hsv(hue);
  // Sağa bakan ok
  for(int i=0;i<=sz;i++){
    matrix.drawPixel(cx-sz+i, cy, c);         // gövde
    matrix.drawPixel(cx+sz-i, cy-i, c);       // üst kanat
    matrix.drawPixel(cx+sz-i, cy+i, c);       // alt kanat
  }
}
void drawSpiral(int cx,int cy,int sz,uint8_t hue){
  for(float t=0;t<sz*6.28f;t+=0.15f){
    float r=t/(sz*0.8f);
    int px=cx+(int)(r*cos(t+frame*0.05f));
    int py=cy+(int)(r*sin(t+frame*0.05f));
    if(px>=0&&px<MW&&py>=0&&py<MH)
      matrix.drawPixel(px,py,hsv((hue+((int)(t*10))+(frame*3))&0xFF));
  }
}
void drawTarget(int cx,int cy,int sz,uint8_t hue){
  for(int r=1;r<=sz;r+=2){
    uint16_t c=hsv((hue+r*30)&0xFF);
    // Çember yaklaşımı
    for(int a=0;a<360;a+=10){
      int px=cx+(int)(r*cos(a*PI/180.0f));
      int py=cy+(int)(r*sin(a*PI/180.0f));
      if(px>=0&&px<MW&&py>=0&&py<MH) matrix.drawPixel(px,py,c);
    }
  }
  matrix.drawPixel(cx,cy,hsv(hue)); // merkez nokta
}
void drawEyes(int cx,int cy,int sz,uint8_t hue){
  uint16_t white=matrix.Color(200,200,200);
  uint16_t iris=hsv(hue);
  uint16_t pupil=matrix.Color(0,0,0);
  int blink=(frame/30)%8==0; // arada bir goz kirp
  if(!blink){
    // Sol göz
    matrix.fillRect(cx-sz*2-1, cy-sz/2, sz+1, sz, white);
    matrix.drawPixel(cx-sz*2+sz/2+(int)(sin(frame*0.05f)*sz/3), cy, iris);
    // Sag goz
    matrix.fillRect(cx+sz, cy-sz/2, sz+1, sz, white);
    matrix.drawPixel(cx+sz+sz/2+(int)(sin(frame*0.05f)*sz/3), cy, iris);
  } else {
    // Kirpma: ince çizgi
    for(int x=cx-sz*2-1;x<cx-sz+2;x++) matrix.drawPixel(x,cy,white);
    for(int x=cx+sz;x<cx+sz*2+2;x++)   matrix.drawPixel(x,cy,white);
  }
}

void drawFigure(){
  if(figureMode==0) return;
  int cx=MW/2, cy=MH/2;
  int sz=constrain((int)figureSize,1,min(MW/2-1,MH/2-1));
  uint8_t hue=(baseHue+frame*2)&0xFF;
  switch(figureMode){
    case 1:  drawHeart(cx,cy,sz,hue); break;
    case 2:  drawStar(cx,cy,sz+1,hue); break;
    case 3:  drawSnowflake(cx,cy,sz,hue); break;
    case 4:  drawSpiral(cx,cy,sz,hue); break;
    case 5:  drawArrow(cx,cy,sz,hue); break;
    case 6:  drawTarget(cx,cy,sz,hue); break;
    case 7:  drawEyes(cx,cy,sz,hue); break;
    // 8-11: gelecek güncellemeler için yer
    default: break;
  }
}

// ─── YAZI ────────────────────────────────────────────────────
void applyOrient(){
  uint8_t r=(rotSteps+(orient==OR_H?0:orient==OR_V_UP?1:3))&0x3;
  matrix.setRotation(r);
}
void prepareText(const String&s){
  applyOrient();matrix.setTextWrap(false);matrix.setTextSize(textSize);
  int16_t x1,y1;uint16_t w,h;matrix.getTextBounds(s,0,0,&x1,&y1,&w,&h);textW=w;
  if(orient==OR_H) textX=(dirLR<0)?matrix.width():-textW;
  else textX=(matrix.width()/2)-(textW/2);
}
uint16_t getTextColor(int16_t col){
  switch(textAnim){
    case TA_WAVE:    return hsv((baseHue+col*12+frame)&0xFF);
    case TA_RAINBOW: return hsv((baseHue+frame*3)&0xFF);
    case TA_GLOW:    {uint8_t v=(uint8_t)(128+127*sin(frame*0.06f));return hsv(baseHue,255,v);}
    default: return hsv(baseHue);
  }
}
void drawText(){
  if(textCount==0) return;
  applyOrient();matrix.setTextWrap(false);matrix.setTextSize(textSize);
  if(textAnim==TA_BLINK){
    if(frame%20<10){matrix.setTextColor(hsv(baseHue));matrix.setCursor(textX,textY);matrix.print(activeText);}
  } else if(textAnim==TA_TYPING){
    int show=min((int)(frame/8),(int)activeText.length());
    matrix.setTextColor(hsv(baseHue));matrix.setCursor(borderWidth+1,textY);matrix.print(activeText.substring(0,show));
    if(show>=(int)activeText.length()&&frame%80<5) matrix.drawPixel(borderWidth+1+show*6,textY+5,0xFFFF);
  } else {
    matrix.setTextColor(getTextColor(textX));matrix.setCursor(textX,textY);matrix.print(activeText);
    if(orient==OR_H) textX+=(dirLR<0?-1:+1);
    else if(orient==OR_V_UP) textX--;
    else textX++;
    bool wrapped=false;
    if(orient==OR_H){if(dirLR<0){if(textX<-textW){textX=matrix.width();wrapped=true;}}else{if(textX>matrix.width()){textX=-textW;wrapped=true;}}}
    else{if(textX<-textW){textX=matrix.width();wrapped=true;}if(textX>matrix.width()){textX=-textW;wrapped=true;}}
    // Playlist: metin bitince degil, playInterval'da gecis
    (void)wrapped; // artik interval ile gecis yapiliyor
  }
}
void drawFrame(){
  matrix.fillScreen(0);
  drawBg();
  if(figureMode>0) drawFigure();   // v6: figür
  drawText();
  drawBorder();
  matrix.show();
  frame++;
}

// ─── PREFS ───────────────────────────────────────────────────
void savePrefs(){
  prefs.begin("tb",false);
  prefs.putUChar("ai",activeIdx);prefs.putUChar("br",brightness);prefs.putShort("sp",scrollSpeed);
  prefs.putUChar("ot",(uint8_t)orient);prefs.putChar("dl",dirLR);prefs.putUChar("hu",baseHue);
  prefs.putUChar("ts",textSize);prefs.putChar("ty",textY);prefs.putUChar("ro",rotSteps);prefs.putBool("pl",playlistMode);
  prefs.putUChar("ta",(uint8_t)textAnim);prefs.putUChar("ba",(uint8_t)borderAnim);
  prefs.putUChar("bh",borderHue);prefs.putUChar("bw",borderWidth);prefs.putUChar("bg",(uint8_t)bgFill);
  // v6 ek alanlar
  prefs.putUChar("fm",figureMode);prefs.putUChar("sc",sceneMode);
  prefs.putUChar("pi",playInterval);prefs.putUChar("fs",fxSpeed);
  prefs.putUChar("fi",fxIntensity);prefs.putUChar("fz",figureSize);
  for(int i=0;i<textCount;i++) prefs.putString(("t"+String(i)).c_str(),customTexts[i]);
  prefs.putUChar("tc",textCount);
  prefs.end();
}
void loadPrefs(){
  prefs.begin("tb",true);
  activeIdx=prefs.getUChar("ai",0);brightness=prefs.getUChar("br",160);scrollSpeed=prefs.getShort("sp",40);
  orient=(Orient)prefs.getUChar("ot",0);dirLR=prefs.getChar("dl",-1);baseHue=prefs.getUChar("hu",0);
  textSize=prefs.getUChar("ts",1);textY=prefs.getChar("ty",6);rotSteps=prefs.getUChar("ro",0);playlistMode=prefs.getBool("pl",false);
  textAnim=(TextAnim)prefs.getUChar("ta",0);borderAnim=(BorderAnim)prefs.getUChar("ba",0);
  borderHue=prefs.getUChar("bh",0);borderWidth=prefs.getUChar("bw",1);bgFill=(BgFill)prefs.getUChar("bg",0);
  // v6 ek alanlar
  figureMode=prefs.getUChar("fm",0);sceneMode=prefs.getUChar("sc",0);
  playInterval=prefs.getUChar("pi",5);fxSpeed=prefs.getUChar("fs",50);
  fxIntensity=prefs.getUChar("fi",50);figureSize=prefs.getUChar("fz",3);
  uint8_t tc=prefs.getUChar("tc",8);if(tc>0&&tc<=MAX_CUSTOM)textCount=tc;
  for(int i=0;i<textCount;i++){String def=customTexts[i];customTexts[i]=prefs.getString(("t"+String(i)).c_str(),def);}
  prefs.end();
  if(activeIdx>=textCount)activeIdx=0;
  if(textCount>0) activeText=customTexts[activeIdx];
}

// ─── JSON STATUS ─────────────────────────────────────────────
String buildStatus(){
  String s="{";
  s+="\"brightness\":"+String(brightness)+",\"speed\":"+String(scrollSpeed)+",";
  s+="\"blackout\":"+String(blackout?"true":"false")+",\"hue\":"+String(baseHue)+",";
  s+="\"textSize\":"+String(textSize)+",\"textY\":"+String(textY)+",";
  s+="\"orient\":"+String((int)orient)+",\"dirLR\":"+String(dirLR)+",";
  s+="\"rotSteps\":"+String(rotSteps)+",";
  s+="\"playlist\":"+String(playlistMode?"true":"false")+",\"activeIdx\":"+String(activeIdx)+",";
  s+="\"textAnim\":"+String((int)textAnim)+",\"borderAnim\":"+String((int)borderAnim)+",";
  s+="\"borderHue\":"+String(borderHue)+",\"borderWidth\":"+String(borderWidth)+",";
  s+="\"bgFill\":"+String((int)bgFill)+",\"textCount\":"+String(textCount)+",";
  // v6 ek alanlar
  s+="\"figureMode\":"+String(figureMode)+",\"sceneMode\":"+String(sceneMode)+",";
  s+="\"playInterval\":"+String(playInterval)+",\"fxSpeed\":"+String(fxSpeed)+",";
  s+="\"fxIntensity\":"+String(fxIntensity)+",\"figureSize\":"+String(figureSize)+",";
  s+="\"bleConnected\":"+String(bleCon?"true":"false")+",";
  s+="\"maxTexts\":"+String(MAX_CUSTOM)+",";
  s+="\"texts\":[";
  for(int i=0;i<textCount;i++){s+="\""+customTexts[i]+"\"";if(i<textCount-1)s+=",";}
  s+="]}";return s;
}

// ─── KOMUT İŞLEYİCİ ─────────────────────────────────────────
void processCmd(const String&raw){
  auto getInt=[&](const String&k,int def)->int{int i=raw.indexOf("\""+k+"\":");if(i<0)return def;return raw.substring(i+k.length()+3).toInt();};
  auto getBool=[&](const String&k,bool def)->bool{int i=raw.indexOf("\""+k+"\":");if(i<0)return def;return raw.substring(i+k.length()+3,i+k.length()+7)=="true";};
  auto getStr=[&](const String&k)->String{int i=raw.indexOf("\""+k+"\":\"");if(i<0)return "";int s=i+k.length()+4;int e=raw.indexOf("\"",s);if(e<0)return "";return raw.substring(s,e);};

  // ── mevcut parametreler ──────────────────────────────────
  if(raw.indexOf("\"brightness\":")>=0){brightness=(uint8_t)constrain(getInt("brightness",160),0,255);matrix.setBrightness(brightness);}
  if(raw.indexOf("\"speed\":")>=0)      scrollSpeed=constrain(getInt("speed",40),5,500);
  if(raw.indexOf("\"hue\":")>=0)        baseHue=(uint8_t)getInt("hue",0);
  if(raw.indexOf("\"borderHue\":")>=0)  borderHue=(uint8_t)getInt("borderHue",0);
  if(raw.indexOf("\"borderWidth\":")>=0)borderWidth=(uint8_t)constrain(getInt("borderWidth",1),0,4);
  if(raw.indexOf("\"textSize\":")>=0){  textSize=(uint8_t)constrain(getInt("textSize",1),1,2);prepareText(activeText);}
  if(raw.indexOf("\"textY\":")>=0)      textY=constrain(getInt("textY",6),0,MH-8);
  if(raw.indexOf("\"orient\":")>=0){    orient=(Orient)constrain(getInt("orient",0),0,2);prepareText(activeText);}
  if(raw.indexOf("\"dirLR\":")>=0){     dirLR=(getInt("dirLR",-1)>=0)?1:-1;prepareText(activeText);}
  if(raw.indexOf("\"blackout\":")>=0){  blackout=getBool("blackout",false);if(blackout){matrix.fillScreen(0);matrix.show();}}
  if(raw.indexOf("\"playlist\":")>=0)   playlistMode=getBool("playlist",false);
  if(raw.indexOf("\"textAnim\":")>=0)   textAnim=(TextAnim)constrain(getInt("textAnim",0),0,5);
  if(raw.indexOf("\"borderAnim\":")>=0) borderAnim=(BorderAnim)constrain(getInt("borderAnim",0),0,7);
  if(raw.indexOf("\"bgFill\":")>=0)     bgFill=(BgFill)constrain(getInt("bgFill",0),0,7);
  if(raw.indexOf("\"rotSteps\":")>=0){  rotSteps=(uint8_t)getInt("rotSteps",0)&0x3;prepareText(activeText);}
  if(raw.indexOf("\"activeIdx\":")>=0){
    int idx=constrain(getInt("activeIdx",0),0,max(0,textCount-1));
    activeIdx=idx;
    if(textCount>0){activeText=customTexts[activeIdx];prepareText(activeText);}
  }
  if(raw.indexOf("\"customText\":")>=0){
    String ct=getStr("customText");
    if(ct.length()>0){activeText=ct;prepareText(activeText);}
  }

  // setText: {"setText":{"idx":0,"text":"YENİ YAZI "}}
  if(raw.indexOf("\"setText\":")>=0){
    int bi=raw.indexOf("\"setText\":");String sub=raw.substring(bi+10);
    int idxPos=sub.indexOf("\"idx\":");int txtPos=sub.indexOf("\"text\":\"");
    if(idxPos>=0&&txtPos>=0){
      int idx=sub.substring(idxPos+6).toInt();int ts=txtPos+8;int te=sub.indexOf("\"",ts);
      String newTxt=sub.substring(ts,te);
      if(idx>=0&&idx<MAX_CUSTOM){
        customTexts[idx]=newTxt;
        if(idx>=textCount) textCount=idx+1;
        if(idx==activeIdx){activeText=newTxt;prepareText(activeText);}
      }
    }
  }

  // addText: {"addText":"YENİ YAZI "}
  String addT=getStr("addText");
  if(addT.length()>0&&textCount<MAX_CUSTOM){customTexts[textCount]=addT;textCount++;}

  // ── v6 YENİ KOMUTLAR ────────────────────────────────────
  if(raw.indexOf("\"figureMode\":")>=0) figureMode=(uint8_t)constrain(getInt("figureMode",0),0,11);
  if(raw.indexOf("\"sceneMode\":")>=0)  sceneMode=(uint8_t)constrain(getInt("sceneMode",0),0,7);
  if(raw.indexOf("\"playInterval\":")>=0) playInterval=(uint8_t)constrain(getInt("playInterval",5),1,60);
  if(raw.indexOf("\"fxSpeed\":")>=0)    fxSpeed=(uint8_t)constrain(getInt("fxSpeed",50),1,100);
  if(raw.indexOf("\"fxIntensity\":")>=0) fxIntensity=(uint8_t)constrain(getInt("fxIntensity",50),1,100);
  if(raw.indexOf("\"figureSize\":")>=0) figureSize=(uint8_t)constrain(getInt("figureSize",3),1,8);

  // delText: {"delText":2}
  if(raw.indexOf("\"delText\":")>=0){
    int idx=getInt("delText",-1);
    if(idx>=0&&idx<textCount){
      for(int i=idx;i<textCount-1;i++) customTexts[i]=customTexts[i+1];
      textCount--;
      if(textCount==0){activeIdx=0;activeText="";}
      else{if(activeIdx>=textCount)activeIdx=textCount-1;activeText=customTexts[activeIdx];prepareText(activeText);}
    }
  }

  // moveText: {"moveText":{"from":0,"to":3}}
  if(raw.indexOf("\"moveText\":")>=0){
    int bi=raw.indexOf("\"moveText\":");String sub=raw.substring(bi+11);
    int fp=sub.indexOf("\"from\":");int tp=sub.indexOf("\"to\":");
    if(fp>=0&&tp>=0){
      int from=sub.substring(fp+7).toInt();
      int to=sub.substring(tp+5).toInt();
      if(from>=0&&from<textCount&&to>=0&&to<textCount&&from!=to){
        String tmp=customTexts[from];
        if(from<to){ for(int i=from;i<to;i++) customTexts[i]=customTexts[i+1]; }
        else        { for(int i=from;i>to;i--) customTexts[i]=customTexts[i-1]; }
        customTexts[to]=tmp;
        if(activeIdx==from) activeIdx=to;
      }
    }
  }

  // clearTexts: {"clearTexts":true}
  if(raw.indexOf("\"clearTexts\":")>=0&&getBool("clearTexts",false)){
    textCount=0;activeIdx=0;activeText="";
  }

  // saveTexts: sadece metin listesini yaz
  if(raw.indexOf("\"saveTexts\":")>=0&&getBool("saveTexts",false)){
    prefs.begin("tb",false);
    for(int i=0;i<textCount;i++) prefs.putString(("t"+String(i)).c_str(),customTexts[i]);
    prefs.putUChar("tc",textCount);
    prefs.end();
    return; // savePrefs'i tekrar cagirma
  }

  // saveAll / saveSettings
  if(raw.indexOf("\"saveAll\":")>=0||raw.indexOf("\"saveSettings\":")>=0){
    savePrefs(); return;
  }

  // factoryReset: {"factoryReset":true}
  if(raw.indexOf("\"factoryReset\":")>=0&&getBool("factoryReset",false)){
    prefs.begin("tb",false);prefs.clear();prefs.end();
    delay(200);ESP.restart();
  }

  savePrefs();
}

// ─── HTTP SUNUCU ─────────────────────────────────────────────
void setupHTTP(){
  auto addCORS=[&](){
    server.sendHeader("Access-Control-Allow-Origin","*");
    server.sendHeader("Access-Control-Allow-Methods","GET,POST,OPTIONS");
    server.sendHeader("Access-Control-Allow-Headers","Content-Type");
  };

  // Basit tarayici kontrol sayfasi
  server.on("/",HTTP_GET,[](){
    server.send(200,"text/html",R"(<!DOCTYPE html><html><head><meta charset='utf-8'>
<title>Akilli Tahta</title><meta name='viewport' content='width=device-width,initial-scale=1'>
<style>body{font-family:sans-serif;background:#0d0d0d;color:#eee;padding:16px;max-width:500px;margin:auto}
h2{color:#00e5ff}input,select{width:100%;padding:8px;margin:4px 0;background:#1a1a2e;color:#eee;border:1px solid #333;border-radius:6px;box-sizing:border-box}
button{padding:10px 16px;background:#00e5ff;color:#000;border:none;border-radius:6px;cursor:pointer;margin:4px}
.row{margin:10px 0}.label{color:#888;font-size:12px}</style></head><body>
<h2>Akilli Tahta v6</h2>
<div class='row'><div class='label'>Metin Gonder</div>
<input id='txt' type='text' placeholder='yazinizi girin'>
<button onclick='send({addText:document.getElementById("txt").value.toUpperCase()+" "})'>Ekle</button>
<button onclick='send({customText:document.getElementById("txt").value.toUpperCase()+" "})'>Goster</button></div>
<div class='row'><div class='label'>Parlaklik</div><input type='range' min='0' max='255' oninput='send({brightness:+this.value})'></div>
<div class='row'><div class='label'>Hiz</div><input type='range' min='5' max='300' oninput='send({speed:+this.value})'></div>
<div class='row'><div class='label'>Renk</div><input type='range' min='0' max='255' oninput='send({hue:+this.value})'></div>
<div class='row'>
<button onclick='send({dirLR:-1})'>← Sola</button>
<button onclick='send({dirLR:1})'>Saga →</button>
<button onclick='send({blackout:true})'>Kapat</button>
<button onclick='send({blackout:false})'>Ac</button>
<button onclick='send({playlist:true})'>Playlist</button>
</div>
<script>function send(o){fetch('/cmd',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(o)}).then(r=>r.json()).then(d=>console.log(d));}</script>
</body></html>)");
  });

  server.on("/status",HTTP_GET,[&](){
    addCORS();
    server.send(200,"application/json",buildStatus());
  });

  server.on("/cmd",HTTP_POST,[&](){
    addCORS();
    String body=server.arg("plain");
    if(body.length()>0) processCmd(body);
    server.send(200,"application/json",buildStatus());
  });

  server.on("/cmd",HTTP_OPTIONS,[&](){
    addCORS();server.send(200);
  });

  server.begin();
  Serial.println("[HTTP] Sunucu: http://192.168.4.1");
}

// ─── SERIAL ──────────────────────────────────────────────────
void handleSerial(String cmd){
  cmd.trim();if(cmd.length()==0)return;
  if(cmd.startsWith("{")){processCmd(cmd);Serial.println(buildStatus());return;}
  int sp=cmd.indexOf(' ');
  String key=sp<0?cmd:cmd.substring(0,sp);
  String val=sp<0?"":cmd.substring(sp+1);
  key.toLowerCase();val.trim();

  if(key=="help"){
    Serial.println("=== AKILLI TAHTA v6 KOMUTLARI ===");
    Serial.println("yaz <metin>      : metin goster");
    Serial.println("parlaklik <0-255>: parlaklik ayarla");
    Serial.println("hiz <5-300>      : hiz ayarla");
    Serial.println("renk <0-255>     : renk tonu");
    Serial.println("sol / sag        : yon");
    Serial.println("yatay/yukari/asagi: orient");
    Serial.println("don              : 90 derece don");
    Serial.println("boyut            : 1x/2x toggle");
    Serial.println("ac / kapat       : ekran ac/kapat");
    Serial.println("playlist         : playlist toggle");
    Serial.println("sonraki/onceki   : playlist gecis");
    Serial.println("sec <0-N>        : metin sec");
    Serial.println("ekle <metin>     : metin ekle");
    Serial.println("sil <N>          : metin sil");
    Serial.println("figur <0-7>      : figur modu");
    Serial.println("durum            : durum goster");
    Serial.println("liste            : metin listesi");
    Serial.println("kaydet           : EEPROM'a kaydet");
    Serial.println("sifirla          : fabrika sifirla");
  }
  else if(key=="yaz"||key=="text"){val.toUpperCase();if(!val.endsWith(" "))val+=" ";activeText=val;prepareText(activeText);Serial.println("OK: "+activeText);}
  else if(key=="parlaklik"){brightness=(uint8_t)constrain(val.toInt(),0,255);matrix.setBrightness(brightness);Serial.println("OK: "+String(brightness));}
  else if(key=="hiz"){scrollSpeed=constrain(val.toInt(),5,500);Serial.println("OK: "+String(scrollSpeed));}
  else if(key=="renk"){baseHue=(uint8_t)val.toInt();Serial.println("OK: "+String(baseHue));}
  else if(key=="sol"){dirLR=-1;prepareText(activeText);Serial.println("OK");}
  else if(key=="sag"){dirLR=+1;prepareText(activeText);Serial.println("OK");}
  else if(key=="yatay"){orient=OR_H;prepareText(activeText);Serial.println("OK");}
  else if(key=="yukari"){orient=OR_V_UP;prepareText(activeText);Serial.println("OK");}
  else if(key=="asagi"){orient=OR_V_DOWN;prepareText(activeText);Serial.println("OK");}
  else if(key=="don"){rotSteps=(rotSteps+1)&0x3;prepareText(activeText);Serial.println("OK: "+String(rotSteps*90)+"°");}
  else if(key=="boyut"){textSize=(textSize==1?2:1);prepareText(activeText);Serial.println("OK: "+String(textSize)+"x");}
  else if(key=="ypoz"){textY=constrain(val.toInt(),0,12);Serial.println("OK: textY="+String(textY));}
  else if(key=="ac"){blackout=false;Serial.println("OK");}
  else if(key=="kapat"){blackout=true;matrix.fillScreen(0);matrix.show();Serial.println("OK");}
  else if(key=="playlist"){playlistMode=!playlistMode;Serial.println("OK: "+String(playlistMode?"ACIK":"KAPALI"));}
  else if(key=="sonraki"){if(textCount>0){activeIdx=(activeIdx+1)%textCount;activeText=customTexts[activeIdx];prepareText(activeText);Serial.println("OK: ["+String(activeIdx)+"] "+activeText);}}
  else if(key=="onceki"){if(textCount>0){if(activeIdx>0)activeIdx--;else activeIdx=textCount-1;activeText=customTexts[activeIdx];prepareText(activeText);Serial.println("OK: ["+String(activeIdx)+"] "+activeText);}}
  else if(key=="sec"){int i=val.toInt();if(i>=0&&i<textCount){activeIdx=i;activeText=customTexts[i];prepareText(activeText);Serial.println("OK");}else Serial.println("HATA");}
  else if(key=="ekle"){val.toUpperCase();if(!val.endsWith(" "))val+=" ";if(textCount<MAX_CUSTOM){customTexts[textCount]=val;textCount++;Serial.println("OK: Eklendi ["+String(textCount-1)+"]");}else Serial.println("HATA: Dolu");}
  else if(key=="sil"){int i=val.toInt();processCmd("{\"delText\":"+String(i)+"}");Serial.println("OK: Silindi");}
  else if(key=="guncelle"){int sp2=val.indexOf(' ');if(sp2>0){int i=val.substring(0,sp2).toInt();String t=val.substring(sp2+1);t.toUpperCase();if(!t.endsWith(" "))t+=" ";if(i>=0&&i<MAX_CUSTOM){customTexts[i]=t;if(i==activeIdx){activeText=t;prepareText(activeText);}Serial.println("OK");}}}
  else if(key=="yanim"){textAnim=(TextAnim)constrain(val.toInt(),0,5);Serial.println("OK: yanim="+String((int)textAnim));}
  else if(key=="cerceve"){borderAnim=(BorderAnim)constrain(val.toInt(),0,7);Serial.println("OK");}
  else if(key=="crenk"){borderHue=(uint8_t)val.toInt();Serial.println("OK");}
  else if(key=="ckalinlik"){borderWidth=(uint8_t)constrain(val.toInt(),0,4);Serial.println("OK");}
  else if(key=="arka"){bgFill=(BgFill)constrain(val.toInt(),0,7);Serial.println("OK");}
  else if(key=="figur"){figureMode=(uint8_t)constrain(val.toInt(),0,11);Serial.println("OK: figur="+String(figureMode));}
  else if(key=="figurboyut"){figureSize=(uint8_t)constrain(val.toInt(),1,8);Serial.println("OK");}
  else if(key=="sahne"){sceneMode=(uint8_t)constrain(val.toInt(),0,7);Serial.println("OK");}
  else if(key=="durum"){
    Serial.println("=== DURUM ===");
    Serial.println("Parlaklik:"+String(brightness)+" Hiz:"+String(scrollSpeed)+" Renk:"+String(baseHue));
    Serial.println("Yon:"+String((int)orient)+" Dir:"+String(dirLR)+" Boyut:"+String(textSize)+"x Y:"+String(textY));
    Serial.println("Anim:"+String((int)textAnim)+" Cerceve:"+String((int)borderAnim)+" Arka:"+String((int)bgFill));
    Serial.println("Figur:"+String(figureMode)+" Boyut:"+String(figureSize)+" Sahne:"+String(sceneMode));
    Serial.println("Ekran:"+String(blackout?"KAPALI":"ACIK")+" Playlist:"+String(playlistMode?"ACIK":"KAPALI")+" Interval:"+String(playInterval)+"sn");
    Serial.println("Aktif:["+String(activeIdx)+"] "+activeText);
    Serial.println("Metin sayisi: "+String(textCount)+"/"+String(MAX_CUSTOM));
    Serial.println("BLE: "+String(bleCon?"Bagli":"Bos")+" WiFi AP: 192.168.4.1");
  }
  else if(key=="liste"){
    for(int i=0;i<textCount;i++){
      Serial.print(i==activeIdx?"[*]":"[ ]");
      Serial.println(" "+String(i)+": "+customTexts[i]);
    }
    if(textCount==0) Serial.println("(bos)");
  }
  else if(key=="kaydet"){savePrefs();Serial.println("OK: EEPROM'a kaydedildi");}
  else if(key=="sifirla"){prefs.begin("tb",false);prefs.clear();prefs.end();Serial.println("Sifirlanıyor...");delay(500);ESP.restart();}
  else{Serial.println("HATA: '"+key+"' bilinmiyor. 'help' yaz");}
  savePrefs();
}

// ─── IR ──────────────────────────────────────────────────────
void handleIR(){
  if(!IrReceiver.decode()) return;
  if(IrReceiver.decodedIRData.flags&IRDATA_FLAGS_IS_REPEAT){IrReceiver.resume();return;}
  uint32_t c=IrReceiver.decodedIRData.decodedRawData;
  if(c==IR_PLY){playlistMode=!playlistMode;savePrefs();}
  else if(c==IR_CH_M){if(textCount>0){if(activeIdx>0)activeIdx--;else activeIdx=textCount-1;activeText=customTexts[activeIdx];prepareText(activeText);savePrefs();}}
  else if(c==IR_CH_P){if(textCount>0){activeIdx=(activeIdx+1)%textCount;activeText=customTexts[activeIdx];prepareText(activeText);savePrefs();}}
  else if(c==IR_PRV){scrollSpeed=min(500,scrollSpeed+5);savePrefs();}
  else if(c==IR_NXT){scrollSpeed=max(5,scrollSpeed-5);savePrefs();}
  else if(c==IR_VM){brightness=(brightness<=10?0:brightness-10);matrix.setBrightness(brightness);savePrefs();}
  else if(c==IR_VP){brightness=(brightness>=245?255:brightness+10);matrix.setBrightness(brightness);savePrefs();}
  else if(c==IR_EQ){blackout=!blackout;if(blackout){matrix.fillScreen(0);matrix.show();}}
  else if(c==IR_FM){baseHue-=16;savePrefs();}
  else if(c==IR_FP){baseHue+=16;savePrefs();}
  else if(c==IR_1){orient=(Orient)((orient+1)%3);prepareText(activeText);savePrefs();}
  else if(c==IR_3){borderAnim=(BorderAnim)((borderAnim+1)%8);savePrefs();}
  else if(c==IR_7){bgFill=(BgFill)((bgFill+1)%8);savePrefs();}
  else if(c==IR_9){borderHue+=32;savePrefs();}
  else if(c==IR_4){if(orient==OR_H)dirLR=-1;else orient=OR_V_UP;prepareText(activeText);savePrefs();}
  else if(c==IR_6){if(orient==OR_H)dirLR=+1;else orient=OR_V_DOWN;prepareText(activeText);savePrefs();}
  else if(c==IR_5){textSize=(textSize==1?2:1);prepareText(activeText);savePrefs();}
  else if(c==IR_0){rotSteps=(rotSteps+1)&0x3;prepareText(activeText);savePrefs();}
  else if(c==IR_2){textY=max(0,textY-1);savePrefs();}
  else if(c==IR_8){textY=min(12,textY+1);savePrefs();}
  // IR_8 = figur cycling (uzun bas ile)
  IrReceiver.resume();
}

// ─── BLE ─────────────────────────────────────────────────────
class BleSrvCB:public BLEServerCallbacks{
  void onConnect(BLEServer*)override{bleCon=true;Serial.println("[BLE] Baglandi");}
  void onDisconnect(BLEServer*)override{bleCon=false;BLEDevice::startAdvertising();Serial.println("[BLE] Kesildi, reklam yeniden basladi");}
};
class BleCmdCB:public BLECharacteristicCallbacks{
  void onWrite(BLECharacteristic*c)override{
    bleCmd=String(c->getValue().c_str());
    bleNew=true;
    Serial.println("[BLE RX] "+bleCmd);
  }
};
void setupBLE(){
  BLEDevice::init("AkilliTahta");
  BLEDevice::setMTU(512);
  bleServer=BLEDevice::createServer();
  bleServer->setCallbacks(new BleSrvCB());
  BLEService*svc=bleServer->createService(SVC_UUID);
  cmdChar=svc->createCharacteristic(CMD_UUID,BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_WRITE_NR);
  cmdChar->setCallbacks(new BleCmdCB());
  stsChar=svc->createCharacteristic(STS_UUID,BLECharacteristic::PROPERTY_READ|BLECharacteristic::PROPERTY_NOTIFY);
  stsChar->addDescriptor(new BLE2902());
  svc->start();
  BLEAdvertising*adv=BLEDevice::getAdvertising();
  adv->addServiceUUID(SVC_UUID);
  adv->setScanResponse(true);
  adv->setMinPreferred(0x06);
  BLEDevice::startAdvertising();
  Serial.println("[BLE] AkilliTahta hazir, taranabilir");
}

// ─── SETUP ───────────────────────────────────────────────────
void setup(){
  Serial.begin(115200);
  matrix.begin();
  matrix.setTextWrap(false);
  loadPrefs();
  if(brightness==0) brightness=120;
  blackout=false;
  matrix.setBrightness(brightness);
  IrReceiver.begin(IR_PIN,DISABLE_LED_FEEDBACK);
  for(int x=0;x<MW;x++){mDropY[x]=random(MH);mDropL[x]=random(3,MH/2);mDropS[x]=random(1,4);}
  prepareText(activeText);

  // Boot animasyonu: gokusagi sonu
  for(uint8_t h=0;h<255;h+=5){matrix.fillScreen(hsv(h));matrix.show();delay(8);}
  matrix.fillScreen(0);matrix.show();

  // WiFi AP
  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID,AP_PASS);
  Serial.println("[WiFi] AP: "+String(AP_SSID)+" / "+String(AP_PASS));
  Serial.println("[WiFi] IP: 192.168.4.1");

  // Ekranda kisa bilgi
  matrix.fillScreen(0);matrix.setTextSize(1);
  matrix.setTextColor(matrix.Color(0,200,255));
  matrix.setCursor(0,6);matrix.print("v6");matrix.show();delay(1000);

  setupHTTP();
  setupBLE();

  Serial.println("");
  Serial.println("╔══════════════════════════════════════╗");
  Serial.println("║  AKILLI TAHTA v6.0 HAZIR             ║");
  Serial.println("║  WiFi: AkilliTahta-AP / 12345678     ║");
  Serial.println("║  IP  : 192.168.4.1                   ║");
  Serial.println("║  BLE : AkilliTahta                   ║");
  Serial.println("║  Serial: 'help' yaz                  ║");
  Serial.println("╚══════════════════════════════════════╝");
}

// ─── LOOP ────────────────────────────────────────────────────
void loop(){
  // Serial
  while(Serial.available()){
    char c=Serial.read();
    if(c=='\n'||c=='\r'){
      if(serialBuf.length()>0){Serial.print("> ");Serial.println(serialBuf);handleSerial(serialBuf);serialBuf="";}
    } else serialBuf+=c;
  }

  // HTTP
  server.handleClient();

  // IR
  handleIR();

  // BLE komut
  if(bleNew){
    processCmd(bleCmd);
    // BLE status notify gonder
    String st=buildStatus();
    stsChar->setValue(st.c_str());
    stsChar->notify();
    bleNew=false;
  }

  if(blackout) return;

  uint32_t now=millis();

  // Playlist interval timer (v6: metin kaydirma bitince degil, sure ile gecis)
  if(playlistMode&&textCount>1&&(now-lastPlayMs>=(uint32_t)playInterval*1000)){
    lastPlayMs=now;
    activeIdx=(activeIdx+1)%textCount;
    activeText=customTexts[activeIdx];
    prepareText(activeText);
  }

  // Kare çiz
  if(now-lastStep>=(uint32_t)scrollSpeed){lastStep=now;drawFrame();}
}
