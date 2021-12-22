unit WebModuleUnit1;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp, Data.DB, Data.Win.ADODB, dbModule, System.Types, clsEmployee,
  System.Generics.Collections, System.JSON, Rest.Json,Vcl.Dialogs;

type
  TWebModule1 = class(TWebModule)
    procedure WebModule1DefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1GetAllEmployeesAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1GetAnEmployeeAction(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1CreateAnEmployeeAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1DeleteAnEmployeeAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);

  private
    { Private declarations }

    function GetParameters(actionPath, fullPath: string): String;
    function GetRequestParameters(reqString: String): TStringList;
  public
    { Public declarations }
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}



procedure TWebModule1.WebModule1DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.Content :=
    '<html>' +
    '<head><title>Web Server Application</title></head>' +
    '<body>Web Server Application</body>' +
    '</html>';
end;


// Get all Employees
procedure TWebModule1.WebModule1GetAllEmployeesAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  id, age: Integer;
  name: string;
  salary: Double;

  employees: TList<TEmployee>;
  emp: TEmployee;

  jsob: TJSONObject;
  jsar: TJSONArray;
  json: TJSONObject;

begin

  employees := TList<TEmployee>.Create;

  with DataModule1 do
  begin

    with empDs do
    begin

      empDs.Close;
      CommandText := 'select * from EMPLOYEE';
      empDs.Open;

      emp := TEmployee.Create();

      First;

      while not eof do
      begin
        emp := TEmployee.Create();

        id := empDs['ID'];

        // ** Errors **
        //name := empDs['NAME'];                        //"..." is not a valid component name (string with space in db)
        //name := empDs['NAME'].AsString;               //invalid variant operation (string with space in db)
        //name := empDs['NAME'];                        //name is unassigned & access violation in salary;  (string without space in db)
        //name := empDs['NAME'].AsString;               //invalid varinat operation (string without space in db)
        //name := empDs.FieldByName('NAME').AsString;   //name is '' & access violation in salary;
        //name := empDs.Fields[1].AsString;            //name is '' & access violation in salary;
        //name := empDs.FieldByName('NAME').Value;       //name is '' & access violation in salary;


        //emp.name := empDs['NAME'];   //Success when Temployee.name is public

        salary := empDs['SALARY'];
        age := empDs['AGE'];

        emp.SetId(id);
        emp.SetName(empDs['NAME']);
        emp.SetSalary(salary);
        emp.SetAge(age);

        employees.Add(emp);
        Next;
      end;

    end;

    json := TJsonObject.Create;
    jsar := TJSONArray.Create;

    try

      for emp in employees do
      begin

      jsob := TJSONObject.Create;
      jsob.AddPair('id', emp.GetId.ToString);
      jsob.AddPair('name', emp.GetName);
      jsob.AddPair('salary', emp.GetSalary.ToString);
      jsob.AddPair('age', emp.GetAge.ToString);

      jsar.AddElement(jsob);
      end;

      json.AddPair('status', 'success');
      json.AddPair('data',jsar);
      json.AddPair('message','Success! All employees have been fetched');

    except

      json.AddPair('status', 'error');
      json.AddPair('message','something went wrong');

    end;

    Response.ContentType := 'application/json';
    Response.Content := json.ToString;

  end;
end;

// Get an Employee
procedure TWebModule1.WebModule1GetAnEmployeeAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  empId: string;
  emp: TEmployee;
  id, age: Integer;
  name: string;
  salary: Double;

  json: TJSONObject;
  jsdata: TJSONObject;

begin

  empId := GetParameters((Sender as TWebActionItem).PathInfo, Request.PathInfo);

  with DataModule1 do
  begin

    with empQr do
    begin

      SQL.Clear;
      SQL.Add('select * from EMPLOYEE where ID = :id');
      Parameters.ParamByName('id').Value := empId;
      Open;

      if not empQr.FieldByName('ID').IsNull then
      begin

        id := empQr['ID'];
        //name := empQr['NAME'].AsString;
        salary := empQr['SALARY'];
        age := empQr['AGE'];

        emp := TEmployee.Create(id, empQr['NAME'], salary, age);

        json := TJSONObject.Create;
        json.AddPair('status', 'success');

        jsData := TJSONObject.Create;
        jsData.AddPair('id', emp.GetId.ToString);
        jsData.AddPair('name', emp.GetName);
        jsData.AddPair('salary', emp.GetSalary.ToString);
        jsData.AddPair('age', emp.GetAge.ToString);

        json.AddPair('data', jsData);
        json.AddPair('message', 'Success! Employee has been found');

      end
      else
      begin

         json := TJSONObject.Create;
         json.AddPair('status', 'error');
         json.AddPair('message', 'Employee not found');
      end;

    end;
  end;

  Response.ContentType := 'application/json';
  Response.Content := json.ToString;

end;

// Create Employee
procedure TWebModule1.WebModule1CreateAnEmployeeAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);

var
  clRequest: string;
  paramList: TStringList;
  id,age: Integer;
  name: String;
  salary: Double;
  emp: TEmployee;

  resp: TJSONObject;
  empData: TJSONObject;

begin

  try //create employee

    clRequest := Request.Content;
    paramList := GetRequestParameters(clRequest);

    name := paramList[0];
    salary := paramList[1].ToDouble;
    age := paramList[2].ToInteger;

    paramList.Free;

    try  //insert employee to db

      emp := TEmployee.Create;
      emp.SetName(name);
      emp.SetSalary(salary);
      emp.SetAge(age);

      with DataModule1 do
      begin

        with empQr do
        begin

          SQL.Clear;
          SQL.Add('insert into EMPLOYEE (NAME, SALARY, AGE) OUTPUT INSERTED.ID VALUES (:name, :salary, :age)');
          parameters.ParamByName('name').Value := emp.GetName;
          parameters.ParamByName('salary').Value := emp.GetSalary;
          parameters.ParamByName('age').Value := emp.GetAge;
          Open;

          id := empQr['ID'];

          emp.SetId(id);

        end;

        resp := TJSONObject.Create;
        if id > 0 then
        begin

          empData := TJSONObject.Create;

          empData.AddPair('name', name);
          empData.AddPair('salary', salary.ToString);
          empData.AddPair('age', age.ToString);
          empData.AddPair('id', id.ToString);

          resp.AddPair('status', 'success');
          resp.AddPair('data', empData);

          Response.Content := resp.ToString;

        end
        else
        begin

          resp.AddPair('message', 'Error');

        end;

      end;

    except

      on e: Exception do
      begin
        ShowMessage('Error on Db insert');
      end;

    end;

  except

    on e: Exception  do
    begin
      ShowMessage('Error on employee creation');
    end;

  end;

end;

// Delete an employee
procedure TWebModule1.WebModule1DeleteAnEmployeeAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  idStr: string;
  empId: Integer;
  emp: TEmployee;

  resp: TJSONObject;

begin

  idStr := GetParameters((Sender as TWebActionItem).PathInfo, Request.PathInfo);
  empId := StrToInt(idStr);

  with DataModule1 do
  begin

    resp := TJSONObject.Create;

    try

      with empQr do
      begin
         //when OUTPUT DELETED.* RowsAffected = -1
        SQL.Clear;
        SQL.Add('delete from EMPLOYEE OUTPUT DELETED.* where ID = :id');
        parameters.paramByName('id').Value := empId;
        Open;

        emp := TEmployee.Create;

        if empQr['ID'] > 0 then
        begin

          emp.SetId(empId);
          emp.SetName(empQr['NAME']);
          emp.SetSalary(empQr['SALARY']);
          emp.SetAge(empQr['AGE']);

          resp.AddPair('status', 'success');
          resp.AddPair('message', 'Employee {' + emp.GetId.ToString + ', ' +
                                  emp.GetName + ', ' + emp.GetSalary.ToString + ', ' +
                                  emp.GetAge.ToString + '} has been deleted');

        end
        else
        begin

          resp.AddPair('status', 'success');
          resp.AddPair('message', 'There is no employee with this ID');

        end;

      end;


    except

       resp.AddPair('message', 'Error Occured!');

    end;

  end;

  Response.Content := resp.ToString;
  FreeAndNil(emp);

end;


// GetParameters for *anEmployee action
function TWebModule1.GetParameters(actionPath: string; fullPath: string): String;
var
  segment: string;

begin

  segment := fullPath;
  actionPath := actionPath.Replace('*','');
  segment := segment.Replace(actionPath, '');
  segment := segment.Replace('/','');

  Result := segment;

end;

// Get Parameters for *createEmployee action
function TWebModule1.GetRequestParameters(reqString: string): TStringList;
var
  paramList: TStringList;
begin

  paramList := TStringList.Create;

  try

    paramList.Delimiter := '&';
    paramList.DelimitedText := reqString;
    paramList.CaseSensitive := True;
    paramList.NameValueSeparator := '=';


    paramList[0] := paramList[0].Replace('name=', '');
    paramList[0] := paramList[0].Replace('%20', ' ');
    paramList[1] := paramList[1].Replace('salary=', '');
    paramList[2] := paramList[2].Replace('age=', '');

  except

    paramList[0] := 'input error';

  end;

  Result := paramList;

end;

end.