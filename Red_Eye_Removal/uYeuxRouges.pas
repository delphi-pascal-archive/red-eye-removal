unit uYeuxRouges;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, uManipBMP, Buttons, ComCtrls, StdCtrls, Math, ExtDlgs, Jpeg;

type
  TForm1 = class(TForm)
    ScrollBox1: TScrollBox;
    Image1: TImage;
    OpenPictureDialog1: TOpenPictureDialog;
    SavePictureDialog1: TSavePictureDialog;
    Label2: TLabel;
    Image2: TImage;
    Label1: TLabel;
    edDiametre: TEdit;
    btnMesurer: TSpeedButton;
    btnCorriger: TSpeedButton;
    btnAnnuler: TSpeedButton;
    btnSauver: TSpeedButton;
    btnOuvrir: TSpeedButton;
    Label3: TLabel;
    labInfo: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnMesurerMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnAnnulerClick(Sender: TObject);
    procedure btnSauverClick(Sender: TObject);
    procedure btnOuvrirClick(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

var       BmpUndo : tBitmap;

procedure TForm1.FormCreate(Sender: TObject);
begin     BmpUndo:=tBitmap.create;
          BmpUndo.Assign(Image1.Picture.BitMap);
          OpenPictureDialog1.InitialDir:=ExtractFilePath(Application.ExeName);
          SavePictureDialog1.InitialDir:=OpenPictureDialog1.InitialDir;
          // WindowState:=wsMaximized;
          labInfo.caption:='';
end;

procedure TForm1.btnMesurerMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var       btn : tSpeedButton;
begin     btn:=Sender as tSpeedButton;
          case btn.Tag of
               1 : labInfo.caption:=' Pour mesurer : Enfoncer le bouton 1, puis cliquer sur deux points diamétralement opposés de la zone à corriger';
               2 : labInfo.caption:=' Pour corriger : Mesurer d''abord le diamètre, puis enfoncer le bouton 2, puis cliquer sur le centre de la zone à corriger';
          end;
end;

var       nbClicks,nbCorr : byte; P1,P2 : tPoint; Diam : integer;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin     if btnMesurer.Down then begin
             inc(nbClicks);
             if Odd(nbClicks) then
             begin
                P1.x:=X; P1.y:=Y;
             end else
             begin P2.x:=X; P2.y:=Y; Diam:=Ceil(Hypot(P2.x-P1.x,P2.y-P1.y));
                   edDiametre.text:=IntToStr(Diam);
                   nbClicks:=0;
             end;
          end;
          if btnCorriger.Down then begin
             inc(nbCorr);
             CorrYeuxRouges(Image1.Picture.bitMap, X,Y,Diam);
             Image1.Repaint;
          end;
end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin     if (nbCorr=2) and (btnCorriger.Down) then begin
                btnCorriger.AllowAllUp:=true;
                btnCorriger.Down:=False;
                nbClicks:=0; nbCorr:=0;
          end;
end;

procedure TForm1.btnAnnulerClick(Sender: TObject);
begin     Image1.Picture.BitMap.Assign(BmpUndo);
          Image1.Repaint;
end;

procedure TForm1.btnSauverClick(Sender: TObject);
var       JP : tJPegImage; EX : string;
begin     with SavePictureDialog1 do begin
               Filter:= 'Fichiers BMP (*.bmp)|*.BMP|Fichiers JPG (*.jpg)|*.JPG';
               if Execute then begin
                  EX:=lowerCase(ExtractFileExt(FileName));
                  if EX='.bmp' then Image1.Picture.BitMap.SaveToFile(FileName) else
                  if EX='.jpg' then begin
                     JP:=JPEGdeBMP(Image1.Picture.BitMap);
                     JP.SaveToFile(FileName);
                     JP.Free;
                  end else ShowMessage('Format '+EX+' : non prévu');
               end;
          end;
end;

procedure TForm1.btnOuvrirClick(Sender: TObject);
begin     with OpenPictureDialog1 do begin
               Filter := GraphicFilter(TGraphic);
               if Execute then begin
                  Image1.Picture.Bitmap.Assign(BMPdeIMG(FileName));
                  BmpUndo.Assign(Image1.Picture.Bitmap);
               end;
          end;
end;

procedure TForm1.FormPaint(Sender: TObject);
//        On va placer un bout de texte incliné avec une ombre réelle
var       Fonte : tFont; i,xt,yt,EpBord : integer; clFond,clOmbreMax,clBord,clD : tColor;
begin     Fonte:=Label2.Font;
          Fonte.size:=72;
          xt:=15; yt:=120;
          clFond:=$00B8C1C7;        //Beige
          clOmbreMax:=RGB(51,25,0); //Marron foncé
          clBord:=clMaroon;
          EpBord:=2;
          for i:=0 to 15 do begin
              clD:=clDegradee( i, 15,clFond,clOmbreMax);
              AffTexteIncliBordeTexture(Canvas,xt,yt,Fonte,clD,EpBord,pmCopy,image2.Picture.BitMap,'Yeux',285);
              dec(xt); dec(yt);
          end;
          AffTexteIncliBordeTexture(Canvas,xt,yt,Fonte,clBord,EpBord-1,pmCopy,image2.Picture.BitMap,'Yeux',285);

end;

initialization

          nbClicks:=0;
          nbCorr:=0;

END.

