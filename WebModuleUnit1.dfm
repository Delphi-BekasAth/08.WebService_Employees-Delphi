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
    end
    item
      Name = 'CheckForUpdateAnEmployee'
      PathInfo = '/checkForUpdate*'
      OnAction = WebModule1CheckForUpdateAnEmployeeAction
    end
    item
      Name = 'UpdateAnEmployee'
      PathInfo = '/update*'
      OnAction = WebModule1UpdateAnEmployeeAction
    end>
  Height = 329
  Width = 547
end
