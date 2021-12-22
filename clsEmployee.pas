unit clsEmployee;

interface

type TEmployee = class(TObject)
  public name: string;
  private
    id: integer;
    //name: string;
    salary: double;
    age: integer;

  public
    constructor Create; overload;
    constructor Create(anId: Integer; aName: string; aSalary: Double; anAge: Integer); overload;

    procedure SetId(anId: Integer);
    procedure SetName(aName: string);
    procedure SetSalary(aSalary: double);
    procedure SetAge(anAge: Integer);

    function GetId: Integer;
    function GetName: string;
    function GetSalary: double;
    function GetAge: integer;

end;

implementation

constructor TEmployee.Create;
begin
end;

constructor TEmployee.Create(anId: Integer; aName: string; aSalary: Double; anAge: Integer);
begin
  id:= anId;
  name:= aName;
  salary:= aSalary;
  age:= anAge;
end;

procedure TEmployee.SetId(anId: Integer);
begin
  id := anId;
end;

procedure TEmployee.SetName(aName: string);
begin
  name := aName;
end;

procedure TEmployee.SetSalary(aSalary: Double);
begin
  salary := aSalary;
end;

procedure TEmployee.SetAge(anAge: Integer);
begin
  age := anAge;
end;

function TEmployee.GetId: Integer;
begin
  result := id;
end;

function TEmployee.GetName: string;
begin
  result := name;
end;

function TEmployee.GetSalary: Double;
begin
  result := salary;
end;

function TEmployee.GetAge: Integer;
begin
  result := age;
end;

end.

