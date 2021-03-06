{Summary MeScript VM Execution Core .}
{
   @author  Riceball LEE(riceballl@hotmail.com)
   @version $Revision$

  License:
    * The contents of this file are released under a dual \license, and
    * you may choose to use it under either the Mozilla Public License
    * 1.1 (MPL 1.1, available from http://www.mozilla.org/MPL/MPL-1.1.html)
    * or the GNU Lesser General Public License 2.1 (LGPL 2.1, available from
    * http://www.opensource.org/licenses/lgpl-license.php).
    * Software distributed under the License is distributed on an "AS
    * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
    * implied. See the License for the specific language governing
    * rights and limitations under the \license.
    * The Original Code is $RCSfile: uMeScriptInterpreter.pas,v $.
    * The Initial Developers of the Original Code are Riceball LEE.
    * Portions created by Riceball LEE is Copyright (C) 2007-2008
    * All rights reserved.

    * Contributor(s):


}
unit uMeScriptInterpreter;

interface

{$I MeSetting.inc}

uses
  SysUtils
  , uMeScript
  , uMeScriptConsts
  ;

implementation

type
  PPMeScriptBlock = ^PMeScriptBlock;
  PMeScriptGlobalFunctionAccess = ^TMeScriptGlobalFunctionAccess;
  TMeScriptGlobalFunctionAccess = object(TMeScriptGlobalFunction)
  end;
  TMeVMInstructionProcA = procedure(const aGlobalFunction: PMeScriptGlobalFunctionAccess);
  //the Core VM instructions List
  {: 核心虚拟指令表 } 
  TMeScriptCoreWords = array [TMeVMInstruction] of TMeVMInstructionProcA;

var
  GMeScriptCoreWords: TMeScriptCoreWords;

{## the VM instructions ## }
procedure iVMNext(const aGlobalFunction: PMeScriptGlobalFunction); forward;
procedure _iVMHalt(const aGlobalFunction: PMeScriptGlobalFunctionAccess; ErrorCode: TMeScriptProcessorErrorCode); forward;

procedure iVMNext(const aGlobalFunction: PMeScriptGlobalFunction);
var
  vInstruction: TMeVMInstruction; //the instruction.
  vProc: TMeVMInstructionProcA;
begin
  with PMeScriptGlobalFunctionAccess(aGlobalFunction)^ do
    {$IFDEF FPC}
    While (psRunning in TMeScriptProcessorStates(LongWord(States))) do
    {$ELSE Borland}
    While (psRunning in TMeScriptProcessorStates(States)) do
    {$ENDIF}
    begin
      vInstruction := PMeVMInstruction(_PC.Mem)^;
      Inc(_PC.Mem);
      vProc := GMeScriptCoreWords[vInstruction];
      if Assigned(vProc) then
      begin
        vProc(PMeScriptGlobalFunctionAccess(aGlobalFunction));
      end
      else begin
        //BadOpError
        _iVMHalt(PMeScriptGlobalFunctionAccess(aGlobalFunction), errBadInstruction);
        //break;
      end;
    end;
end;

procedure _iVMHalt(const aGlobalFunction: PMeScriptGlobalFunctionAccess; ErrorCode: TMeScriptProcessorErrorCode);
{$IFDEF FPC}
var
  vStates: TMeScriptProcessorStates;
{$ENDIF}
begin
  with aGlobalFunction^ do
  begin 
    LastErrorCode := ErrorCode;
    {$IFDEF FPC}
    vStates := TMeScriptProcessorStates(LongWord(States)); 
    Exclude(vStates, psRunning);
    Include(vStates, psHalt);
    {$ELSE Borland}
    Exclude(TMeScriptProcessorStates(States), psRunning);
    Include(TMeScriptProcessorStates(States), psHalt);
    {$ENDIF}
    //cmpare the RP and ReturnStackBottom, it should be equ.
    if _RP <> 0 then //not same so halt error
    begin
      {$IFDEF FPC}
      Include(vStates, psHaltError);
      {$ELSE Borland}
      Include(TMeScriptProcessorStates(States), psHaltError);
      {$ENDIF}
    end
    else  
      {$IFDEF FPC}
      Exclude(vStates, psHaltError);
      {$ELSE Borland}
      Exclude(TMeScriptProcessorStates(States), psHaltError);
      {$ENDIF}
    {$IFDEF FPC}
    States := Byte(LongWord(vStates)); 
    {$ENDIF}
  end;
end;

procedure VMCallBlock(const aGlobalFunction: PMeScriptGlobalFunctionAccess);
var
  vBlock: PMeScriptBlock;
begin
  with aGlobalFunction^ do
  begin
    vBlock := PPMeScriptBlock(_PC.Mem)^;
    Inc(_PC.Mem, SizeOf(tsInt));
    //Todo: Valid the vBlock before execution.
    vBlock.Execute();
  end;
end;

procedure VMAssignment(const aGlobalFunction: PMeScriptGlobalFunctionAccess);
{代码体是在函数上的，如何处理？
  法1： 进入某函数的时候，压入原来的_Func和_PC,赋值给全局 _Func 和 _PC. 修改返回栈的内容为： _Func, _PC，退出函数则还原原来的。
}
begin
end;

procedure VMCall(const aGlobalFunction: PMeScriptGlobalFunctionAccess);
begin
end;

procedure InitMeScriptCoreWordList;
begin
end;

initialization
  SetVMExecutorProc(iVMNext);
end.
