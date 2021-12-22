object WebModule1: TWebModule1
  OldCreateOrder = False
  Actions = <
    item
      Default = True
      Name = 'DefaultHandler'
      PathInfo = '/'
      OnAction = WebModule1DefaultHandlerAction
    end
    item
      Name = 'GetAllEmployees'
      PathInfo = '/employees'
      OnAction = WebModule1GetAllEmployeesAction
    end
    item
      Name = 'GetAnEmployee'
      PathInfo = '/employee*'
      OnAction = WebModule1GetAnEmployeeAction
    end
    item
      MethodType = mtPost
      Name = 'CreateAnEmployee'
      PathInfo = '/create'
      OnAction = WebModule1CreateAnEmployeeAction
    end
    item
      Name = 'DeleteAnEmployee'
      PathInfo = '/delete*'
      OnAction = WebModule1DeleteAnEmployeeAction
    end>
  Height = 329
  Width = 547
end
