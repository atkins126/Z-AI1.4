unit FMXDoubleTunnelCliFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Edit,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,

  PasAI.Net.Client.Indy, PasAI.DFE,
  PasAI.Net, PasAI.Core, PasAI.Status,
  PasAI.Net.DoubleTunnelIO.NoAuth;

type
  TFMXDoubleClientForm = class(TForm)
    Memo1: TMemo;
    connectButton: TButton;
    HostEdit: TEdit;
    HelloWorldBtn: TButton;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure connectButtonClick(Sender: TObject);
    procedure HelloWorldBtnClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    procedure DoStatusNear(AText: string; const ID: Integer);

    procedure cmd_ChangeCaption(Sender: TPeerClient; InData: TDataFrameEngine);
    procedure cmd_GetClientValue(Sender: TPeerClient; InData, OutData: TDataFrameEngine);
  public
    { Public declarations }
    RecvTunnel: TZNet_Client_Indy;
    SendTunnel: TZNet_Client_Indy;
    client    : TZNet_DoubleTunnelClient_NoAuth;
  end;

var
  FMXDoubleClientForm: TFMXDoubleClientForm;

implementation

{$R *.fmx}

{ TFMXClientForm }

procedure TFMXDoubleClientForm.cmd_ChangeCaption(Sender: TPeerClient; InData: TDataFrameEngine);
begin
  DoStatus('Change Caption:%s', [InData.Reader.ReadString]);
end;

procedure TFMXDoubleClientForm.cmd_GetClientValue(Sender: TPeerClient; InData, OutData: TDataFrameEngine);
begin
  OutData.WriteString('getclientvalue:abc');
end;

procedure TFMXDoubleClientForm.connectButtonClick(Sender: TObject);
begin
  SendTunnel.Connect(HostEdit.Text, 9815);
  RecvTunnel.Connect(HostEdit.Text, 9816);

  // ���˫ͨ���Ƿ��Ѿ��ɹ����ӣ�ȷ������˶ԳƼ��ܵȵȳ�ʼ������
  while (not client.RemoteInited) and (client.Connected) do
    begin
      TThread.Sleep(10);
      client.Progress;
    end;

  if client.Connected then
    begin
      // �첽��ʽ�ϲ�����ͨ��
      client.TunnelLinkP(
        procedure(const State: Boolean)
        begin
          if State then
            begin
              // ˫ͨ�����ӳɹ�
              DoStatus('double tunnel link success!');
            end;
        end);
      // ͬ����ʽ�ϲ�����ͨ��
      // if client.TunnelLink then
      // begin
      // // ˫ͨ�����ӳɹ�
      // end;
    end;
end;

procedure TFMXDoubleClientForm.DoStatusNear(AText: string; const ID: Integer);
begin
  Memo1.Lines.Add(AText);
  Memo1.GoToTextEnd;
end;

procedure TFMXDoubleClientForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(self, DoStatusNear);

  RecvTunnel := TZNet_Client_Indy.Create;
  SendTunnel := TZNet_Client_Indy.Create;
  client := TZNet_DoubleTunnelClient_NoAuth.Create(RecvTunnel, SendTunnel);

  client.RegisterCommand;

  // ע������ɷ����������ͨѶָ��
  client.RecvTunnel.RegisterDirectStream('ChangeCaption').OnExecute := cmd_ChangeCaption;
  client.RecvTunnel.RegisterStream('GetClientValue').OnExecute := cmd_GetClientValue;
end;

procedure TFMXDoubleClientForm.FormDestroy(Sender: TObject);
begin
  DisposeObject(client);
  DeleteDoStatusHook(self);
end;

procedure TFMXDoubleClientForm.HelloWorldBtnClick(Sender: TObject);
var
  SendDe, ResultDE: TDataFrameEngine;
begin
  // ������������һ��console��ʽ��hello worldָ��
  client.SendTunnel.SendDirectConsoleCmd('helloWorld_Console', '');

  // ������������һ��stream��ʽ��hello worldָ��
  SendDe := TDataFrameEngine.Create;
  SendDe.WriteString('directstream 123456');
  client.SendTunnel.SendDirectStreamCmd('helloWorld_Stream', SendDe);
  DisposeObject([SendDe]);

  // �첽��ʽ���ͣ����ҽ���Streamָ�������proc�ص�����
  SendDe := TDataFrameEngine.Create;
  SendDe.WriteString('123456');
  client.SendTunnel.SendStreamCmdP('helloWorld_Stream_Result', SendDe,
    procedure(Sender: TPeerClient; ResultData: TDataFrameEngine)
    begin
      if ResultData.Count > 0 then
          DoStatus('server response:%s', [ResultData.Reader.ReadString]);
    end);
  DisposeObject([SendDe]);

  // ������ʽ���ͣ����ҽ���Streamָ��
  SendDe := TDataFrameEngine.Create;
  ResultDE := TDataFrameEngine.Create;
  SendDe.WriteString('123456');
  client.SendTunnel.WaitSendStreamCmd('helloWorld_Stream_Result', SendDe, ResultDE, 5000);
  if ResultDE.Count > 0 then
      DoStatus('server response:%s', [ResultDE.Reader.ReadString]);
  DisposeObject([SendDe, ResultDE]);
end;

procedure TFMXDoubleClientForm.Timer1Timer(Sender: TObject);
begin
  client.Progress;
end;

end.