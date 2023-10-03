unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, BufDataset, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, Buttons, StdCtrls, DBGrids, DBCtrls, AsyncProcess, ZConnection,
  ZDataset, SynEdit, SynHighlighterPas;

type

  { TFrmMain }

  TFrmMain = class(TForm)
    BtnPesq: TBitBtn;
    BtnCon: TBitBtn;
    BtnGerarClasses: TBitBtn;
    BtnGerarMetodos: TBitBtn;
    bufTemp: TBufDataset;
    chkCampoGrid: TDBCheckBox;
    chkChavePrimaria: TDBCheckBox;
    dtsTabelas: TDataSource;
    dtsCampos: TDataSource;
    dtsbufTemp: TDataSource;
    dbLkpBancoDados: TEdit;
    EdtTraducao: TDBEdit;
    dbLkpTabelaDados: TDBLookupComboBox;
    lblRotulo: TLabel;
    nvgControle: TDBNavigator;
    grdCampos: TDBGrid;
    EdtNomeDaClasse: TEdit;
    EdtTipoDaClasse: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    lblSelecioneBanco: TLabel;
    lblSelecioneTabela: TLabel;
    OpenDialog1: TOpenDialog;
    PnlBotoes: TPanel;
    PnlEsquerdo: TPanel;
    PnlCentro: TPanel;
    PnlControles: TPanel;
    PnlGrid: TPanel;
    SynCodigo: TSynEdit;
    SynPascal: TSynPasSyn;
    ConDataBase: TZConnection;
    qryTabelas: TZQuery;
    qryCampos: TZQuery;
    procedure BtnConClick(Sender: TObject);
    procedure BtnConExit(Sender: TObject);
    procedure BtnGerarClassesClick(Sender: TObject);
    procedure BtnGerarMetodosClick(Sender: TObject);
    procedure BtnPesqClick(Sender: TObject);
    procedure dbLkpTabelaDadosExit(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    function RetornaTipoCampo:String;
    procedure WhereAndParamsPK;
    function RetornaTipoCampoWithAS:String;
    procedure AddTransaction;
  public

  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.lfm}

{ TFrmMain }

procedure TFrmMain.BtnPesqClick(Sender: TObject);
begin
 OpenDialog1.Execute;

 dbLkpBancoDados.Text := OpenDialog1.FileName;

 if dbLkpBancoDados.Text <> '' then
  BtnCon.Enabled:= True;

end;

procedure TFrmMain.dbLkpTabelaDadosExit(Sender: TObject);
begin
 try
   qryCampos.Close;
   qryCampos.Sql.Clear;
   qryCampos.Sql.Add(' SELECT A.RDB$RELATION_NAME, A.RDB$FIELD_NAME, A.RDB$FIELD_SOURCE,  '+
                     '        A.RDB$FIELD_POSITION, B.RDB$FIELD_TYPE, B.RDB$FIELD_LENGTH FROM RDB$RELATION_FIELDS A '+
                     ' INNER JOIN RDB$FIELDS B ON (A.RDB$FIELD_SOURCE = B.RDB$FIELD_NAME) '+
                     ' WHERE RDB$RELATION_NAME = :NOMETABELA ');

   qryCampos.ParamByName('NOMETABELA').Value := (TDBLookupComboBox(Sender).KeyValue);

   qryCampos.Open;
   qryCampos.First;

   bufTemp.First;
   while not bufTemp.Eof do
     bufTemp.Delete;

   while not qryCampos.Eof do begin
     bufTemp.Append;
     bufTemp.FieldByName('NOMECAMPO').AsString        := qryCampos.FieldByName('RDB$FIELD_NAME').AsString;
     bufTemp.FieldByName('TIPOCAMPO').AsInteger       := qryCampos.FieldByName('RDB$FIELD_TYPE').AsInteger;
     bufTemp.FieldByName('TAMANHO').AsFloat           := (qryCampos.FieldByName('RDB$FIELD_LENGTH').AsFloat / 4);
     bufTemp.FieldByName('CHAVEPRIMARIA').AsBoolean   := False;
     bufTemp.FieldByName('CAMPONOGRID').AsBoolean     := False;
     bufTemp.FieldByName('TRADUCAOCAMPO').AsString    := qryCampos.FieldByName('RDB$FIELD_NAME').AsString;
     bufTemp.Post;

     qryCampos.Next;
   end;
 except
 end;
end;

procedure TFrmMain.FormShow(Sender: TObject);
begin

 bufTemp.FieldDefs.Add('NOMECAMPO',ftString,20);
 bufTemp.FieldDefs.Add('TRADUCAOCAMPO',ftString,20);
 bufTemp.FieldDefs.Add('TIPOCAMPO',ftInteger,0);
 bufTemp.FieldDefs.Add('TAMANHO',ftInteger,0);
 bufTemp.FieldDefs.Add('CHAVEPRIMARIA',ftBoolean);
 bufTemp.FieldDefs.Add('CAMPONOGRID',ftBoolean);
 bufTemp.CreateDataset;

end;

function TFrmMain.RetornaTipoCampo: String;
begin
 if bufTemp.FieldByName('TipoCampo').AsInteger = 8 then
  Result := 'Integer'
else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 10 then
  Result := 'Float'
else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 37 then
  Result := 'String'
else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 14 then
  Result := 'String'
else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 12 then
  Result := 'Date'
{else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 35 then
  Result := 'TimeStamp'}
else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 13 then
  Result := 'Time'
else
  Result := 'Implementar'
end;

procedure TFrmMain.WhereAndParamsPK;
var
  i: Integer;
begin
 with SynCodigo.Lines do begin
   i:=0;
   bufTemp.First;
   while not bufTemp.Eof do begin
     if (bufTemp.FieldByName('CHAVEPRIMARIA').AsBoolean) then begin
       if (i=0) then
          Add('                ''      WHERE '+bufTemp.FieldByName('NOMECAMPO').AsString + '=:'+ bufTemp.FieldByName('NOMECAMPO').AsString+' ''); ')
       else
          Add('                ''        AND '+bufTemp.FieldByName('NOMECAMPO').AsString + '=:'+ bufTemp.FieldByName('NOMECAMPO').AsString+' ''); ');
       inc(i);
     end;
     bufTemp.Next;
   end;

   bufTemp.First;
   while not bufTemp.Eof do begin
     if (bufTemp.FieldByName('CHAVEPRIMARIA').AsBoolean) then begin
         Add('    Qry.ParamByName('+QuotedStr(bufTemp.FieldByName('NOMECAMPO').AsString)+').'+RetornaTipoCampoWithAS+' := Self.F_'+bufTemp.FieldByName('NOMECAMPO').AsString+'; ');
     end;
     bufTemp.Next;
   end;
 end;
end;

function TFrmMain.RetornaTipoCampoWithAS: String;
begin
 if bufTemp.FieldByName('TipoCampo').AsInteger = 8 then
  Result := 'AsInteger'
else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 10 then
  Result := 'AsFloat'
else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 37 then
  Result := 'AsString'
else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 14 then
  Result := 'AsString'
else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 12 then
  Result := 'AsDate'
{else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 35 then
  Result := 'TimeStamp'}
else
 if bufTemp.FieldByName('TipoCampo').AsInteger = 13 then
  Result := 'AsTime'
else
  Result := 'Implementar'
end;

procedure TFrmMain.AddTransaction;
begin
 with SynCodigo.Lines do begin
   Add('    try');
   Add('      ConexaoDB.StartTransaction; ');
   Add('      Qry.ExecSQL;');
   Add('      ConexaoDB.Commit; ');
   Add('    except ');
   Add('      ConexaoDB.Rollback; ');
   Add('      Result := False; ');
   Add('    end;');
 end;
end;

procedure TFrmMain.BtnConClick(Sender: TObject);
begin

 if ConDataBase.Connected = True then
  begin
   ConDataBase.Connected := False;
   ShowMessage('Desconectado');
   Abort;
  end;

 ConDataBase.Connected       := False;
 ConDataBase.SQLHourGlass    := True;
 ConDataBase.Protocol        := 'firebird';

 ConDataBase.Port     :=  3050;
 ConDataBase.User     := 'SYSDBA';
 ConDataBase.Password := 'masterkey';
 ConDataBase.Database := dbLkpBancoDados.Text;

 ConDataBase.AutoCommit := True;

 try
   ConDataBase.Connected  := True;
   ShowMessage('Conectado');
   dbLkpTabelaDados.SetFocus;

   dbLkpTabelaDados.ListSource := dtsTabelas;
   dbLkpTabelaDados.ListField  := 'RDB$RELATION_NAME';
   dbLkpTabelaDados.KeyField   := 'RDB$RELATION_NAME';
   dbLkpTabelaDados.KeyValue   := nil;

   chkChavePrimaria.DataSource := dtsbufTemp;
   chkChavePrimaria.DataField  := 'CHAVEPRIMARIA';

   chkCampoGrid.DataSource     := dtsbufTemp;
   chkCampoGrid.DataField      := 'CAMPONOGRID';

   edtTraducao.DataSource      := dtsbufTemp;
   edtTraducao.DataField       := 'TRADUCAOCAMPO';

   grdCampos.DataSource        := dtsbufTemp;
   nvgControle.DataSource      := dtsbufTemp;


 except
   on E:Exception do
   begin
   ShowMessage(E.Message);
   Abort;
   end;

 end;

end;

procedure TFrmMain.BtnConExit(Sender: TObject);
begin
 try
   qryTabelas.Close;
   qryTabelas.Sql.Clear;
   qryTabelas.SQL.Add('SELECT DISTINCT RDB$RELATION_NAME FROM RDB$RELATION_FIELDS       '+
                       ' WHERE RDB$RELATION_FIELDS.RDB$RELATION_NAME NOT LIKE ''%RDB$%'' '+
                        ' AND RDB$RELATION_FIELDS.RDB$RELATION_NAME NOT LIKE ''%MON$%''   ');

   qryTabelas.Open;

   dbLkpTabelaDados.KeyValue:= nil;

 except
   qryTabelas.Close;
 end;
end;

procedure TFrmMain.BtnGerarClassesClick(Sender: TObject);
var
  i:Integer;
begin
 if bufTemp.State in [dsEdit, dsInsert] then
    bufTemp.Post;

 if bufTemp.IsEmpty then
  begin
   MessageDlg('Não existe campos de tabela definido para a classe',mtWarning,[mbok],0);
   EdtNomeDaClasse.SetFocus;
   Exit;
  end;

 if edtNomeDaClasse.Text=EmptyStr then
  begin
   MessageDlg('Não existe o nome da classe definida',mtWarning,[mbok],0);
   EdtNomeDaClasse.SetFocus;
   exit;
  end;

 if EdtTipoDaClasse.Text=EmptyStr then begin
   MessageDlg('Não existe o Tipo da classe definida',mtWarning,[mbok],0);
   EdtTipoDaClasse.SetFocus;
   Exit;
 end;

 SynCodigo.Lines.Clear;

 With synCodigo.Lines do begin
   Add('unit c'+edtNomeDaClasse.Text+'; ');
   Add('');
   Add('{$mode objfpc}{$H+}   ');
   Add('');
   Add('interface ');
   Add('');
   Add('uses Classes,  ');
   Add('     Controls,');
   Add('     ExtCtrls, ');
   Add('     Dialogs, ');
   Add('     cBase, ');
   Add('     ZAbstractConnection, ');
   Add('     ZConnection, ');
   Add('     ZAbstractRODataset, ');
   Add('     ZAbstractDataset, ');
   Add('     ZDataset, ');
   Add('     SysUtils, ');
   Add('     uUtils; ');
   Add('');
   Add('type ');
   Add('  T'+Copy(EdtTipoDaClasse.Text,1,20)+' = class(TBase)');
   Add('');
   Add('  private ');

   bufTemp.First;
   while not bufTemp.Eof do begin
     SynCodigo.Lines.Add('    F_'+bufTemp.FieldByName('NomeCampo').AsString+':'+RetornaTipoCampo+';');
     bufTemp.Next;
   end;

   With synCodigo.Lines do begin
     Add('  public ');
     Add('    constructor Create(aConexao:TZConnection);');
     Add('    destructor Destroy; override;');
     Add('    function Inserir:Boolean; ');
     Add('    function Atualizar:Boolean; ');
     Add('    function Apagar:Boolean; ');
     Add('    function Selecionar(id:String):Boolean; ');
     Add('');
     Add('  published ');
   end;

   bufTemp.First;
   while not bufTemp.Eof do begin
     SynCodigo.Lines.Add('    property '+bufTemp.FieldByName('NomeCampo').AsString+':' + RetornaTipoCampo +
                         '  read F_'+bufTemp.FieldByName('NomeCampo').AsString+
                         ' write F_'+bufTemp.FieldByName('NomeCampo').AsString+';' );
     bufTemp.Next;
   end;

   with  SynCodigo.Lines do begin
     Add('');
     Add('end;');
     Add('');
     Add('implementation ');
     Add('');
     Add('{T'+EdtTipoDaClasse.Text+'}');

     Add('');
     Add('{$region ''Constructor and Destructor''} ');
     Add('constructor T'+Copy(EdtTipoDaClasse.Text,1,20)+'.Create(aConexao:TZConnection);');
     Add('begin');
     Add('  ConexaoDB:=aConexao; ');
     Add('end;');
     Add('');
     Add('destructor T'+Copy(EdtTipoDaClasse.Text,1,20)+'.Destroy; ');
     Add('begin ');
     Add('  inherited; ');
     Add('end; ');
     Add('{$endRegion} ');
     Add('');

     Add('{$region ''CRUD''} ');
     Add('function T'+Copy(EdtTipoDaClasse.Text,1,20)+'.Apagar: Boolean; ');
     Add('var Qry:TZQuery;   ');
     Add('begin');
     Add('  if MessageNoYes(''Apagar o Registro? '', mtConfirmation)=mrNo then begin ');
     Add('     Result := False;');
     Add('     abort; ');
     Add('  end;');
     Add('  try');
     Add('    Result := True;');
     Add('    Qry:=TZQuery.Create(nil);');
     Add('    Qry.Connection:=ConexaoDB;');
     Add('    Qry.SQL.Clear;');
     Add('    Qry.SQL.Add(''DELETE FROM '+ dbLkpTabelaDados.Text + '''+ ');
     WhereAndParamsPK;
     AddTransaction;
     Add('  finally ');
     Add('   if Assigned(Qry) then ');
     Add('      FreeAndNil(Qry);  ');
     Add('  end;');
     Add('end; ');
     Add('');

     //Atualizar
     Add('function T'+Copy(EdtTipoDaClasse.Text,1,50)+'.Atualizar: Boolean; ');
     Add('var Qry:TZQuery;   ');
     Add('begin');
     Add('  try');
     Add('    Result := True;');
     Add('    Qry:=TZQuery.Create(nil);');
     Add('    Qry.Connection:=ConexaoDB;');
     Add('    Qry.SQL.Clear;');
     Add('    Qry.SQL.Add('' UPDATE '+ dbLkpTabelaDados.Text + '''+ ');
     i:=0;
     bufTemp.First;

     while not bufTemp.Eof do begin
       if (bufTemp.FieldByName('CHAVEPRIMARIA').AsBoolean) then begin
          bufTemp.Next;
          continue;
       end;

       if (i=0) then
          Add('                ''    SET '+bufTemp.FieldByName('NOMECAMPO').AsString + '=:'+ bufTemp.FieldByName('NOMECAMPO').AsString+' ''+ ')
       else
          Add('                ''       ,'+bufTemp.FieldByName('NOMECAMPO').AsString + '=:'+ bufTemp.FieldByName('NOMECAMPO').AsString+' ''+ ');


       inc(i);
       bufTemp.Next;
     end;
     WhereAndParamsPK;

     bufTemp.First;

     while not bufTemp.Eof do begin
       if (bufTemp.FieldByName('CHAVEPRIMARIA').AsBoolean) then begin
          bufTemp.Next;
          continue;
       end;

     Add('    Qry.ParamByName('+QuotedStr(bufTemp.FieldByName('NOMECAMPO').AsString)+').'+RetornaTipoCampoWithAS+' := Self.F_'+bufTemp.FieldByName('NOMECAMPO').AsString+'; ');

     bufTemp.Next;
     end;

     AddTransaction;
     Add('  finally ');
     Add('   if Assigned(Qry) then ');
     Add('      FreeAndNil(Qry);  ');
     Add('  end;');
     Add('end; ');
     Add('');

     Add('function T'+Copy(EdtTipoDaClasse.Text,1,50)+'.Inserir: Boolean; ');
     Add('var Qry:TZQuery;   ');
     Add('begin');
     Add('  try');
     Add('    Result:=true;');
     Add('    Qry:=TZQuery.Create(nil);');
     Add('    Qry.Connection:=ConexaoDB;');
     Add('    Qry.SQL.Clear;');
     Add('    Qry.SQL.Add('' INSERT INTO '+ dbLkpTabelaDados.Text + ' (''+ ');  // mexer aqui

     i:=0;
     bufTemp.First;
     while not bufTemp.Eof do begin
       if (i=0) then begin
          Add('                ''      '+bufTemp.FieldByName('NOMECAMPO').AsString + '''+ ');
       end
       else
          Add('                ''      ,'+bufTemp.FieldByName('NOMECAMPO').AsString + '''+ ');

       inc(i);
       bufTemp.Next;
     end;
     Add('               '+' '')''); ');
     Add('    Qry.SQL.Add('' VALUES (''+ ');

     i:=0;
     bufTemp.First;

     while not bufTemp.Eof do begin
       if (i=0) then begin
          Add('                ''      :'+bufTemp.FieldByName('NOMECAMPO').AsString + ' ''+ ');
       end
       else
          Add('                ''      ,:'+bufTemp.FieldByName('NOMECAMPO').AsString + ' ''+ ');

       inc(i);
       bufTemp.Next;
     end;
     Add('               '+' '')''); ');

     bufTemp.First;

     while not bufTemp.Eof do begin
       if (bufTemp.FieldByName('CHAVEPRIMARIA').AsBoolean) then begin
         Add('    Qry.ParamByName('+QuotedStr(bufTemp.FieldByName('NOMECAMPO').AsString)+').'+RetornaTipoCampoWithAS+' := GuidId; ');
       end
       else
         Add('    Qry.ParamByName('+QuotedStr(bufTemp.FieldByName('NOMECAMPO').AsString)+').'+RetornaTipoCampoWithAS+' := Self.F_'+bufTemp.FieldByName('NOMECAMPO').AsString+'; ');

       bufTemp.Next;
     end;

     AddTransaction;
     Add('  finally ');
     Add('   if Assigned(Qry) then ');
     Add('      FreeAndNil(Qry);  ');
     Add('  end;');
     Add('end; ');

     Add('function T'+Copy(EdtTipoDaClasse.Text,1,50)+'.Selecionar(id:string): Boolean; ');
     Add('var Qry:TZQuery;   ');
     Add('begin');
     Add('  try');
     Add('    Result:=true;');
     Add('    Qry:=TZQuery.Create(nil);');
     Add('    Qry.Connection:=ConexaoDB;');
     Add('    Qry.SQL.Clear;');
     Add('    Qry.SQL.Add('' SELECT ''+ ');

     i:=0;
     bufTemp.First;

     while not bufTemp.Eof do begin
       if (i=0) then begin
          Add('                ''      '+bufTemp.FieldByName('NOMECAMPO').AsString + ' ''+ ');
       end
       else
          Add('                ''      ,'+bufTemp.FieldByName('NOMECAMPO').AsString +' ''+ ');

       inc(i);
       bufTemp.Next;
     end;
     Add('                '' FROM '+dbLkpTabelaDados.Text +''' + ');

     i:=0;
     bufTemp.First;

     while not bufTemp.Eof do begin
         if (bufTemp.FieldByName('CHAVEPRIMARIA').AsBoolean) then begin
            Add('                '' WHERE '+bufTemp.FieldByName('NOMECAMPO').AsString + '=:id '');');
        end;
        inc(i);
        bufTemp.Next;
      end;
      Add('    Qry.ParamByName(''Id'').AsString:=id; ');


      Add('    Qry.Open; ');

      bufTemp.First;

      while not bufTemp.Eof do begin
        Add('    Self.F_'+bufTemp.FieldByName('NOMECAMPO').AsString+' := '+ 'Qry.FieldByName('+ QuotedStr(bufTemp.FieldByName('NOMECAMPO').AsString)+').'+RetornaTipoCampoWithAS+'; ');
        bufTemp.Next;
      end;

      Add('  finally ');
      Add('   if Assigned(Qry) then ');
      Add('      FreeAndNil(Qry);  ');
      Add('  end;');
      Add('end; ');


      Add('{$endRegion} ');
      Add('end. ');
    end;

  end;

 end;

procedure TFrmMain.BtnGerarMetodosClick(Sender: TObject);
var i:Integer;
begin
 if bufTemp.State in [dsEdit, dsInsert] then
    bufTemp.Post;

 if bufTemp.IsEmpty then begin
   MessageDlg('Não existe campos de tabela definido para a classe',mtWarning,[mbok],0);
   edtNomeDaClasse.SetFocus;
   exit;
 end;

 if edtNomeDaClasse.Text=EmptyStr then begin
   MessageDlg('Não existe o nome da classe definida',mtWarning,[mbok],0);
   edtNomeDaClasse.SetFocus;
   exit;
 end;

 if EdtTipoDaClasse.Text=EmptyStr then begin
   MessageDlg('Não existe o tipo da classe definida',mtWarning,[mbok],0);
   EdtTipoDaClasse.SetFocus;
   exit;
 end;

 SynCodigo.Lines.Clear;
 With SynCodigo.Lines do begin
   Add('  public   ');
   Add('    o'+EdtTipoDaClasse.Text+':T'+EdtTipoDaClasse.Text+'; ');
   Add('    function Gravar(aEstadoDoCadastro:TEstadoDoCadastro):boolean; override; ');
   Add('    function Apagar:Boolean; override; ');
   Add('    procedure ConfigurarCampos; override; ');
   Add('  end; ');
   Add(' ');
   Add(' ');

   Add('{$region ''Metodos Override''} ');
   Add('procedure Tfrm'+Copy(edtNomeDaClasse.Text,1,20)+'.ConfigurarCampos; ');
   Add('begin');

   i:=0;
   bufTemp.First;
   while not bufTemp.Eof do begin
     if (bufTemp.FieldByName('CAMPONOGRID').AsBoolean) then begin
        Add('  qryListagem.Fields['+i.ToString()+'].DisplayLabel:='+QuotedStr(bufTemp.FieldByName('TRADUCAOCAMPO').AsString)+';');
        inc(i);
     end;
     bufTemp.Next;
   end;
   Add(' ');

   i:=0;
   bufTemp.First;
   while not bufTemp.Eof do begin
     if (bufTemp.FieldByName('CAMPONOGRID').AsBoolean) then begin
        Add('  grdListagem.Columns.Add(); ');
        Add('  grdListagem.Columns['+i.ToString()+'].FieldName:='+QuotedStr(bufTemp.FieldByName('NOMECAMPO').AsString)+';');
        Add('  grdListagem.Columns['+i.ToString()+'].Width:='+bufTemp.FieldByName('TAMANHO').AsString+';');
        Add(' ');
        inc(i);
     end;
     bufTemp.Next;
   end;
   Add('end;');
   Add(' ');

   Add('function Tfrm'+Copy(edtNomeDaClasse.Text,1,20)+'.Gravar(aEstadoDoCadastro: TEstadoDoCadastro): boolean; ');
   Add('begin');
   Add('  if EstadoDoCadastro=ecInserir then ');
   Add('     Result:= o'+Copy(EdtTipoDaClasse.Text,1,20)+'.Inserir    ');
   Add('  else if EstadoDoCadastro=ecAlterar then ');
   Add('     Result:= o'+Copy(EdtTipoDaClasse.Text,1,20)+'.Atualizar; ');
   Add('end;');

   Add(' ');
   Add('function Tfrm'+Copy(edtNomeDaClasse.Text,1,20)+'.Apagar: boolean; ');
   Add('begin');
   bufTemp.First;
   while not bufTemp.Eof do begin
     if (bufTemp.FieldByName('CHAVEPRIMARIA').AsBoolean) then begin
        Add('  if o'+Copy(EdtTipoDaClasse.Text,1,20)+'.Selecionar(QryListagem.FieldByName('+ QuotedStr(bufTemp.FieldByName('NOMECAMPO').AsString)+').AsString) then  ');
        Add('     Result:= o'+Copy(EdtTipoDaClasse.Text,1,20)+'.Apagar    ');
        Break;
     end;
     bufTemp.Next;
   end;
   Add('end;');

   Add('{$endRegion} ');

   Add(' ');
   Add('procedure Tfrm'+Copy(edtNomeDaClasse.text,1,20)+'.FormClose(Sender: Tobject; var CloseAction: TCloseAction);');
   Add('begin');
   Add(' inherited; ');
   Add(' if Assigned(o'+Copy(edtTipoDaClasse.text,1,20)+') then ');
   Add('  FreeAndNil(o'+Copy(edtTipoDaClasse.text,1,20)+');     ');
   Add('end;');

   Add(' ');
   Add('procedure Tfrm'+Copy(edtNomeDaClasse.text,1,20)+'.FormCreate(Sender: Tobject);');
   Add('begin');
   Add('  o'+Copy(edtTipoDaClasse.text,1,20)+':= T'+Copy(edtTipoDaClasse.text,1,20)+'.Create(DtmPrincipal.ConDatabase);');
   Add('  IndiceAtual:=; ');
   Add('  inherited; ');
   Add('end;');

   Add(' ');
   Add('========================');
   bufTemp.First;
   while not bufTemp.Eof do begin
   Add(' o'+Copy(edtTipoDaClasse.text,1,20)+'.'+bufTemp.FieldByName('NOMECAMPO').AsString+':= ');
   bufTemp.Next;
   end;

   Add(' ');
   Add('========================');
   bufTemp.First;
   while not bufTemp.Eof do begin
   Add(' := o'+Copy(edtTipoDaClasse.text,1,20)+'.'+bufTemp.FieldByName('NOMECAMPO').AsString+';');
   bufTemp.Next;
   end;

 end;

end;


end.

