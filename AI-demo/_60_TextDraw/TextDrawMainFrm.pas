unit TextDrawMainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,

  PasAI.Core, PasAI.PascalStrings, PasAI.DrawEngine, PasAI.DrawEngine.SlowFMX, PasAI.Geometry2D;

type
  TTextDrawMainForm = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    drawIntf: TDrawEngineInterface_FMX;
    angle: TDEFloat;
  end;

var
  TextDrawMainForm: TTextDrawMainForm;

implementation

{$R *.fmx}


procedure TTextDrawMainForm.FormCreate(Sender: TObject);
begin
  drawIntf := TDrawEngineInterface_FMX.Create;
  angle := 0;
end;

procedure TTextDrawMainForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
  n: string;
begin
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);
  // voFPS:��ʾÿ��֡��
  // voEdge:��ʾ�߽�
  // voTextBox:��ʾ�ı���
  d.ViewOptions := [voFPS, voEdge { , voTextBox } ];
  d.FillBox(d.ScreenRect, DEColor(0.5, 0.5, 0.5));

  // �ı�����ʽ��һ�ֽű����﷨Ϊ |�ű�|�ı����ű�������|��ͷ������|���������ű�����������ı�����
  // size:xx�������ĳߴ磬ͬ��Ҳ����д��|s:xx|
  // color(r,g,b,a)����ɫ
  // |color(1,0,0,1)|xx������ɫ����xx��Ҳ����д��|red:1|xx
  // |color(255,0,0,255)|xx������ɫ����xx�������������ֵ����1.0��byte��ֵ
  // |s:11|����ʾʹ��11��size��color���Զ�ʹ�õ���drawText�ĳ���
  // |color(1,1,1,1)|,��ʾ���ɰ�ɫ�����֣����ڽű���û�и��������ֵ��ֺţ�ʹ�õ���drawText�ĳ���
  // || �սű���ʾʹ��Ĭ���ı�size+color��
  // |bk(����ɫ)����|
  n := '|size:24|24�ֺŵĴ���|| |s:16|16�ֺŵ�С��' + #13#10 +
    '|color(1,0,0,1),size:24|24�ֺŵĺ�ɫ��|| Ĭ������ |color(0,1,0,1),size:50|�ش�����'+#13#10+
    '|bk(0,0,0,0.8)|��������||';

  // ��һ����:��ֹangleϵ���ڶ�������ʱ��ù���ʧ����
  angle := NormalizeDegAngle(angle + 30 * d.LastDeltaTime);
  // angle := angle + 15 * d.LastDeltaTime;

  // ��ʼ����Ӱ��,Vec2(2,5)��Ӱ�ӵ�ƫ����
  // BeginCaptureShadowֻ�����ֺ�ͼƬ��Ч����shapeͼ����Ч
  d.BeginCaptureShadow(vec2(2, 5), 0.9);

  // �ı�����ʽ�ڻ���ʱ��ʹ��zExpression��cache���ƣ���Ƶ�ʻ��Ʋ��ᷴ���������ʽ
  d.DrawText(
    n,                   // �ı�
    12,                  // �ı�size
    d.ScreenRect,        // �����ֵĿ���
    DEColor(1, 1, 1, 1), // ������ɫ
    True,                // �����Ƿ����
    vec2(0.5, 0.5),      // ��ת���ģ��߶�����ϵ��vec2(0.5,0.5)��ʾ���룬vec2(0,0)��ʾ���ϣ�vec2(1,1)��ʾ����
    angle                // ��ת�Ƕ�
    );

  // ����Ӱ�Ӳ���
  d.EndCaptureShadow;

  // �����Fillbox,DrawText��Щ�����ڵ���ʱ�������������ƶ��Ǵ�ŵ�һ��command list����
  // flush�����ǽ�command list���е���������������
  // command list��һ�������Ż����ƣ���ͨ��������һ�������̣߳���flush�����һ����һ���̣߳�������Ƴ����ڸ߼������Ż�
  d.Flush;
end;

procedure TTextDrawMainForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  EnginePool.Progress();
  Invalidate;
end;

end.