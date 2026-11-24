/*
    ============================================================
     DUKTUR RP - ARAC GALERISI  (galeri.pwn)   v1.0
     GTA San Andreas temali, SA-MP (0.3.7) Textdraw arayuzu
    ============================================================
     KURULUM
       1) Bu dosyayi GitHub'da  filterscripts/galeri.pwn  olarak koy
       2) Derle -> galeri.amx
       3) galeri.amx'i sunucuda  filterscripts/  klasorune at
       4) server.cfg icinde:  filterscripts galeri
       5) Oyunda:  /galeri     (test surusunu erken bitirmek: /testbitir)

     NOT: SA-MP'de HTML/CSS yok (o FiveM NUI). Bu yuzden tasarim
     textdraw ile yapildi. Turkce harf (ğ,ş,ı) kullanilmadi, cunku
     dosya kodlamasi/oyun fontu yuzunden bozuk gorunur.

     SATIN ALMAYI KAYDETMEK ICIN (gamemode'una ekle):
       forward OnGaleriAracSatinAlindi(playerid, model, fiyat);
       public  OnGaleriAracSatinAlindi(playerid, model, fiyat)
       {
           // burada veritabanina / dosyaya kaydet
           return 1;
       }
    ============================================================
*/

#include <a_samp>

#pragma tabsize 0

// ------------------------------------------------------------
//  AYARLAR
// ------------------------------------------------------------
#define GAL_P              50          // desteklenen max oyuncu slotu (maxplayers 30 ise yeter)
#define GAL_TEST_SURE      120         // test surusu suresi (saniye)
#define GAL_VIP_KONTROL    0           // 1 yaparsan VIP araclar icin SetPVarInt(playerid,"VIP",1) sart

// Test surusu aracinin dogdugu yer (kendi galeri koordinatinla degistir)
#define TEST_X   1520.0
#define TEST_Y   -1690.0
#define TEST_Z   13.4
#define TEST_A   270.0

// Satin alinan aracin dogdugu yer
#define BUY_X    1530.0
#define BUY_Y    -1690.0
#define BUY_Z    13.4
#define BUY_A    270.0

// Kamera acilari (Ön/Arka/Yan butonlari). Araba ters gorunurse degistir.
#define CAM_ON   330.0
#define CAM_ARKA 150.0
#define CAM_YAN  60.0

// ------------------------------------------------------------
//  SABITLER
// ------------------------------------------------------------
#define MAX_GAL_VEH   80
#define GAL_CATS      12
#define GAL_CARDS     6
#define GAL_COLS      6
#define MAX_GAL_TD    220

#define BAR_X         486.0
#define BAR_W         130.0

#define COL_YEL       0xFFC800FF
#define COL_WHITE     0xFFFFFFFF
#define COL_GREEN     0x39D353FF
#define COL_GRAY      0xB4B4B4FF
#define COL_PANEL     0x0B0B0BCC
#define COL_BTN       0x1C1C1CD0
#define COL_CARD      0x161616D8

#define DLG_FILTER    7710
#define DLG_SEARCH    7711
#define DLG_BRAND     7712
#define DLG_MINP      7713
#define DLG_MAXP      7714
#define DLG_SPD       7715
#define DLG_BUY       7716
#define DLG_COMPARE   7717

// ------------------------------------------------------------
//  ARAC VERILERI
//  tag: 0 yok, 1 VIP, 2 indirim(%20), 3 yeni
// ------------------------------------------------------------
enum E_GVEH
{
    gModel,
    gName[16],
    gBrand[14],
    gCat,
    gPrice,
    gSpd,
    gAcc,
    gBrk,
    gHnd,
    gFuel[10],
    gGear[12],
    gDrive[4],
    gTag
}

new GVeh[][E_GVEH] =
{
    // ---- 0: SPOR ----
    {560, "Sultan",     "Karin",       0,  450000, 92, 85, 78, 88, "Benzin", "Manuel",      "AWD", 3},
    {562, "Elegy",      "Annis",       0,  500000, 90, 88, 75, 90, "Benzin", "Manuel",      "RWD", 0},
    {559, "Jester",     "Dinka",       0,  600000, 91, 87, 80, 89, "Benzin", "Manuel",      "AWD", 2},
    {429, "Banshee",    "Bravado",     0,  750000, 94, 90, 78, 82, "Benzin", "Manuel",      "RWD", 0},
    {565, "Flash",      "Maibatsu",    0,  420000, 86, 84, 74, 87, "Benzin", "Manuel",      "FWD", 0},
    {558, "Uranus",     "Vapid",       0,  430000, 85, 83, 73, 86, "Benzin", "Manuel",      "FWD", 0},
    {589, "Club",       "Maibatsu",    0,  300000, 80, 80, 70, 84, "Benzin", "Manuel",      "FWD", 0},
    // ---- 1: SUPER ----
    {411, "Infernus",   "Pegassi",     1, 1200000, 97, 95, 82, 85, "Benzin", "Sekvansiyel", "RWD", 0},
    {451, "Turismo",    "Grotti",      1, 1300000, 98, 94, 80, 84, "Benzin", "Sekvansiyel", "RWD", 3},
    {415, "Cheetah",    "Grotti",      1, 1100000, 95, 92, 79, 83, "Benzin", "Manuel",      "RWD", 0},
    {541, "Bullet",     "Vapid",       1, 1250000, 96, 96, 82, 86, "Benzin", "Sekvansiyel", "RWD", 0},
    {506, "Super GT",   "Dewbauchee",  1,  980000, 93, 90, 80, 85, "Benzin", "Manuel",      "RWD", 2},
    {480, "Comet",      "Pfister",     1,  850000, 91, 88, 78, 86, "Benzin", "Manuel",      "RWD", 0},
    {477, "ZR-350",     "Annis",       1,  900000, 94, 91, 81, 90, "Benzin", "Manuel",      "RWD", 0},
    // ---- 2: KASLI ----
    {402, "Buffalo",    "Bravado",     2,  400000, 88, 86, 72, 74, "Benzin", "Manuel",      "RWD", 0},
    {603, "Phoenix",    "Imponte",     2,  380000, 86, 84, 70, 72, "Benzin", "Manuel",      "RWD", 0},
    {475, "Sabre",      "Declasse",    2,  350000, 84, 82, 70, 70, "Benzin", "Otomatik",    "RWD", 0},
    {545, "Hustler",    "Vapid",       2,  300000, 80, 78, 68, 70, "Benzin", "Manuel",      "RWD", 0},
    {549, "Tampa",      "Declasse",    2,  280000, 78, 76, 66, 68, "Benzin", "Manuel",      "RWD", 0},
    {602, "Alpha",      "Albany",      2,  420000, 87, 85, 71, 73, "Benzin", "Manuel",      "RWD", 0},
    // ---- 3: SEDAN ----
    {426, "Premier",    "Declasse",    3,  120000, 70, 68, 65, 68, "Benzin", "Otomatik",    "RWD", 0},
    {421, "Washington", "Albany",      3,  150000, 68, 66, 66, 66, "Benzin", "Otomatik",    "RWD", 0},
    {445, "Admiral",    "Albany",      3,  160000, 70, 68, 66, 67, "Benzin", "Otomatik",    "RWD", 0},
    {405, "Sentinel",   "Ubermacht",   3,  220000, 74, 72, 68, 72, "Benzin", "Otomatik",    "RWD", 2},
    {507, "Elegant",    "Enus",        3,  200000, 72, 70, 67, 70, "Benzin", "Otomatik",    "RWD", 0},
    {546, "Intruder",   "Vulcar",      3,  140000, 66, 64, 64, 66, "Benzin", "Otomatik",    "FWD", 0},
    {551, "Merit",      "Vapid",       3,  130000, 67, 65, 64, 66, "Benzin", "Otomatik",    "RWD", 0},
    {547, "Primo",      "Albany",      3,  110000, 64, 62, 62, 64, "Benzin", "Otomatik",    "FWD", 0},
    // ---- 4: SUV ----
    {400, "Landstalker","Canis",       4,  280000, 70, 66, 68, 62, "Dizel",  "Otomatik",    "AWD", 0},
    {579, "Huntley",    "Enus",        4,  350000, 74, 70, 70, 64, "Benzin", "Otomatik",    "AWD", 0},
    {489, "Rancher",    "Declasse",    4,  240000, 68, 64, 66, 60, "Dizel",  "Manuel",      "AWD", 0},
    {500, "Mesa",       "Canis",       4,  220000, 66, 62, 64, 60, "Dizel",  "Manuel",      "AWD", 0},
    {470, "Patriot",    "Mammoth",     4,  450000, 72, 66, 72, 62, "Dizel",  "Otomatik",    "AWD", 3},
    {554, "Yosemite",   "Declasse",    4,  260000, 66, 62, 64, 60, "Dizel",  "Manuel",      "RWD", 0},
    {422, "Bobcat",     "Vapid",       4,  180000, 62, 60, 62, 58, "Benzin", "Manuel",      "RWD", 0},
    // ---- 5: OFF-ROAD ----
    {495, "Sandking",   "Vapid",       5,  400000, 76, 72, 68, 66, "Dizel",  "Manuel",      "AWD", 0},
    {424, "BF Injection","Bandito",    5,  200000, 70, 74, 60, 64, "Benzin", "Manuel",      "RWD", 0},
    {573, "Dune",       "Brute",       5,  300000, 60, 62, 62, 56, "Dizel",  "Manuel",      "RWD", 0},
    {505, "Rancher L.", "Declasse",    5,  280000, 70, 66, 66, 62, "Dizel",  "Manuel",      "AWD", 2},
    {471, "Quad",       "Nagasaki",    5,  120000, 62, 70, 52, 66, "Benzin", "Manuel",      "RWD", 0},
    {444, "Monster",    "Vapid",       5,  800000, 58, 60, 56, 40, "Dizel",  "Manuel",      "AWD", 0},
    // ---- 6: MOTOSIKLET ----
    {522, "NRG-500",    "Pegassi",     6,  650000, 95, 96, 70, 90, "Benzin", "Manuel",      "RWD", 0},
    {521, "FCR-900",    "Pegassi",     6,  300000, 86, 88, 66, 86, "Benzin", "Manuel",      "RWD", 0},
    {461, "PCJ-600",    "Shitzu",      6,  280000, 84, 86, 64, 85, "Benzin", "Manuel",      "RWD", 0},
    {468, "Sanchez",    "Maibatsu",    6,  140000, 74, 78, 60, 80, "Benzin", "Manuel",      "RWD", 0},
    {463, "Freeway",    "Western",     6,  180000, 72, 74, 62, 76, "Benzin", "Manuel",      "RWD", 0},
    {581, "BF-400",     "Nagasaki",    6,  220000, 78, 82, 62, 82, "Benzin", "Manuel",      "RWD", 0},
    // ---- 7: KLASIK ----
    {439, "Stallion",   "Declasse",    7,  250000, 76, 74, 66, 66, "Benzin", "Manuel",      "RWD", 0},
    {533, "Feltzer",    "Benefactor",  7,  300000, 74, 72, 66, 70, "Benzin", "Otomatik",    "RWD", 0},
    {410, "Manana",     "Albany",      7,  120000, 62, 60, 60, 62, "Benzin", "Manuel",      "FWD", 0},
    {466, "Glendale",   "Albany",      7,  140000, 64, 62, 62, 64, "Benzin", "Otomatik",    "RWD", 0},
    {527, "Cadrona",    "Albany",      7,  100000, 60, 58, 58, 60, "Benzin", "Manuel",      "FWD", 0},
    {419, "Esperanto",  "Albany",      7,  160000, 66, 64, 62, 64, "Benzin", "Otomatik",    "RWD", 0},
    // ---- 8: LOWRIDER ----
    {536, "Blade",      "Declasse",    8,  220000, 72, 70, 64, 60, "Benzin", "Otomatik",    "RWD", 0},
    {535, "Slamvan",    "Vapid",       8,  260000, 70, 66, 66, 58, "Benzin", "Otomatik",    "RWD", 0},
    {412, "Voodoo",     "Declasse",    8,  200000, 70, 68, 62, 60, "Benzin", "Otomatik",    "RWD", 0},
    {534, "Remington",  "Declasse",    8,  230000, 74, 72, 64, 60, "Benzin", "Otomatik",    "RWD", 0},
    {567, "Savanna",    "Albany",      8,  240000, 72, 70, 64, 60, "Benzin", "Otomatik",    "RWD", 0},
    {576, "Tornado",    "Declasse",    8,  210000, 68, 66, 62, 58, "Benzin", "Otomatik",    "RWD", 0},
    {575, "Broadway",   "Declasse",    8,  215000, 68, 66, 62, 58, "Benzin", "Otomatik",    "RWD", 0},
    // ---- 9: ACIL ----
    {596, "Polis (LS)", "Vapid",       9,  150000, 80, 80, 74, 76, "Benzin", "Otomatik",    "RWD", 0},
    {598, "Polis (SF)", "Vapid",       9,  150000, 80, 80, 74, 76, "Benzin", "Otomatik",    "RWD", 0},
    {416, "Ambulans",   "Brute",       9,  200000, 66, 62, 66, 58, "Dizel",  "Otomatik",    "RWD", 0},
    {407, "Itfaiye",    "Brute",       9,  300000, 58, 52, 58, 46, "Dizel",  "Otomatik",    "RWD", 0},
    {427, "Enforcer",   "Vapid",       9,  400000, 70, 66, 70, 58, "Dizel",  "Otomatik",    "RWD", 0},
    {490, "FBI Rancher","Declasse",    9,  350000, 76, 74, 70, 66, "Benzin", "Otomatik",    "AWD", 0},
    // ---- 10: VIP ----
    {409, "Stretch",    "Albany",     10, 1500000, 74, 66, 68, 56, "Benzin", "Otomatik",    "RWD", 1},
    {494, "Hotring",    "Declasse",   10, 1800000, 99, 98, 85, 92, "Benzin", "Sekvansiyel", "RWD", 1},
    {502, "Hotring A",  "Declasse",   10, 1900000, 99, 98, 85, 93, "Benzin", "Sekvansiyel", "RWD", 1},
    {503, "Hotring B",  "Declasse",   10, 1900000, 99, 98, 85, 93, "Benzin", "Sekvansiyel", "RWD", 1},
    {587, "Euros",      "Dinka",      10, 1000000, 90, 86, 78, 88, "Benzin", "Manuel",      "RWD", 1}
};

new const CatName[GAL_CATS][] =
{
    "Spor Arabalar", "Super Arabalar", "Kasli Arabalar", "Sedanlar",
    "SUV'lar", "Off-Road", "Motosikletler", "Klasik Arabalar",
    "Lowrider", "Acil Araclar", "VIP Araclar", "Favori Araclar"
};

new const SwatchRGBA[GAL_COLS]   = {0x111111FF, 0xFFFFFFFF, 0xC81E1EFF, 0x1E50C8FF, 0x1EA03CFF, 0xF0C814FF};
new const SwatchVehCol[GAL_COLS] = {0, 1, 3, 79, 86, 6};

new const BarLbl[4][] = {"Maksimum Hiz", "Hizlanma", "Fren", "Yol Tutusu"};
new const CamLbl[6][] = {"Yakin", "Uzak", "360", "On", "Arka", "Yan"};
new const BtnLbl[6][] = {"Geri Don (ESC)", "Favorilere Ekle", "Filtre / Ara", "Test Surusu", "SATIN AL", "Karsilastir"};

new GAL_COUNT = 0;

// ------------------------------------------------------------
//  OYUNCU DURUMU
// ------------------------------------------------------------
new bool:G_Open[GAL_P];
new bool:G_InDialog[GAL_P];
new bool:G_Testing[GAL_P];
new bool:G_Spin[GAL_P];
new G_Cat[GAL_P];
new G_Sel[GAL_P];
new G_Page[GAL_P];
new G_Color[GAL_P];
new G_Count[GAL_P];
new G_List[GAL_P][MAX_GAL_VEH];
new bool:G_Fav[GAL_P][MAX_GAL_VEH];
new Float:G_RotZ[GAL_P];
new Float:G_Zoom[GAL_P];
new G_Timer[GAL_P];
new G_FMinP[GAL_P];
new G_FMaxP[GAL_P];
new G_FMinSpd[GAL_P];
new G_FBrand[GAL_P][24];
new G_FSearch[GAL_P][24];
new G_Compare[GAL_P];
new G_BarCur[GAL_P][4];
new G_BarTar[GAL_P][4];
new Float:G_Pos[GAL_P][4];
new G_PosInt[GAL_P];
new G_PosVW[GAL_P];
new G_TestVeh[GAL_P];
new G_TestSec[GAL_P];
new G_TestTimer[GAL_P];
new G_LastBought[GAL_P];

// Textdraw tutaclari
new PlayerText:G_All[GAL_P][MAX_GAL_TD];
new G_AllCnt[GAL_P];
new PlayerText:G_TDTest[GAL_P];

new PlayerText:TD_Name[GAL_P];
new PlayerText:TD_Brand[GAL_P];
new PlayerText:TD_PriceTxt[GAL_P];
new PlayerText:TD_Tag[GAL_P];
new PlayerText:TD_Model[GAL_P];
new PlayerText:TD_IBrand[GAL_P];
new PlayerText:TD_IModel[GAL_P];
new PlayerText:TD_IPrice[GAL_P];
new PlayerText:TD_IFuel[GAL_P];
new PlayerText:TD_IGear[GAL_P];
new PlayerText:TD_IDrive[GAL_P];
new PlayerText:TD_BarPct[GAL_P][4];
new PlayerText:TD_BarFill[GAL_P][4];
new PlayerText:TD_CatBtn[GAL_P][GAL_CATS];
new PlayerText:TD_CatTxt[GAL_P][GAL_CATS];
new PlayerText:TD_Cam[GAL_P][6];
new PlayerText:TD_SwFrame[GAL_P][GAL_COLS];
new PlayerText:TD_Sw[GAL_P][GAL_COLS];
new PlayerText:TD_CardBg[GAL_P][GAL_CARDS];
new PlayerText:TD_CardGlow[GAL_P][GAL_CARDS];
new PlayerText:TD_CardMdl[GAL_P][GAL_CARDS];
new PlayerText:TD_CardName[GAL_P][GAL_CARDS];
new PlayerText:TD_CardPrice[GAL_P][GAL_CARDS];
new PlayerText:TD_CardFav[GAL_P][GAL_CARDS];
new PlayerText:TD_ArrL[GAL_P];
new PlayerText:TD_ArrR[GAL_P];
new PlayerText:TD_Btn[GAL_P][6];
new PlayerText:TD_BtnTxt[GAL_P][6];

// ------------------------------------------------------------
//  YARDIMCI FONKSIYONLAR
// ------------------------------------------------------------
stock FmtMoney(amount, dest[], len = 24)
{
    new s[16], o[24], j = 0, l;
    format(s, sizeof s, "%d", amount);
    l = strlen(s);
    for(new k = 0; k < l; k++)
    {
        if(k > 0 && ((l - k) % 3) == 0)
        {
            o[j] = '.';
            j++;
        }
        o[j] = s[k];
        j++;
    }
    o[j] = 0;
    format(dest, len, "$%s", o);
    return 1;
}

stock Galeri_Fiyat(v)
{
    if(GVeh[v][gTag] == 2) return (GVeh[v][gPrice] * 80) / 100;
    return GVeh[v][gPrice];
}

stock Galeri_ListeYap(playerid)
{
    new n = 0;
    for(new i = 0; i < GAL_COUNT; i++)
    {
        if(G_Cat[playerid] == 11)
        {
            if(!G_Fav[playerid][i]) continue;
        }
        else if(GVeh[i][gCat] != G_Cat[playerid]) continue;

        new fp = Galeri_Fiyat(i);
        if(G_FMinP[playerid] > 0 && fp < G_FMinP[playerid]) continue;
        if(G_FMaxP[playerid] > 0 && fp > G_FMaxP[playerid]) continue;
        if(G_FMinSpd[playerid] > 0 && GVeh[i][gSpd] < G_FMinSpd[playerid]) continue;
        if(G_FBrand[playerid][0] != 0 && strfind(GVeh[i][gBrand], G_FBrand[playerid], true) == -1) continue;
        if(G_FSearch[playerid][0] != 0)
        {
            if(strfind(GVeh[i][gName], G_FSearch[playerid], true) == -1 && strfind(GVeh[i][gBrand], G_FSearch[playerid], true) == -1) continue;
        }
        G_List[playerid][n] = i;
        n++;
    }
    G_Count[playerid] = n;
    return 1;
}

stock Galeri_Kaydet(playerid, PlayerText:t)
{
    if(G_AllCnt[playerid] < MAX_GAL_TD)
    {
        G_All[playerid][G_AllCnt[playerid]] = t;
        G_AllCnt[playerid]++;
    }
    return 1;
}

stock PlayerText:Galeri_Box(playerid, Float:x, Float:y, Float:w, Float:h, color, bool:sel = false)
{
    new PlayerText:t = CreatePlayerTextDraw(playerid, x, y, "_");
    PlayerTextDrawFont(playerid, t, 1);
    PlayerTextDrawLetterSize(playerid, t, 0.0, h / 9.0);
    PlayerTextDrawTextSize(playerid, t, x + w, 0.0);
    PlayerTextDrawUseBox(playerid, t, 1);
    PlayerTextDrawBoxColor(playerid, t, color);
    PlayerTextDrawSetShadow(playerid, t, 0);
    PlayerTextDrawSetOutline(playerid, t, 0);
    if(sel) PlayerTextDrawSetSelectable(playerid, t, true);
    Galeri_Kaydet(playerid, t);
    return t;
}

stock PlayerText:Galeri_Txt(playerid, Float:x, Float:y, const text[], Float:lx, Float:ly, color, font, align)
{
    new PlayerText:t = CreatePlayerTextDraw(playerid, x, y, text);
    PlayerTextDrawLetterSize(playerid, t, lx, ly);
    PlayerTextDrawColor(playerid, t, color);
    PlayerTextDrawFont(playerid, t, font);
    PlayerTextDrawAlignment(playerid, t, align);
    PlayerTextDrawSetShadow(playerid, t, 0);
    PlayerTextDrawSetOutline(playerid, t, 1);
    PlayerTextDrawBackgroundColor(playerid, t, 0x000000FF);
    PlayerTextDrawSetProportional(playerid, t, 1);
    Galeri_Kaydet(playerid, t);
    return t;
}

stock PlayerText:Galeri_Model(playerid, Float:x, Float:y, Float:w, Float:h, model, Float:rx, Float:rz, Float:zoom, vcol, bool:sel = false)
{
    new PlayerText:t = CreatePlayerTextDraw(playerid, x, y, "_");
    PlayerTextDrawFont(playerid, t, 5);
    PlayerTextDrawTextSize(playerid, t, w, h);
    PlayerTextDrawBackgroundColor(playerid, t, 0x00000000);
    PlayerTextDrawSetPreviewModel(playerid, t, model);
    PlayerTextDrawSetPreviewRot(playerid, t, rx, 0.0, rz, zoom);
    PlayerTextDrawSetPreviewVehCol(playerid, t, vcol, vcol);
    if(sel) PlayerTextDrawSetSelectable(playerid, t, true);
    Galeri_Kaydet(playerid, t);
    return t;
}

stock Galeri_Sifirla(playerid)
{
    G_Open[playerid] = false;
    G_InDialog[playerid] = false;
    G_Testing[playerid] = false;
    G_Spin[playerid] = true;
    G_Cat[playerid] = 0;
    G_Sel[playerid] = 0;
    G_Page[playerid] = 0;
    G_Color[playerid] = 0;
    G_Count[playerid] = 0;
    G_RotZ[playerid] = CAM_ON;
    G_Zoom[playerid] = 1.0;
    G_Timer[playerid] = 0;
    G_FMinP[playerid] = 0;
    G_FMaxP[playerid] = 0;
    G_FMinSpd[playerid] = 0;
    G_FBrand[playerid][0] = 0;
    G_FSearch[playerid][0] = 0;
    G_Compare[playerid] = -1;
    G_AllCnt[playerid] = 0;
    G_TestVeh[playerid] = INVALID_VEHICLE_ID;
    G_TestSec[playerid] = 0;
    G_TestTimer[playerid] = 0;
    G_LastBought[playerid] = INVALID_VEHICLE_ID;
    for(new b = 0; b < 4; b++)
    {
        G_BarCur[playerid][b] = 0;
        G_BarTar[playerid][b] = 0;
    }
    for(new i = 0; i < MAX_GAL_VEH; i++) G_Fav[playerid][i] = false;
    return 1;
}

stock Galeri_UIYokEt(playerid)
{
    for(new i = 0; i < G_AllCnt[playerid]; i++) PlayerTextDrawDestroy(playerid, G_All[playerid][i]);
    G_AllCnt[playerid] = 0;
    return 1;
}

stock Galeri_Dialog(playerid, id, style, const caption[], const info[], const b1[], const b2[])
{
    G_InDialog[playerid] = true;
    CancelSelectTextDraw(playerid);
    ShowPlayerDialog(playerid, id, style, caption, info, b1, b2);
    return 1;
}

// ------------------------------------------------------------
//  ONIZLEME / YENILEME
// ------------------------------------------------------------
stock Galeri_Onizleme(playerid)
{
    PlayerTextDrawSetPreviewRot(playerid, TD_Model[playerid], -14.0, 0.0, G_RotZ[playerid], G_Zoom[playerid]);
    PlayerTextDrawShow(playerid, TD_Model[playerid]);
    return 1;
}

stock Galeri_Yenile(playerid)
{
    new cnt = G_Count[playerid];
    new str[96], str2[24];

    if(G_Sel[playerid] >= cnt) G_Sel[playerid] = cnt - 1;
    if(G_Sel[playerid] < 0) G_Sel[playerid] = 0;
    if(G_Sel[playerid] < G_Page[playerid]) G_Page[playerid] = G_Sel[playerid];
    if(G_Sel[playerid] >= G_Page[playerid] + GAL_CARDS) G_Page[playerid] = G_Sel[playerid] - GAL_CARDS + 1;
    if(G_Page[playerid] < 0) G_Page[playerid] = 0;

    // kategori butonlari
    for(new c = 0; c < GAL_CATS; c++)
    {
        if(c == G_Cat[playerid])
        {
            PlayerTextDrawBoxColor(playerid, TD_CatBtn[playerid][c], COL_YEL);
            PlayerTextDrawColor(playerid, TD_CatTxt[playerid][c], 0x000000FF);
        }
        else
        {
            PlayerTextDrawBoxColor(playerid, TD_CatBtn[playerid][c], COL_BTN);
            PlayerTextDrawColor(playerid, TD_CatTxt[playerid][c], COL_WHITE);
        }
        PlayerTextDrawShow(playerid, TD_CatBtn[playerid][c]);
        PlayerTextDrawShow(playerid, TD_CatTxt[playerid][c]);
    }

    // renk cerceveleri
    for(new s = 0; s < GAL_COLS; s++)
    {
        if(s == G_Color[playerid]) PlayerTextDrawBoxColor(playerid, TD_SwFrame[playerid][s], COL_YEL);
        else PlayerTextDrawBoxColor(playerid, TD_SwFrame[playerid][s], 0x00000000);
        PlayerTextDrawShow(playerid, TD_SwFrame[playerid][s]);
    }

    // arac kartlari
    for(new c = 0; c < GAL_CARDS; c++)
    {
        new idx = G_Page[playerid] + c;
        if(idx < cnt)
        {
            new cv = G_List[playerid][idx];
            PlayerTextDrawSetPreviewModel(playerid, TD_CardMdl[playerid][c], GVeh[cv][gModel]);
            PlayerTextDrawSetPreviewVehCol(playerid, TD_CardMdl[playerid][c], SwatchVehCol[cv % GAL_COLS], SwatchVehCol[cv % GAL_COLS]);
            PlayerTextDrawSetString(playerid, TD_CardName[playerid][c], GVeh[cv][gName]);
            FmtMoney(Galeri_Fiyat(cv), str2, sizeof str2);
            PlayerTextDrawSetString(playerid, TD_CardPrice[playerid][c], str2);
            if(G_Fav[playerid][cv]) PlayerTextDrawSetString(playerid, TD_CardFav[playerid][c], "FAV");
            else PlayerTextDrawSetString(playerid, TD_CardFav[playerid][c], " ");

            if(idx == G_Sel[playerid])
            {
                PlayerTextDrawBoxColor(playerid, TD_CardBg[playerid][c], 0x3A2F00E0);
                PlayerTextDrawColor(playerid, TD_CardName[playerid][c], COL_YEL);
                PlayerTextDrawShow(playerid, TD_CardGlow[playerid][c]);
            }
            else
            {
                PlayerTextDrawBoxColor(playerid, TD_CardBg[playerid][c], COL_CARD);
                PlayerTextDrawColor(playerid, TD_CardName[playerid][c], COL_WHITE);
                PlayerTextDrawHide(playerid, TD_CardGlow[playerid][c]);
            }
            PlayerTextDrawShow(playerid, TD_CardBg[playerid][c]);
            PlayerTextDrawShow(playerid, TD_CardMdl[playerid][c]);
            PlayerTextDrawShow(playerid, TD_CardName[playerid][c]);
            PlayerTextDrawShow(playerid, TD_CardPrice[playerid][c]);
            PlayerTextDrawShow(playerid, TD_CardFav[playerid][c]);
        }
        else
        {
            PlayerTextDrawHide(playerid, TD_CardBg[playerid][c]);
            PlayerTextDrawHide(playerid, TD_CardGlow[playerid][c]);
            PlayerTextDrawHide(playerid, TD_CardMdl[playerid][c]);
            PlayerTextDrawHide(playerid, TD_CardName[playerid][c]);
            PlayerTextDrawHide(playerid, TD_CardPrice[playerid][c]);
            PlayerTextDrawHide(playerid, TD_CardFav[playerid][c]);
        }
    }

    // secili arac detaylari
    if(cnt > 0)
    {
        new sv = G_List[playerid][G_Sel[playerid]];
        new col = SwatchVehCol[G_Color[playerid]];

        PlayerTextDrawSetString(playerid, TD_Name[playerid], GVeh[sv][gName]);
        format(str, sizeof str, "%s / %s", GVeh[sv][gBrand], GVeh[sv][gName]);
        PlayerTextDrawSetString(playerid, TD_Brand[playerid], str);
        FmtMoney(Galeri_Fiyat(sv), str2, sizeof str2);
        PlayerTextDrawSetString(playerid, TD_PriceTxt[playerid], str2);
        PlayerTextDrawSetString(playerid, TD_IBrand[playerid], GVeh[sv][gBrand]);
        PlayerTextDrawSetString(playerid, TD_IModel[playerid], GVeh[sv][gName]);
        PlayerTextDrawSetString(playerid, TD_IPrice[playerid], str2);
        PlayerTextDrawSetString(playerid, TD_IFuel[playerid], GVeh[sv][gFuel]);
        PlayerTextDrawSetString(playerid, TD_IGear[playerid], GVeh[sv][gGear]);
        PlayerTextDrawSetString(playerid, TD_IDrive[playerid], GVeh[sv][gDrive]);

        switch(GVeh[sv][gTag])
        {
            case 1:
            {
                PlayerTextDrawSetString(playerid, TD_Tag[playerid], "PREMIUM VIP ARAC");
                PlayerTextDrawColor(playerid, TD_Tag[playerid], 0xFFD700FF);
            }
            case 2:
            {
                FmtMoney(GVeh[sv][gPrice], str2, sizeof str2);
                format(str, sizeof str, "-%%20 INDIRIM!  Eski fiyat: %s", str2);
                PlayerTextDrawSetString(playerid, TD_Tag[playerid], str);
                PlayerTextDrawColor(playerid, TD_Tag[playerid], 0xFF7A1AFF);
            }
            case 3:
            {
                PlayerTextDrawSetString(playerid, TD_Tag[playerid], "YENI ARAC");
                PlayerTextDrawColor(playerid, TD_Tag[playerid], COL_GREEN);
            }
            default:
            {
                PlayerTextDrawSetString(playerid, TD_Tag[playerid], " ");
            }
        }
        PlayerTextDrawShow(playerid, TD_Tag[playerid]);

        G_BarTar[playerid][0] = GVeh[sv][gSpd];
        G_BarTar[playerid][1] = GVeh[sv][gAcc];
        G_BarTar[playerid][2] = GVeh[sv][gBrk];
        G_BarTar[playerid][3] = GVeh[sv][gHnd];

        PlayerTextDrawSetPreviewModel(playerid, TD_Model[playerid], GVeh[sv][gModel]);
        PlayerTextDrawSetPreviewVehCol(playerid, TD_Model[playerid], col, col);
        Galeri_Onizleme(playerid);

        if(G_Fav[playerid][sv]) PlayerTextDrawSetString(playerid, TD_BtnTxt[playerid][1], "Favoriden Cikar");
        else PlayerTextDrawSetString(playerid, TD_BtnTxt[playerid][1], "Favorilere Ekle");
    }
    else
    {
        PlayerTextDrawSetString(playerid, TD_Name[playerid], "ARAC YOK");
        PlayerTextDrawSetString(playerid, TD_Brand[playerid], "Filtreye uygun arac bulunamadi");
        PlayerTextDrawSetString(playerid, TD_PriceTxt[playerid], "$0");
        PlayerTextDrawSetString(playerid, TD_IBrand[playerid], "-");
        PlayerTextDrawSetString(playerid, TD_IModel[playerid], "-");
        PlayerTextDrawSetString(playerid, TD_IPrice[playerid], "-");
        PlayerTextDrawSetString(playerid, TD_IFuel[playerid], "-");
        PlayerTextDrawSetString(playerid, TD_IGear[playerid], "-");
        PlayerTextDrawSetString(playerid, TD_IDrive[playerid], "-");
        PlayerTextDrawSetString(playerid, TD_Tag[playerid], " ");
        PlayerTextDrawHide(playerid, TD_Model[playerid]);
        for(new b = 0; b < 4; b++) G_BarTar[playerid][b] = 0;
        PlayerTextDrawSetString(playerid, TD_BtnTxt[playerid][1], "Favorilere Ekle");
    }
    return 1;
}

stock Galeri_Yeniden(playerid)
{
    G_Sel[playerid] = 0;
    G_Page[playerid] = 0;
    Galeri_ListeYap(playerid);
    Galeri_Yenile(playerid);
    return 1;
}

// ------------------------------------------------------------
//  ARAYUZ KURULUMU
// ------------------------------------------------------------
stock Galeri_UIKur(playerid)
{
    new Float:x, Float:y;
    G_AllCnt[playerid] = 0;

    // --- arka plan ---
    Galeri_Box(playerid, 0.0, 0.0, 640.0, 449.0, 0x00000070);
    Galeri_Box(playerid, 0.0, 0.0, 640.0, 64.0, 0x000000A0);

    // --- logo ---
    Galeri_Txt(playerid, 14.0, 4.0, "DUKTUR RP", 0.55, 2.0, COL_WHITE, 3, 1);
    Galeri_Txt(playerid, 16.0, 34.0, "ROLEPLAY", 0.30, 1.2, COL_YEL, 3, 1);
    Galeri_Txt(playerid, 626.0, 8.0, "SAN ANDREAS", 0.30, 1.2, COL_YEL, 3, 3);
    Galeri_Txt(playerid, 626.0, 24.0, "ARAC GALERISI", 0.20, 0.95, COL_GRAY, 2, 3);

    // --- orta ust: isim / marka / fiyat ---
    TD_Name[playerid] = Galeri_Txt(playerid, 320.0, 2.0, "SULTAN", 0.65, 2.4, COL_WHITE, 3, 2);
    TD_Brand[playerid] = Galeri_Txt(playerid, 320.0, 33.0, "Karin / Sultan", 0.22, 1.0, COL_GRAY, 2, 2);
    Galeri_Box(playerid, 268.0, 46.0, 104.0, 15.0, COL_YEL);
    TD_PriceTxt[playerid] = Galeri_Txt(playerid, 320.0, 47.0, "$0", 0.28, 1.1, 0x000000FF, 2, 2);
    PlayerTextDrawSetOutline(playerid, TD_PriceTxt[playerid], 0);
    TD_Tag[playerid] = Galeri_Txt(playerid, 320.0, 64.0, " ", 0.22, 1.0, COL_WHITE, 2, 2);

    // --- sol panel ---
    Galeri_Box(playerid, 12.0, 70.0, 150.0, 285.0, COL_PANEL);
    Galeri_Txt(playerid, 22.0, 75.0, "Arac Galerisi", 0.30, 1.3, COL_WHITE, 2, 1);
    Galeri_Txt(playerid, 22.0, 90.0, "Hayalindeki araci sec!", 0.17, 0.85, COL_GRAY, 2, 1);
    Galeri_Box(playerid, 16.0, 103.0, 142.0, 2.0, COL_YEL);
    for(new i = 0; i < GAL_CATS; i++)
    {
        y = 108.0 + float(i) * 20.0;
        TD_CatBtn[playerid][i] = Galeri_Box(playerid, 16.0, y, 142.0, 18.0, COL_BTN, true);
        TD_CatTxt[playerid][i] = Galeri_Txt(playerid, 24.0, y + 3.5, CatName[i], 0.22, 1.0, COL_WHITE, 2, 1);
    }

    // --- orta: 3D onizleme ---
    TD_Model[playerid] = Galeri_Model(playerid, 170.0, 84.0, 300.0, 230.0, 560, -14.0, CAM_ON, 1.0, 3);

    // --- kamera butonlari ---
    for(new i = 0; i < 6; i++)
    {
        x = 170.0 + float(i) * 50.0;
        TD_Cam[playerid][i] = Galeri_Box(playerid, x, 322.0, 46.0, 16.0, COL_BTN, true);
        Galeri_Txt(playerid, x + 23.0, 325.0, CamLbl[i], 0.20, 0.95, COL_WHITE, 2, 2);
    }

    // --- renk secimi ---
    Galeri_Txt(playerid, 226.0, 345.0, "Renk:", 0.20, 0.95, COL_GRAY, 2, 1);
    for(new i = 0; i < GAL_COLS; i++)
    {
        x = 262.0 + float(i) * 24.0;
        TD_SwFrame[playerid][i] = Galeri_Box(playerid, x - 2.0, 340.0, 20.0, 18.0, 0x00000000);
        TD_Sw[playerid][i] = Galeri_Box(playerid, x, 342.0, 16.0, 14.0, SwatchRGBA[i], true);
    }

    // --- sag panel: bilgiler ---
    Galeri_Box(playerid, 478.0, 70.0, 148.0, 238.0, COL_PANEL);
    Galeri_Txt(playerid, 486.0, 75.0, "Arac Bilgileri", 0.28, 1.2, COL_WHITE, 2, 1);
    Galeri_Box(playerid, 482.0, 91.0, 140.0, 2.0, COL_YEL);

    Galeri_Txt(playerid, 486.0, 97.0, "Marka", 0.20, 0.95, COL_GRAY, 2, 1);
    TD_IBrand[playerid] = Galeri_Txt(playerid, 618.0, 97.0, " ", 0.20, 0.95, COL_WHITE, 2, 3);
    Galeri_Txt(playerid, 486.0, 110.0, "Model", 0.20, 0.95, COL_GRAY, 2, 1);
    TD_IModel[playerid] = Galeri_Txt(playerid, 618.0, 110.0, " ", 0.20, 0.95, COL_WHITE, 2, 3);
    Galeri_Txt(playerid, 486.0, 123.0, "Fiyat", 0.20, 0.95, COL_GRAY, 2, 1);
    TD_IPrice[playerid] = Galeri_Txt(playerid, 618.0, 123.0, " ", 0.22, 1.0, COL_GREEN, 2, 3);

    for(new b = 0; b < 4; b++)
    {
        y = 142.0 + float(b) * 27.0;
        Galeri_Txt(playerid, 486.0, y, BarLbl[b], 0.20, 0.95, COL_WHITE, 2, 1);
        TD_BarPct[playerid][b] = Galeri_Txt(playerid, 618.0, y, "0%", 0.20, 0.95, COL_WHITE, 2, 3);
        Galeri_Box(playerid, BAR_X, y + 13.0, BAR_W, 5.0, 0x333333FF);
        TD_BarFill[playerid][b] = Galeri_Box(playerid, BAR_X, y + 13.0, 1.0, 5.0, COL_YEL);
    }

    Galeri_Box(playerid, 482.0, 253.0, 140.0, 1.5, 0x555555FF);
    Galeri_Txt(playerid, 486.0, 259.0, "Yakit Turu", 0.20, 0.95, COL_GRAY, 2, 1);
    TD_IFuel[playerid] = Galeri_Txt(playerid, 618.0, 259.0, " ", 0.20, 0.95, COL_WHITE, 2, 3);
    Galeri_Txt(playerid, 486.0, 272.0, "Vites", 0.20, 0.95, COL_GRAY, 2, 1);
    TD_IGear[playerid] = Galeri_Txt(playerid, 618.0, 272.0, " ", 0.20, 0.95, COL_WHITE, 2, 3);
    Galeri_Txt(playerid, 486.0, 285.0, "Cekis Sistemi", 0.20, 0.95, COL_GRAY, 2, 1);
    TD_IDrive[playerid] = Galeri_Txt(playerid, 618.0, 285.0, " ", 0.20, 0.95, COL_WHITE, 2, 3);

    // --- alt: secilen arac kartlari ---
    Galeri_Txt(playerid, 34.0, 358.0, "SECILEN ARAC", 0.25, 1.1, COL_YEL, 3, 1);
    TD_ArrL[playerid] = Galeri_Box(playerid, 4.0, 372.0, 24.0, 58.0, COL_BTN, true);
    Galeri_Txt(playerid, 16.0, 391.0, "<", 0.40, 1.6, COL_YEL, 2, 2);
    TD_ArrR[playerid] = Galeri_Box(playerid, 588.0, 372.0, 32.0, 58.0, COL_BTN, true);
    Galeri_Txt(playerid, 604.0, 391.0, ">", 0.40, 1.6, COL_YEL, 2, 2);

    for(new i = 0; i < GAL_CARDS; i++)
    {
        x = 32.0 + float(i) * 92.0;
        TD_CardBg[playerid][i] = Galeri_Box(playerid, x, 372.0, 88.0, 58.0, COL_CARD, true);
        TD_CardGlow[playerid][i] = Galeri_Box(playerid, x, 368.5, 88.0, 3.0, COL_YEL);
        TD_CardMdl[playerid][i] = Galeri_Model(playerid, x + 4.0, 373.0, 80.0, 36.0, 560, -14.0, CAM_ON, 1.0, 3, true);
        TD_CardName[playerid][i] = Galeri_Txt(playerid, x + 44.0, 409.0, "-", 0.20, 0.95, COL_WHITE, 2, 2);
        TD_CardPrice[playerid][i] = Galeri_Txt(playerid, x + 44.0, 419.0, "-", 0.20, 0.95, COL_GREEN, 2, 2);
        TD_CardFav[playerid][i] = Galeri_Txt(playerid, x + 84.0, 375.0, " ", 0.15, 0.75, 0xFF5C8AFF, 2, 3);
    }

    // --- alt butonlar ---
    for(new i = 0; i < 6; i++)
    {
        x = 10.0 + float(i) * 103.0;
        if(i == 4)
        {
            TD_Btn[playerid][i] = Galeri_Box(playerid, x, 436.0, 98.0, 26.0, COL_YEL, true);
            TD_BtnTxt[playerid][i] = Galeri_Txt(playerid, x + 49.0, 443.0, BtnLbl[i], 0.27, 1.15, 0x000000FF, 2, 2);
            PlayerTextDrawSetOutline(playerid, TD_BtnTxt[playerid][i], 0);
        }
        else
        {
            TD_Btn[playerid][i] = Galeri_Box(playerid, x, 436.0, 98.0, 26.0, COL_BTN, true);
            TD_BtnTxt[playerid][i] = Galeri_Txt(playerid, x + 49.0, 443.0, BtnLbl[i], 0.24, 1.1, COL_WHITE, 2, 2);
        }
    }

    // hepsini goster
    for(new i = 0; i < G_AllCnt[playerid]; i++) PlayerTextDrawShow(playerid, G_All[playerid][i]);
    return 1;
}

// ------------------------------------------------------------
//  AC / KAPAT
// ------------------------------------------------------------
stock Galeri_Ac(playerid, bool:yeni = true)
{
    if(G_Open[playerid]) return 0;

    if(yeni)
    {
        GetPlayerPos(playerid, G_Pos[playerid][0], G_Pos[playerid][1], G_Pos[playerid][2]);
        GetPlayerFacingAngle(playerid, G_Pos[playerid][3]);
        G_PosInt[playerid] = GetPlayerInterior(playerid);
        G_PosVW[playerid] = GetPlayerVirtualWorld(playerid);
        G_Cat[playerid] = 0;
        G_Sel[playerid] = 0;
        G_Page[playerid] = 0;
        G_Color[playerid] = 0;
        G_FMinP[playerid] = 0;
        G_FMaxP[playerid] = 0;
        G_FMinSpd[playerid] = 0;
        G_FBrand[playerid][0] = 0;
        G_FSearch[playerid][0] = 0;
        G_Compare[playerid] = -1;
        G_Zoom[playerid] = 1.0;
        G_RotZ[playerid] = CAM_ON;
        G_Spin[playerid] = true;
    }

    Galeri_ListeYap(playerid);
    Galeri_UIKur(playerid);
    G_Open[playerid] = true;
    for(new b = 0; b < 4; b++) G_BarCur[playerid][b] = 0;
    Galeri_Yenile(playerid);

    TogglePlayerControllable(playerid, 0);
    SelectTextDraw(playerid, COL_YEL);
    G_Timer[playerid] = SetTimerEx("Galeri_Zamanlayici", 70, true, "i", playerid);
    return 1;
}

stock Galeri_Kapat(playerid, bool:kontrol = true)
{
    if(!G_Open[playerid]) return 0;
    G_Open[playerid] = false;
    KillTimer(G_Timer[playerid]);
    CancelSelectTextDraw(playerid);
    Galeri_UIYokEt(playerid);
    if(kontrol) TogglePlayerControllable(playerid, 1);
    return 1;
}

// ------------------------------------------------------------
//  TEST SURUSU
// ------------------------------------------------------------
stock Galeri_TestBitir(playerid, bool:galeriAc = true)
{
    if(!G_Testing[playerid]) return 0;
    G_Testing[playerid] = false;
    KillTimer(G_TestTimer[playerid]);
    PlayerTextDrawDestroy(playerid, G_TDTest[playerid]);

    if(galeriAc)
    {
        SetPlayerVirtualWorld(playerid, G_PosVW[playerid]);
        SetPlayerInterior(playerid, G_PosInt[playerid]);
        SetPlayerPos(playerid, G_Pos[playerid][0], G_Pos[playerid][1], G_Pos[playerid][2]);
        SetPlayerFacingAngle(playerid, G_Pos[playerid][3]);
    }
    if(G_TestVeh[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(G_TestVeh[playerid]);
        G_TestVeh[playerid] = INVALID_VEHICLE_ID;
    }
    if(galeriAc)
    {
        SendClientMessage(playerid, COL_YEL, "[Galeri] Test surusu bitti.");
        Galeri_Ac(playerid, false);
    }
    return 1;
}

stock Galeri_TestBaslat(playerid)
{
    if(G_Count[playerid] < 1) return 0;
    new sv = G_List[playerid][G_Sel[playerid]];
    new col = SwatchVehCol[G_Color[playerid]];

    Galeri_Kapat(playerid, true);
    G_Testing[playerid] = true;

    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    G_TestVeh[playerid] = CreateVehicle(GVeh[sv][gModel], TEST_X, TEST_Y, TEST_Z, TEST_A, col, col, -1);
    PutPlayerInVehicle(playerid, G_TestVeh[playerid], 0);

    G_TestSec[playerid] = GAL_TEST_SURE;
    G_TDTest[playerid] = CreatePlayerTextDraw(playerid, 320.0, 400.0, "Test Surusu: 02:00");
    PlayerTextDrawAlignment(playerid, G_TDTest[playerid], 2);
    PlayerTextDrawFont(playerid, G_TDTest[playerid], 3);
    PlayerTextDrawLetterSize(playerid, G_TDTest[playerid], 0.45, 1.8);
    PlayerTextDrawColor(playerid, G_TDTest[playerid], COL_YEL);
    PlayerTextDrawSetOutline(playerid, G_TDTest[playerid], 1);
    PlayerTextDrawSetProportional(playerid, G_TDTest[playerid], 1);
    PlayerTextDrawShow(playerid, G_TDTest[playerid]);

    G_TestTimer[playerid] = SetTimerEx("Galeri_TestTick", 1000, true, "i", playerid);
    SendClientMessage(playerid, COL_YEL, "[Galeri] Test surusu basladi! Erken bitirmek icin /testbitir yaz.");
    return 1;
}

// ------------------------------------------------------------
//  SATIN ALMA / FAVORI / KARSILASTIR
// ------------------------------------------------------------
stock Galeri_SatinAl(playerid)
{
    if(G_Count[playerid] < 1) return 0;
    new sv = G_List[playerid][G_Sel[playerid]];
    new fiyat = Galeri_Fiyat(sv);

    if(GetPlayerMoney(playerid) < fiyat)
    {
        SendClientMessage(playerid, 0xFF4040FF, "[Galeri] Yeterli paran yok!");
        return 0;
    }

    new model = GVeh[sv][gModel];
    new col = SwatchVehCol[G_Color[playerid]];
    new msg[96], fs[24];

    Galeri_Kapat(playerid, true);
    GivePlayerMoney(playerid, -fiyat);

    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    new veh = CreateVehicle(model, BUY_X, BUY_Y, BUY_Z, BUY_A, col, col, -1);
    PutPlayerInVehicle(playerid, veh, 0);
    G_LastBought[playerid] = veh;

    FmtMoney(fiyat, fs, sizeof fs);
    format(msg, sizeof msg, "[Galeri] %s %s satin aldin! (%s)", GVeh[sv][gBrand], GVeh[sv][gName], fs);
    SendClientMessage(playerid, COL_GREEN, msg);

    CallRemoteFunction("OnGaleriAracSatinAlindi", "iii", playerid, model, fiyat);
    return 1;
}

stock Galeri_FavDegistir(playerid)
{
    if(G_Count[playerid] < 1) return 0;
    new sv = G_List[playerid][G_Sel[playerid]];
    G_Fav[playerid][sv] = !G_Fav[playerid][sv];

    if(G_Fav[playerid][sv]) SendClientMessage(playerid, COL_YEL, "[Galeri] Favorilere eklendi.");
    else SendClientMessage(playerid, COL_YEL, "[Galeri] Favorilerden cikarildi.");

    if(G_Cat[playerid] == 11) Galeri_Yeniden(playerid);
    else Galeri_Yenile(playerid);
    return 1;
}

stock Galeri_Karsilastir(playerid)
{
    if(G_Count[playerid] < 1) return 0;
    new sv = G_List[playerid][G_Sel[playerid]];

    if(G_Compare[playerid] == -1 || G_Compare[playerid] == sv)
    {
        G_Compare[playerid] = sv;
        SendClientMessage(playerid, COL_YEL, "[Galeri] Karsilastirma icin simdi baska bir arac sec ve tekrar Karsilastir'a bas.");
        return 1;
    }

    new a = G_Compare[playerid];
    new info[600], p1[24], p2[24];
    FmtMoney(Galeri_Fiyat(a), p1, sizeof p1);
    FmtMoney(Galeri_Fiyat(sv), p2, sizeof p2);

    format(info, sizeof info,
        "Ozellik\t%s\t%s\nFiyat\t%s\t%s\nMaks. Hiz\t%d%%\t%d%%\nHizlanma\t%d%%\t%d%%\nFren\t%d%%\t%d%%\nYol Tutusu\t%d%%\t%d%%\nYakit\t%s\t%s\nVites\t%s\t%s\nCekis\t%s\t%s",
        GVeh[a][gName], GVeh[sv][gName],
        p1, p2,
        GVeh[a][gSpd], GVeh[sv][gSpd],
        GVeh[a][gAcc], GVeh[sv][gAcc],
        GVeh[a][gBrk], GVeh[sv][gBrk],
        GVeh[a][gHnd], GVeh[sv][gHnd],
        GVeh[a][gFuel], GVeh[sv][gFuel],
        GVeh[a][gGear], GVeh[sv][gGear],
        GVeh[a][gDrive], GVeh[sv][gDrive]);

    G_Compare[playerid] = -1;
    Galeri_Dialog(playerid, DLG_COMPARE, DIALOG_STYLE_TABLIST_HEADERS, "Arac Karsilastirma", info, "Tamam", "");
    return 1;
}

// ------------------------------------------------------------
//  CALLBACKLER
// ------------------------------------------------------------
forward Galeri_Zamanlayici(playerid);
public Galeri_Zamanlayici(playerid)
{
    if(!G_Open[playerid]) return 1;

    if(G_Spin[playerid] && G_Count[playerid] > 0)
    {
        G_RotZ[playerid] += 4.0;
        if(G_RotZ[playerid] >= 360.0) G_RotZ[playerid] -= 360.0;
        Galeri_Onizleme(playerid);
    }

    new str[16];
    for(new b = 0; b < 4; b++)
    {
        if(G_BarCur[playerid][b] == G_BarTar[playerid][b]) continue;

        if(G_BarCur[playerid][b] < G_BarTar[playerid][b])
        {
            G_BarCur[playerid][b] += 4;
            if(G_BarCur[playerid][b] > G_BarTar[playerid][b]) G_BarCur[playerid][b] = G_BarTar[playerid][b];
        }
        else
        {
            G_BarCur[playerid][b] -= 4;
            if(G_BarCur[playerid][b] < G_BarTar[playerid][b]) G_BarCur[playerid][b] = G_BarTar[playerid][b];
        }

        PlayerTextDrawTextSize(playerid, TD_BarFill[playerid][b], BAR_X + 1.0 + (BAR_W - 1.0) * float(G_BarCur[playerid][b]) / 100.0, 0.0);
        PlayerTextDrawShow(playerid, TD_BarFill[playerid][b]);
        format(str, sizeof str, "%d%%", G_BarCur[playerid][b]);
        PlayerTextDrawSetString(playerid, TD_BarPct[playerid][b], str);
    }
    return 1;
}

forward Galeri_TestTick(playerid);
public Galeri_TestTick(playerid)
{
    if(!G_Testing[playerid]) return 1;

    G_TestSec[playerid]--;
    if(G_TestSec[playerid] <= 0 || !IsPlayerInVehicle(playerid, G_TestVeh[playerid]))
    {
        Galeri_TestBitir(playerid, true);
        return 1;
    }
    new s[40];
    format(s, sizeof s, "Test Surusu: %02d:%02d", G_TestSec[playerid] / 60, G_TestSec[playerid] % 60);
    PlayerTextDrawSetString(playerid, G_TDTest[playerid], s);
    return 1;
}

public OnFilterScriptInit()
{
    GAL_COUNT = sizeof(GVeh);
    if(GAL_COUNT > MAX_GAL_VEH) GAL_COUNT = MAX_GAL_VEH;
    for(new i = 0; i < GAL_P; i++) Galeri_Sifirla(i);
    printf("[Galeri] Duktur RP Arac Galerisi yuklendi (%d arac).", GAL_COUNT);
    return 1;
}

public OnFilterScriptExit()
{
    for(new i = 0; i < GAL_P; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(G_Open[i]) Galeri_Kapat(i, true);
        if(G_Testing[i]) Galeri_TestBitir(i, false);
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    if(playerid >= GAL_P) return 1;
    Galeri_Sifirla(playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(playerid >= GAL_P) return 1;
    if(G_Open[playerid])
    {
        G_Open[playerid] = false;
        KillTimer(G_Timer[playerid]);
    }
    if(G_Testing[playerid])
    {
        G_Testing[playerid] = false;
        KillTimer(G_TestTimer[playerid]);
        if(G_TestVeh[playerid] != INVALID_VEHICLE_ID) DestroyVehicle(G_TestVeh[playerid]);
    }
    if(G_LastBought[playerid] != INVALID_VEHICLE_ID) DestroyVehicle(G_LastBought[playerid]);
    Galeri_Sifirla(playerid);
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    if(playerid >= GAL_P) return 1;
    if(G_Open[playerid]) Galeri_Kapat(playerid, true);
    if(G_Testing[playerid]) Galeri_TestBitir(playerid, false);
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if(playerid >= GAL_P) return 0;

    if(!strcmp(cmdtext, "/galeri", true))
    {
        if(G_Open[playerid] || G_Testing[playerid]) return 1;
        if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
        {
            SendClientMessage(playerid, 0xFF4040FF, "[Galeri] Galeriyi acmak icin araktan inmelisin.");
            return 1;
        }
        Galeri_Ac(playerid, true);
        return 1;
    }
    if(!strcmp(cmdtext, "/testbitir", true))
    {
        if(G_Testing[playerid]) Galeri_TestBitir(playerid, true);
        return 1;
    }
    return 0;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(playerid >= GAL_P) return 0;
    if(clickedid == Text:INVALID_TEXT_DRAW)
    {
        if(G_Open[playerid] && !G_InDialog[playerid])
        {
            Galeri_Kapat(playerid, true);
            return 1;
        }
    }
    return 0;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(playerid >= GAL_P || !G_Open[playerid]) return 0;

    // kategoriler
    for(new c = 0; c < GAL_CATS; c++)
    {
        if(playertextid == TD_CatBtn[playerid][c])
        {
            G_Cat[playerid] = c;
            Galeri_Yeniden(playerid);
            return 1;
        }
    }

    // arac kartlari
    for(new c = 0; c < GAL_CARDS; c++)
    {
        if(playertextid == TD_CardBg[playerid][c] || playertextid == TD_CardMdl[playerid][c])
        {
            new idx = G_Page[playerid] + c;
            if(idx < G_Count[playerid])
            {
                G_Sel[playerid] = idx;
                Galeri_Yenile(playerid);
            }
            return 1;
        }
    }

    // onceki / sonraki arac
    if(playertextid == TD_ArrL[playerid])
    {
        if(G_Count[playerid] > 0)
        {
            if(G_Sel[playerid] > 0) G_Sel[playerid]--;
            else G_Sel[playerid] = G_Count[playerid] - 1;
            Galeri_Yenile(playerid);
        }
        return 1;
    }
    if(playertextid == TD_ArrR[playerid])
    {
        if(G_Count[playerid] > 0)
        {
            if(G_Sel[playerid] < G_Count[playerid] - 1) G_Sel[playerid]++;
            else G_Sel[playerid] = 0;
            Galeri_Yenile(playerid);
        }
        return 1;
    }

    // kamera
    for(new c = 0; c < 6; c++)
    {
        if(playertextid == TD_Cam[playerid][c])
        {
            switch(c)
            {
                case 0:
                {
                    G_Zoom[playerid] += 0.15;
                    if(G_Zoom[playerid] > 2.0) G_Zoom[playerid] = 2.0;
                }
                case 1:
                {
                    G_Zoom[playerid] -= 0.15;
                    if(G_Zoom[playerid] < 0.5) G_Zoom[playerid] = 0.5;
                }
                case 2: G_Spin[playerid] = !G_Spin[playerid];
                case 3:
                {
                    G_Spin[playerid] = false;
                    G_RotZ[playerid] = CAM_ON;
                }
                case 4:
                {
                    G_Spin[playerid] = false;
                    G_RotZ[playerid] = CAM_ARKA;
                }
                case 5:
                {
                    G_Spin[playerid] = false;
                    G_RotZ[playerid] = CAM_YAN;
                }
            }
            if(G_Count[playerid] > 0) Galeri_Onizleme(playerid);
            return 1;
        }
    }

    // renkler
    for(new c = 0; c < GAL_COLS; c++)
    {
        if(playertextid == TD_Sw[playerid][c])
        {
            G_Color[playerid] = c;
            Galeri_Yenile(playerid);
            return 1;
        }
    }

    // alt butonlar
    if(playertextid == TD_Btn[playerid][0])
    {
        Galeri_Kapat(playerid, true);
        return 1;
    }
    if(playertextid == TD_Btn[playerid][1])
    {
        Galeri_FavDegistir(playerid);
        return 1;
    }
    if(playertextid == TD_Btn[playerid][2])
    {
        Galeri_Dialog(playerid, DLG_FILTER, DIALOG_STYLE_LIST, "Filtreleme",
            "Arama (isim / marka)\nMarka Filtresi\nMinimum Fiyat\nMaksimum Fiyat\nMinimum Maks. Hiz (%)\nFiltreleri Temizle",
            "Sec", "Geri");
        return 1;
    }
    if(playertextid == TD_Btn[playerid][3])
    {
        Galeri_TestBaslat(playerid);
        return 1;
    }
    if(playertextid == TD_Btn[playerid][4])
    {
        if(G_Count[playerid] < 1) return 1;
        new sv = G_List[playerid][G_Sel[playerid]];

        #if GAL_VIP_KONTROL
        if(GVeh[sv][gTag] == 1 && GetPVarInt(playerid, "VIP") == 0)
        {
            SendClientMessage(playerid, 0xFF4040FF, "[Galeri] Bu arac sadece VIP uyelere ozel!");
            return 1;
        }
        #endif

        new info[200], fs[24];
        FmtMoney(Galeri_Fiyat(sv), fs, sizeof fs);
        format(info, sizeof info, "{FFFFFF}Bu araci satin almak istiyor musun?\n\n{FFC800}Arac:  {FFFFFF}%s %s\n{FFC800}Fiyat: {39D353}%s", GVeh[sv][gBrand], GVeh[sv][gName], fs);
        Galeri_Dialog(playerid, DLG_BUY, DIALOG_STYLE_MSGBOX, "Satin Alma Onayi", info, "Satin Al", "Iptal");
        return 1;
    }
    if(playertextid == TD_Btn[playerid][5])
    {
        Galeri_Karsilastir(playerid);
        return 1;
    }
    return 0;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(playerid >= GAL_P) return 0;
    if(dialogid < DLG_FILTER || dialogid > DLG_COMPARE) return 0;

    G_InDialog[playerid] = false;
    if(!G_Open[playerid]) return 1;

    switch(dialogid)
    {
        case DLG_FILTER:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0: Galeri_Dialog(playerid, DLG_SEARCH, DIALOG_STYLE_INPUT, "Arama", "Arac veya marka adi yaz (bos birak = temizle):", "Ara", "Geri");
                    case 1: Galeri_Dialog(playerid, DLG_BRAND, DIALOG_STYLE_INPUT, "Marka Filtresi", "Marka adi yaz (ornek: Karin, Grotti) (bos = temizle):", "Uygula", "Geri");
                    case 2: Galeri_Dialog(playerid, DLG_MINP, DIALOG_STYLE_INPUT, "Minimum Fiyat", "Minimum fiyat yaz (0 = sinir yok):", "Uygula", "Geri");
                    case 3: Galeri_Dialog(playerid, DLG_MAXP, DIALOG_STYLE_INPUT, "Maksimum Fiyat", "Maksimum fiyat yaz (0 = sinir yok):", "Uygula", "Geri");
                    case 4: Galeri_Dialog(playerid, DLG_SPD, DIALOG_STYLE_INPUT, "Minimum Maks. Hiz", "Minimum hiz yuzdesi yaz (ornek: 90) (0 = sinir yok):", "Uygula", "Geri");
                    case 5:
                    {
                        G_FMinP[playerid] = 0;
                        G_FMaxP[playerid] = 0;
                        G_FMinSpd[playerid] = 0;
                        G_FBrand[playerid][0] = 0;
                        G_FSearch[playerid][0] = 0;
                        Galeri_Yeniden(playerid);
                    }
                }
            }
        }
        case DLG_SEARCH:
        {
            if(response)
            {
                format(G_FSearch[playerid], 24, "%s", inputtext);
                Galeri_Yeniden(playerid);
            }
        }
        case DLG_BRAND:
        {
            if(response)
            {
                format(G_FBrand[playerid], 24, "%s", inputtext);
                Galeri_Yeniden(playerid);
            }
        }
        case DLG_MINP:
        {
            if(response)
            {
                G_FMinP[playerid] = strval(inputtext);
                if(G_FMinP[playerid] < 0) G_FMinP[playerid] = 0;
                Galeri_Yeniden(playerid);
            }
        }
        case DLG_MAXP:
        {
            if(response)
            {
                G_FMaxP[playerid] = strval(inputtext);
                if(G_FMaxP[playerid] < 0) G_FMaxP[playerid] = 0;
                Galeri_Yeniden(playerid);
            }
        }
        case DLG_SPD:
        {
            if(response)
            {
                G_FMinSpd[playerid] = strval(inputtext);
                if(G_FMinSpd[playerid] < 0) G_FMinSpd[playerid] = 0;
                Galeri_Yeniden(playerid);
            }
        }
        case DLG_BUY:
        {
            if(response) Galeri_SatinAl(playerid);
        }
        case DLG_COMPARE:
        {
            // sadece bilgi penceresi
        }
    }

    if(G_Open[playerid] && !G_InDialog[playerid]) SelectTextDraw(playerid, COL_YEL);
    return 1;
}
