/**
 * 内置方法
 * 
 * The license of this source is "Ruby License"
 * 这段代码的许可证为"Ruby许可证"
 */

package jp.yukoba.hotruby 
{
	/**
	 * ...
	 * @author 
	 */
	public dynamic class HotRubyProc
	{
		public function initialize(recver:Object, args:Array, sf:StackFrame):void 
		{
			recver.__opcode = args[0].__opcode;
			recver.__parentStackFrame = args[0].__parentStackFrame;
		}
		
		public function yield(recver:Object, args:Array, sf:StackFrame):Object 
		{
			this.runOpcode(
				recver.__opcode, 
				recver.__parentStackFrame.classObj, 
				recver.__parentStackFrame.methodName, 
				recver.__parentStackFrame.self, 
				args, 
				recver.__parentStackFrame,
				true);
			return sf.stack[--sf.sp];
		}
		
		public function HotRubyProc() 
		{
			
		}	
	}
}