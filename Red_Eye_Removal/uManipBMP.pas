unit uManipBMP;

               // Conçu sous Delphi-5.

interface

uses Windows, Classes, Forms, Graphics, Sysutils, Dialogs, extdlgs,
     extctrls, Jpeg,  Messages, Controls, Math,
     axCtrls; //<- pour TOleGraphic;

     // Ouvrir un fichier *.BMP, *DIB, *.GIF, *.ICO, *.JIF, *.JPG, *.WMF, ou *.EMF'
     // et le récupérer sous forme d'un BitMap :
     function  BMPdeIMG(const nomFichierImg : string) : tBitMap;
     // Convertir un BitMap en un *.JPG
     function  JPEGdeBMP(const BMP : tBitMap) : TJPEGImage;

     // Conversion RGB <-> HSV
     procedure HSVtoRGB(const H,S,V: integer; var R,G,B: byte); // RGB dans 0..255, H dans 0..360°, S et V dans 0..255
     procedure RGBtoHSV(const R,G,B: byte; var H,S,V: integer);

     // Corriger l'effet "yeux rouges" :
     procedure CorrYeuxRouges(const Bmp : tBitMap; xc,yc,Diametre : integer);

     // Récupérer la valeur d'une couleur dégradée entre deux couleurs
     function  clDegradee( i, DeltaI : integer; clGauche,clDroite : tColor) : tColor;

     // Ecrire sur un canvas un texte incliné, avec ou sans bordure, monochrome ou à face texturée
     procedure AffTexteIncliBordeTexture( C : TCanvas; X,Y : integer; Fonte : tFont;
                                          clBord : TColor; EpBord : integer; PenMode : TPenMode;
                                          Texture : tBitMap; Texte : string; AngleDD : longint);

implementation

function  BMPdeIMG(const nomFichierImg : string) : tBitMap;
const     FormatsSupportes = '.BMP.DIB.GIF.ICO.JIF.JPG.WMF.EMF';
var       OleGraphic: TOleGraphic; FS: TFileStream; ext : string; img : tImage;
begin     if not FileExists(nomFichierImg) then begin
             showMessage(nomFichierImg+' : n''existe pas'); Result:=nil; EXIT;
          end;
          ext:=UpperCase(ExtractFileExt(nomFichierImg));
          if (ext='') or (pos(ext,FormatsSupportes)=0) then
          begin showMessage(ext+' = Format non supporté par BMPdeIMG');
                Result:=nil; EXIT;
          end;
          if ext='.BMP' then begin
             Result :=tBitmap.create;
             Result.PixelFormat:=pf24Bit;
             Result.LoadFromFile(nomFichierImg);
             EXIT;
          end;
          OleGraphic := TOleGraphic.Create;
          FS := TFileStream.Create(nomFichierImg, fmOpenRead or fmSharedenyNone);
          img:= tImage.Create(Application);
          try
             OleGraphic.LoadFromStream(FS);
             img.Picture.Assign(OleGraphic);
             Result :=tBitmap.create;
             with Result do
             begin PixelFormat:=pf24Bit;
                   Width :=img.Picture.Width;
                   Height:=img.Picture.Height;
                   Canvas.Draw(0, 0, img.Picture.Graphic);
             end;
          finally
             fs.Free;
             img.free;
             OleGraphic.Free;
          end;
end; // BMPdeIMG

function JPEGdeBMP(const BMP : tBitMap) : TJPEGImage;
begin    Result:=TJPEGImage.Create;
         try
            with Result do
            begin PixelFormat := jf24Bit;
                  Grayscale   := False;
                  CompressionQuality := 80;
                  Scale := jsFullSize;
                  Assign(BMP);
                  JpegNeeded;
                  Compress;
            end;
            BMP.Dormant;
            BMP.FreeImage;
         except
            on EInvalidGraphic do
            begin Result.Free; Result := nil; end;
         end;
         Application.ProcessMessages;
end;

// HSV RGB ---------------------------------------------------------------------

// RGB = Rouge Vert Bleu intervalle 0..255
// Hue          H = 0° à 360° (correspond à la couleur)
// Saturation   S = 0 (niveau de gris)  à 255 (couleur pure)
// Valeur       V = 0 (noir) à 255 (blanc)

procedure RGBtoHSV(const R,G,B: byte; var H,S,V: integer); // RGB dans 0..255, H dans 0..360°, S et V dans 0..255
var       Delta,Mini : integer;
begin     Mini := min(R, min(G,B));
          V    := max(R, max(G,B));
          Delta := V - Mini;

          // Saturation
          if V =  0 then    // valeur maxi = 0 donc noir
             S := 0 else S := (Delta*255) div V;
          if S  = 0 then    // pas de saturation
             H := 0         // donc niveau de gris
          else
          begin
            if Delta=0 then H:=0; // Maxi = Mini
            if R = V then   // dominante rouge -> entre jaune et violet
               H := ((G-B)*60) div delta
            else
            if G = V then   // dominante verte  -> entre bleu-vert et jaune
               H := 120 + ((B-R)*60) div Delta
            else
            if  B = V then  // dominante bleue  -> entre violet et bleu vert
                H := 240 + ((R-G)*60) div Delta;
            if  H <= 0 then H := H + 360;  // intervalle 0..359°
          end;
end; // RGBtoHSV

function IntToByte(V : Integer) : byte;
begin    if V<0 then Result:=0 else
         if V>255 then Result:=255 else Result:=V;
end;

procedure HSVtoRGB (const H,S,V: integer; var R,G,B: byte); // RGB dans 0..255, H dans 0..360°, S et V dans 0..255
const     d = 255*60;
var       a,hh, p,q,t, vs,Ri,Gi,Bi   : integer;
begin     if (H = 0) or (S = 0) or (V = 0) then      // niveaux de gris
          begin Ri := V; Gi := V; Bi := V; end else // en couleur
          begin if H = 360 then hh := 0 else hh := H;
                a  := hh mod 60;     // a intervalle  0..59
                hh := hh div 60;     // hh intervalle 0..6
                vs := V * S;
                p  := V - vs div 255;              // p = v * (1 - s)
                q  := V - (vs*a) div d;            // q = v * (1 - s*a)
                t  := V - (vs*(60 - a)) div d;     // t = v * (1 - s * (1 - f))
                case hh of
                     0: begin Ri := V; Gi := t ; Bi := p; end;
                     1: begin Ri := q; Gi := V ; Bi := p; end;
                     2: begin Ri := p; Gi := V ; Bi := t; end;
                     3: begin Ri := p; Gi := q ; Bi := V; end;
                     4: begin Ri := t; Gi := p ; Bi := V; end;
                     5: begin Ri := V; Gi := p ; Bi := q; end;
                     else begin Ri := 0; Gi := 0 ; Bi := 0; end;
                end;
          end;
          // Ecrêtage éventuel des composantes
          R:=IntToByte(Ri); G:=IntToByte(Gi); B:=IntToByte(Bi);
end; // HSVtoRGB

// Corriger l'effet "yeux rouges" :
procedure CorrYeuxRouges(const Bmp : tBitMap; xc,yc,Diametre : integer);
// Params : Bmp : BitMap-cible
//          xc,yc : Coordonnées du centre de la zone à corriger
//          Diamètre du cercle circonscrit à la zone à corriger
var       // Le BitMap :
          W,H     : integer;
          Scan0   : Integer;       //Valeur du pointeur d'entrée dans le Bitmap.
          Scan    : Integer;       //Pointeur temporaire destiné à être incrémenté.
          MLS     : Integer;       //Memory Line Size (en bytes) du Bitmap.
          Bpp     : Integer;       //Byte per pixel du Bitmap.
          // Dimensions, positions
          x,y, Ray,e : integer;
          u : extended;
          Hue,Sat,Val, R,G,B, Gris : integer;
          // Cercle
          Surface : integer;
          CoulASupprimer : char;
          ptsHue : array [1..6] of integer; // nombre de points dans les plages Hue du Rouge,Jaune, etc.
          ptsMaxHue : integer; // Nombre de points dans la plage Hue dominante
          iPlageDom : integer; // Indice de la plage Hue dominante
          info : string;

          procedure ComptagesPlageDominante;
          begin     inc(Surface);
                    Scan := Scan0;
                    Inc(Scan, y*MLS + x*Bpp);
                    with PRGBQuad(scan)^ do begin
                         R := RgbRed;
                         G := RgbGreen;
                         B := RgbBlue;  Gris:=(R+G+B) div 3;
                         if (R>128) and (G>128) and (B>128) then EXIT; // Préservation des zones claires
                         if (abs(R-Gris)<24) and (abs(G-Gris)<24) and (abs(B-Gris)<24) then EXIT; // Préservation des zones grisées (reflets)
                         RGBtoHSV( R,G,B, Hue,Sat,Val); //
                         if (Val<=85) and (Sat<=85) then EXIT; // Préservation des zones sombres
                         // Comptages
                         if (Hue>330)  or  (Hue<50)  then inc(ptsHue[1]) else
                         if (Hue>=50)  and (Hue<70)  then inc(ptsHue[2]) else
                         if (Hue>=70)  and (Hue<170) then inc(ptsHue[3]) else
                         if (Hue>=170) and (Hue<200) then inc(ptsHue[4]) else
                         if (Hue>=200) and (Hue<280) then inc(ptsHue[5]) else
                         if (Hue>=280) and (Hue<330) then inc(ptsHue[6]);
                  end;
          end;

          procedure GSPixel; // modifs de couleur
          begin     inc(Surface);
                    Scan := Scan0;
                    Inc(Scan, y*MLS + x*Bpp);
                    with PRGBQuad(scan)^ do begin
                         R := RgbRed;
                         G := RgbGreen;
                         B := RgbBlue;  Gris:=(R+G+B) div 3;
                         if (R>128) and (G>128) and (B>128) then EXIT; // Préservation des zones claires
                         if (abs(R-Gris)<24) and (abs(G-Gris)<24) and (abs(B-Gris)<24) then EXIT; // Préservation des zones grisées (reflets)
                         RGBtoHSV( R,G,B, Hue,Sat,Val); //
                         if (Val<=85) and (Sat<=85) then EXIT; // Préservation des zones sombres
                         case upCase(CoulASupprimer) of
                              'R' : begin if (Hue>330) or (Hue<50) then begin   // Réduction du Rouge
                                             RgbRed  := R div 3;
                                             rgbGreen:= G;
                                             rgbBlue := B;
                                          end;
                                    end;
                              'J','Y' :
                                    begin if (Hue>=50) and (Hue<70) then begin   // Réduction du Jaune
                                             RgbRed  := R div 2;
                                             rgbGreen:= G div 2;
                                             rgbBlue := B;
                                          end;
                                    end;
                              'V','G' :
                                    begin if (Hue>=70) and (Hue<170) then begin   // Réduction du Vert
                                             RgbRed  := R;
                                             rgbGreen:= G div 3;
                                             rgbBlue := B;
                                          end;
                                    end;
                              'C' : begin if (Hue>=170) and (Hue<200) then begin   // Réduction du Cyan
                                             RgbRed  := R;
                                             rgbGreen:= G div 2;
                                             rgbBlue := B div 2;
                                          end;
                                    end;
                              'B' : begin if (Hue>=200) and (Hue<280) then begin   // Réduction du Bleu
                                             RgbRed  := R;
                                             rgbGreen:= G;
                                             rgbBlue := B div 3;
                                          end;
                                    end;
                              'M' : begin if (Hue>=280) and (Hue<330) then begin   // Réduction du Magenta
                                             RgbRed  := R div 2;
                                             rgbGreen:= G;
                                             rgbBlue := B div 2;
                                          end;
                                    end;
                         end;
                  end;
          end;

begin     // Initialisations bitMap
          if BMP.PixelFormat<>pf32bit then BMP.PixelFormat:=pf32bit;
          Bpp   :=4;
          Scan0 := Integer(BMP.ScanLine[0]);
          MLS   := Integer(BMP.ScanLine[1]) - Scan0;
          W     := BMP.Width ;
          H     := BMP.Height;
          // R.à.z ptsHue
          for y:=1 to 6 do ptsHue[y]:=0;
          Ray:=Diametre shr 1;
          // Tour de reconnaissance pour identifier la plage de couleur dominante
          for y:=yc-Ray to yc+Ray do begin
              if (y>=0) and (y<H) then begin
                  e:=y-(yc-Ray); u:=sqrt(sqr(Ray)-sqr(Ray-e));
                  for x:=xc-floor(u) to xc+floor(u)
                  do if (x>=0) and (x<W) and (y>=0) and (y<H) then ComptagesPlageDominante;
              end;
          end;
          ptsMaxHue:=0; iPlageDom:=0;
          for y:=1 to 6 do begin
              if ptsHue[y]>ptsMaxHue then begin
                 iPlageDom:=y; ptsMaxHue:=ptsHue[y];
              end;
          end;
          case iPlageDom of
               1 : begin info:=' à dominante Rouge ('; CoulASupprimer:='R'; end;
               2 : begin info:=' à dominante Jaune ('; CoulASupprimer:='J'; end;
               3 : begin info:=' à dominante Verte ('; CoulASupprimer:='V'; end;
               4 : begin info:=' à dominante Cyan (';  CoulASupprimer:='C'; end;
               5 : begin info:=' à dominante Bleue ('; CoulASupprimer:='B'; end;
               6 : begin info:=' à dominante Magenta ('; CoulASupprimer:='M'; end;
               else begin showMessage('Ce n''était pas un oeil'); EXIT; end;
          end;
          info:=info+FloatToStrF(ptsMaxHue*100/Surface, ffFixed, 7, 2)+' %)';
          if iPlageDom<>1
          then if MessageDlg( 'Cet oeil n''est pas rouge mais '+info+' : Supprimer ?',
                              mtConfirmation, [mbYes, mbNo], 0) = mrNo then EXIT;
          // Correction des couleurs
          for y:=yc-Ray to yc+Ray do begin
              if (y>=0) and (y<H) then begin
                  e:=y-(yc-Ray); u:=sqrt(sqr(Ray)-sqr(Ray-e));
                  for x:=xc-floor(u) to xc+floor(u)
                  do if (x>=0) and (x<W) and (y>=0) and (y<H) then GSPixel;
              end;
          end;
end; // pinYeuxRouges

//        Récupérer la valeur d'une couleur dégradée entre deux couleurs
function  clDegradee( i, DeltaI : integer; clGauche,clDroite : tColor) : tColor;
// Params : i = indice dans l'intervalle 0..DeltaI
//          clGauche = Couleur correspondant à i = 0
//          clDroite = Couleur correspondant à i = DeltaI
var       cdep, cfin : integer;
          Rdep, Gdep, Bdep, Rfin, Gfin, Bfin : integer;
          pr, pg, pb : Extended;
begin     cdep := clGauche; cfin := clDroite;
          if i<0 then i:=0; DeltaI:=abs(DeltaI); if i>DeltaI then i:=DeltaI;
          Rdep := getRvalue(cdep);  Gdep := getGvalue(cdep);  Bdep := getBvalue(cdep);
          Rfin := getRvalue(cfin);  Gfin := getGvalue(cfin);  Bfin := getBvalue(cfin);
          if DeltaI=0 then DeltaI:=1;
          pr := (Rfin-Rdep)/DeltaI; pg := (Gfin-Gdep)/DeltaI;  pb := (Bfin-Bdep)/DeltaI;
          Result:=rgb(round(Rdep+i*pr), round(Gdep+i*pg), round(Bdep+i*pb));
end;

// Ecrire sur un canvas un texte incliné, avec ou sans bordure, monochrome ou à face texturée
procedure AffTexteIncliBordeTexture( C : TCanvas; X,Y : integer; Fonte : tFont;
                                     clBord : TColor; EpBord : integer; PenMode : TPenMode;
                                     Texture : tBitMap; Texte : string; AngleDD : longint);
// params : C = Canvas-cible
//          X,Y = Coordonnées angle supérieur gauche du début du texte.
//          Fonte = Police de caractères à utiliser : uniquement des fontes scalables.
//          clBord = Couleur de la bordure.
//          EpBord = Epaisseur de la bordure.
//          PenMode = TPenMode : utiliser en général pmCopy.
//          Texture = BitMap de texture : Si Texture = Nil alors la face sera monochrome de couleur clBord.
//          Texte   = Texte à écrire.
//          AngleDD = Angle d'inclinaison en Dixièmes de degré.
var	  dc : HDC; lgFont : LOGFONT;  AncFonte,NouvFonte : HFONT;
	  AncPen,NouvPen : HPEN;  AncBrush,NouvBrush : HBRUSH;
begin     C.Pen.Mode:=PenMode;
          dc := C.Handle;
          // initialisation de la fonte
          zeroMemory(@lgFont,sizeOf(lgFont));
          strPCopy(lgFont.lfFaceName,Fonte.Name);
          lgFont.lfHeight := Fonte.Height;
          if Fonte.style=[]       then lgFont.lfWeight:=FW_REGULAR; //Normal
          if Fonte.style=[fsBold] then lgFont.lfWeight:=FW_BOLD;    //Gras

          if fsItalic in Fonte.style    then lgFont.lfItalic:=1;
          if fsUnderline in Fonte.style then lgFont.lfUnderline:=1;
          if fsStrikeout in Fonte.style then lgFont.lfStrikeout:=1;

          lgFont.lfEscapement:=AngleDD; // modification de l'inclinaison

          NouvFonte := CreateFontInDirect(lgFont);
          AncFonte := SelectObject(dc,NouvFonte);
          // initialisation du contour
          if EpBord<>0 then NouvPen := CreatePen(PS_SOLID,EpBord,clBord)
                       else NouvPen := CreatePen(PS_NULL,0,0);
          AncPen := SelectObject(dc,NouvPen);
          // initialisation de la couleur de la police ou de la Texture
          //if HandleTexture=0 then NouvBrush := CreateSolidBrush(Fonte.Color)
          if Texture=nil then NouvBrush := CreateSolidBrush(clBord) //Fonte.Color)
                             //else NouvBrush :=CreatePatternBrush(HandleTexture);   Texture
                         else NouvBrush :=CreatePatternBrush(Texture.Handle);
          AncBrush := SelectObject(dc,NouvBrush);
          // le contexte doit être transparent
          SetBkMode(dc,TRANSPARENT);
          // dessin du texe
          beginPath(dc);
          TextOut(dc,X,Y,PansiChar(Texte),length(texte));
          endPath(dc);
          StrokeAndFillPath(dc);
          // Restauration objets et libération mémoire
          SelectObject(dc,AncFonte);
          DeleteObject(NouvFonte);
          SelectObject(dc,AncPen);
          DeleteObject(NouvPen);
          SelectObject(dc,AncBrush);
          DeleteObject(NouvBrush);
end; // AffTexteIncliBorde



END.
