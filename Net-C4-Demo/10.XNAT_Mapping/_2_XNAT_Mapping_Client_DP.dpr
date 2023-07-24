program _2_XNAT_Mapping_Client_DP;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.UnicodeMixedLib,
  PasAI.Status,
  PasAI.MemoryStream,
  PasAI.Notify,
  PasAI.Net,
  PasAI.Net.PhysicsIO,
  PasAI.Net.C4,
  PasAI.Net.C4_XNAT,
  PasAI.Net.XNAT.Client, PasAI.Net.XNAT.MappingOnVirutalService, PasAI.Net.XNAT.Service, PasAI.Net.XNAT.Physics,
  PasAI.Net.C4_Console_APP;

var
  exit_signal: Boolean;

procedure Do_Check_On_Exit;
var
  n: string;
  cH: TC40_Console_Help;
begin
  cH := TC40_Console_Help.Create;
  repeat
    TCompute.Sleep(100);
    Readln(n);
    cH.Run_HelpCmd(n);
  until cH.IsExit;
  disposeObject(cH);
  exit_signal := True;
end;

const
  Internet_XNAT_Service_Addr_ = '127.0.0.1';
  Internet_XNAT_Service_Port_ = 8397;
  Internet_XNAT_Service_Port_DP_ = 8888;

begin
  RegisterC40('MY_XNAT_1', TC40_XNAT_Service_Tool, TC40_XNAT_Client_Tool);

  PasAI.Net.C4.C40_QuietMode := False;
  PasAI.Net.C4.C40_PhysicsTunnelPool.GetOrCreatePhysicsTunnel(Internet_XNAT_Service_Addr_, Internet_XNAT_Service_Port_, 'MY_XNAT_1', nil);

  // ��XNAT���÷��������Ȼ��ʹ��Զ�̵�ַӳ���Ϊ���� TXNAT_MappingOnVirutalService
  // TXNAT_MappingOnVirutalService�볣��Server�÷�һ�£�����ҪXNAT�ظ�������
  PasAI.Net.C4.C40_ClientPool.WaitConnectedDoneP('MY_XNAT_1', procedure(States_: TC40_Custom_ClientPool_Wait_States)
    var
      XNAT_Cli: TC40_XNAT_Client_Tool;
    begin
      if length(States_) = 0 then
          exit;
      // ��C4�����ȡ TDTC40_XNAT_Client_Tool
      XNAT_Cli := TC40_XNAT_Client_Tool(States_[0].Client_);
      // ����Զ������
      XNAT_Cli.Add_XNAT_Mapping(True, Internet_XNAT_Service_Port_DP_, 'test', 5000);
      // Open_XNAT_Tunnel����Զ��XNAT���÷�������XNAT���ѽ������ӵ�XNATϵͳ��ȫ�����ߣ���XNAT����������ɺ�XNAT����Զ���������
      // ʹ��C4��XNAT���÷���ʱ��Ҫ��̫�ഩ͸��1-2���͹��ˣ������Ҫ�ഩ���Ͷ࿪�������÷���
      XNAT_Cli.Open_XNAT_Tunnel;
      // ���� TXNAT_MappingOnVirutalService
      XNAT_Cli.Build_Physics_ServiceP('test', 1000,
        procedure(Sender: TC40_XNAT_Client_Tool; Service: TXNAT_MappingOnVirutalService)
        begin
          if Service = nil then
              exit;
          // ʹ��TXNAT_MappingOnVirutalService��Զ�̽�����͸��ӳ�䵽����
          with PasAI.Net.C4.TC40_PhysicsService.Create(Internet_XNAT_Service_Addr_, Internet_XNAT_Service_Port_DP_, Service) do
            begin
              BuildDependNetwork('DP');
              StartService;
            end;
          // ��ͨ���ȶ�
          PasAI.Net.C4.C40_PhysicsTunnelPool.GetOrCreatePhysicsTunnel(Internet_XNAT_Service_Addr_, Internet_XNAT_Service_Port_DP_, 'DP', nil);
        end);
    end);

  // ��ѭ��
  StatusThreadID := False;
  exit_signal := False;
  TCompute.RunC_NP(@Do_Check_On_Exit);
  while not exit_signal do
      PasAI.Net.C4.C40Progress;

  PasAI.Net.C4.C40Clean;
end.