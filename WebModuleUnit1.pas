unit WebModuleUnit1;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp, Data.DB, Data.Win.ADODB, dbModule, System.Types, clsEmployee,
  System.Generics.Collections, System.JSON, Rest.Json,Vcl.Dialogs, Variants;

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
    procedure WebModule1CheckForUpdateAnEmployeeAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1UpdateAnEmployeeAction(Sender: TObject;
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

(*------------------------------------------------------------------------------*)

procedure TWebModule1.WebModule1DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.Content :=
    '<html>' +
    '<head><title>Web Server Application</title></head>' +
    '<body>Web Server Application</body>' +
    '</html>';
end;

(*------------------------------------------------------------------------------*)

// Get all Employees
procedure TWebModule1.WebModule1GetAllEmployeesAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  id, age: Integer;
  //name: String;
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

      empDs.Close;
      empDs.CommandText := 'select * from EMPLOYEE';
      empDs.Open;

      empDs.First;

      while not empDs.eof do
      begin

        id := empDs['ID'];

        // ** Errors **
        //name := empDs['NAME'].Value;                        //"..." is not a valid component name (string with space in db)
        //name := empDs['NAME'].AsString;               //invalid variant operation (string with space in db)
        //name := empDs['NAME'];                        //name is unassigned & access violation in salary;  (string without space in db)
        //name := empDs['NAME'].AsString;               //invalid varinat operation (string without space in db)
        //name := empDs.FieldByName('NAME').AsString;   //name is '' & access violation in salary;
        //name := empDs.Fields[1].AsString;            //name is '' & access violation in salary;
        //name := empDs.FieldByName('NAME').Value;       //name is '' & access violation in salary;

        // ** Success **
        //emp.name := empDs['NAME'];   //Success when Temployee.name is public

        salary := empDs['SALARY'];
        age := empDs['AGE'];

        emp := TEmployee.Create();

        emp.SetId(id);
        emp.SetName(empDs['NAME']);
        emp.SetSalary(salary);
        emp.SetAge(age);

        employees.Add(emp);
        empDs.Next;
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

    while(employees.Count > 0) do
    begin

      emp := employees[0];
      FreeAndNil(emp);
      employees.Delete(0);
    end;

    FreeAndNil(employees);

  end;
end;

(*------------------------------------------------------------------------------*)

// Get an Employee
procedure TWebModule1.WebModule1GetAnEmployeeAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  empId: string;
  emp: TEmployee;
  id, age: Integer;
  //name: string;
  salary: Double;

  json: TJSONObject;
  jsdata: TJSONObject;

begin

  empId := GetParameters((Sender as TWebActionItem).PathInfo, Request.PathInfo);

  with DataModule1 do
  begin

      empQr.SQL.Clear;
      empQr.SQL.Add('select * from EMPLOYEE where ID = :id');
      empQr.Parameters.ParamByName('id').Value := empId;
      empQr.Open;

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

  Response.ContentType := 'application/json';
  Response.Content := json.ToString;

  FreeAndNil(emp);

end;


(*------------------------------------------------------------------------------*)

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

    //paramList.Free;

    try  //insert employee to db

      emp := TEmployee.Create;
      emp.SetName(name);
      emp.SetSalary(salary);
      emp.SetAge(age);

      with DataModule1 do
      begin

          empQr.SQL.Clear;
          empQr.SQL.Add('insert into EMPLOYEE (NAME, SALARY, AGE) OUTPUT INSERTED.ID VALUES (:name, :salary, :age)');
          empQr.parameters.ParamByName('name').Value := emp.GetName;
          empQr.parameters.ParamByName('salary').Value := emp.GetSalary;
          empQr.parameters.ParamByName('age').Value := emp.GetAge;
          empQr.Open;

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

  while paramList.Count > 0 do
  begin
    paramList.Objects[0].Free;
    paramList.Delete(0);
  end;

  FreeAndNil(paramList);
  FreeAndNil(emp);
end;

(*------------------------------------------------------------------------------*)

// Check to update an Employee
procedure TWebModule1.WebModule1CheckForUpdateAnEmployeeAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  idStr: String;
  empId: Integer;
  emp: TEmployee;
  resp: TJSONObject;
  jsData: TJSONObject;

begin

  idStr := GetParameters((Sender as TWebActionitem).PathInfo, Request.PathInfo);
  empId := StrToInt(idStr);

  with DataModule1 do
  begin

    try

      empDs.Close;
      empDs.CommandText := 'select * from EMPLOYEE where ID = :id';
      empDs.Parameters.ParamByName('id').Value := empId;
      empDs.Open;

      empDs.First;

      resp := TJSONObject.Create;

      if not VarIsNull(empDs['ID']) then
      begin

        emp:= TEmployee.Create();

        emp.SetId(empDs['ID']);
        emp.SetName(empDs['NAME']);
        emp.SetSalary(empDs['SALARY']);
        emp.SetAge(empDs['AGE']);


        resp.AddPair('status','success');

        jsData := TJSONObject.Create;
        jsData.AddPair('id', emp.GetId.ToString);
        jsData.AddPair('name', emp.GetName);
        jsData.AddPair('salary', emp.GetSalary.ToString);
        jsData.AddPair('age', emp.GetAge.ToString);

        resp.AddPair('data', jsData);
        resp.AddPair('message', 'Employee has been found');

        FreeAndNil(emp);
      end
      else
      begin

        resp.AddPair('status', 'not found');
        resp.AddPair('message', 'Employee not found');

      end;

    except

      resp := TJSONObject.Create;
      resp.AddPair('message', 'Error. Page not found.');

    end;
  end;

  Response.Content := resp.ToString;

end;

(*------------------------------------------------------------------------------*)

// Update an Employee
procedure TWebModule1.WebModule1UpdateAnEmployeeAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  idStr: String;
  empId: Integer;
  empData: TStringList;
  emp: TEmployee;
  affRows: Integer;
  resp: TJSONObject;
  jsData: TJSONObject;

begin

  idStr := GetParameters((Sender as TWebActionItem).PathInfo, Request.Pathinfo);
  empId := StrToInt(idStr);

  empData := GetRequestParameters(Request.Content);

  emp := TEmployee.Create;
  emp.SetId(empId);
  emp.SetName(empData[0]);
  emp.SetSalary(empData[1].ToDouble);
  emp.SetAge(empData[2].ToInteger);

  with DataModule1 do
  begin

    try

      empQr.Close;
      empQr.SQL.Clear;
      empQr.SQL.Add('update EMPLOYEE set NAME = :name, SALARY = :salary, AGE = :age OUTPUT INSERTED.* where ID = :id;');
      empQr.Parameters.ParamByName('name').Value := emp.GetName;
      empQr.Parameters.ParamByName('salary').Value := emp.GetSalary;
      empQr.Parameters.ParamByName('age').Value := emp.GetAge;
      empQr.Parameters.ParamByName('id').Value := emp.GetId;
      empQr.Open;

      resp := TJSONObject.Create;

      if not empQr.FieldByName('ID').IsNull then
      begin

        if not VarIsNull(empQr['ID']) then
          emp.SetId(empQr['ID']);

        if not VarIsNull(empQr['NAME']) then
          emp.SetName(empQr['NAME']);

        if not VarIsNull(empQr['SALARY']) then
          emp.SetSalary(empQr['SALARY']);

        if not VarIsNull(empQr['AGE']) then
          emp.SetAge(empQr['AGE']);

        resp.AddPair('status', 'success');
        jsData := TJSONObject.Create;
        jsData.AddPair('id', emp.GetId.ToString);
        jsData.AddPair('name', emp.GetName);
        jsData.AddPair('salary', emp.GetSalary.ToString);
        jsData.AddPair('age', emp.GetAge.ToString);

        resp.AddPair('data', jsData);

        resp.AddPair('message', 'Employee has been updated');

      end
      else
      begin

        resp.AddPair('status', 'not found');
        resp.AddPair('message', 'Employee not found');

      end;

    except

      resp := TJSONObject.Create;
      resp.AddPair('message', 'page not found');

    end;


  end;

  Response.Content := resp.ToString;

end;

(*------------------------------------------------------------------------------*)

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

(*------------------------------------------------------------------------------*)

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

(*------------------------------------------------------------------------------*)

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

(*------------------------------------------------------------------------------*)

end.
