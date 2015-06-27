## Introduction ##

It includes the TMeThreadSafeList class and AddFreeNotification/RemoveFreeNotification functions etc.

## Class ##
  * TMeThreadSafeList : like the TThreadSafeList. this is for the TMeList.

## functions ##

### AddFreeNotification and RemoveFreeNotification ###

Summary: the AddFreeNotification ensures that aProc is notified that the aInstance is going to be destroyed.

Desccription
Use AddFreeNotification to register aProc that should be notified when the aInstance is about to be destroyed.
```
procedure AddFreeNotification(const aInstance : Pointer; const aProc : TFreeNotifyProc);
```

Summary: the RemoveFreeNotification disables destruction notification that was enabled by AddFreeNotification.

Description
RemoveFreeNotification removes the NotificationProc specified by the aProc parameter from the internal list of procedures to be notified that the aInstance is about to be destroyed. aProc is added to this list by a previous call to the AddFreeNotification function.

```
procedure RemoveFreeNotification(const aInstance : Pointer; const aProc : TFreeNotifyProc);
```

#### Examples ####
```
program TestFreeNotify;

{$APPTYPE Console}
	
uses
  Windows, SysUtils
  , uMeSystem
  , uMeObject
  , uMeSysUtils
  ;

var
  v: Pointer;
  v2: Pointer;

procedure NotifyFree(const Self: Pointer; const Instance : Pointer);
begin
  writeln('Instance=',Integer(Instance));
  writeln('v=',Integer(v));
  writeln('v2=',Integer(v2));
  writeln('it should instance = v. :', Instance=v);
end;

begin
  try
    v := TObject.Create;
    v2 := New(PMeDynamicObject, Create);
    //PMeDynamicObject(v2).destroy;
    AddFreeNotification(v, TFreeNotifyProc(ToMethod(@NotifyFree)));
    writeln('hell1');
    AddFreeNotification(v2, TFreeNotifyProc(ToMethod(@NotifyFree)));
    writeln('hell2');
  finally
    writeln('try free object..');
    TObject(v).Free;
    PMeDynamicObject(v2).Free;
  end;

  try
    v := New(PMeDynamicObject, Create);
    writeln('h3');
    AddFreeNotification(v, TFreeNotifyProc(ToMethod(@NotifyFree)));
  finally
    writeln('try free Meobject..');
    PMeDynamicObject(v).Free;
  end;
end.
```