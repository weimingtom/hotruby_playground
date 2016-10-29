/**
 * the original code is from hotruby:
 * @see http://hotruby.yukoba.jp/
 * @see http://code.google.com/p/hotruby/
 * 
 * The license of this source is "Ruby License"
 */

package jp.yukoba.hotruby  
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.getDefinitionByName;
	
	public final class HotRuby extends Sprite
	{
		// Consts
		// 常数
		/** @memberof HotRuby */
		public static const VM_CALL_ARGS_SPLAT_BIT:int = 2;
		/** @memberof HotRuby */
		public static const VM_CALL_ARGS_BLOCKARG_BIT:int = 4;
		/** @memberof HotRuby */
		public static const VM_CALL_FCALL_BIT:int = 8;
		/** @memberof HotRuby */
		public static const VM_CALL_VCALL_BIT:int = 16;

		private var _root:Object = this;
		public static var debugTextField:TextField;
		
		//一些用于移植的变量或函数，需要删除或修改
		private var alert:Function;
		private var asPackages:Array;
		private var _eval:Function;
		private var nativeClassObjCache:Object;
		private var document:Object;
		private var debugDom:Object;
		private var _print:Function;
		private var Ext:Object;

		/** 
		 * Global Variables
		 * 全局变量
		 * @type Object 
		 */
		private var globalVars:Object = {
			"$native": {
				__className : "NativeEnviornment",
				__instanceVars : {}
			}
		};
		
		/** 
		 * END blocks
		 * END块
		 * @type Array 
		 */
		private var endBlocks:Array = [];
		
		/**
		 * Running Enviornment
		 * 运行环境
		 * @type String
		 */
		private var env:String = "browser";
		
		/** nil object */
		/*
		private var nilObj:Object = {
			__className : "NilClass",
			__native : null
		};
		*/
		
		/** true object */
		/*
		private var trueObj:Object = {
			__className : "TrueClass",
			__native : true
		};
		*/
		
		/** false object */
		/*
		private var falseObj:Object = {
			__className : "FalseClass",
			__native : false
		};
		*/
		
		/*
		private var topObject:Object = {
			__className : "Object",
			__native : {}
		};
		*/
		
		private var topSF:Object = null;
		
		private var classes:HotRubyClasses = new HotRubyClasses();
		
		/**
		 * 构造函数
		 */
		public function HotRuby() 
		{
			//TODO:不知道放在前还是后
			this.checkEnv();
			
			//var classes:Object = this.classes;
			var classes:HotRubyClasses = this.classes;
			for (var className:String in classes) 
			{
				classes[className].__className = className;
				classes[className].__parentClass = classes.Object;
				if(!("__constantVars" in classes[className]))
					classes[className].__constantVars = {};
				if(!("__classVars" in classes[className]))
					classes[className].__classVars = {};
			}
			classes.Object.__parentClass = null;
			
			for (className in classes) 
			{
				classes.Object.__constantVars[className] = classes[className];
			}
			
			//-----------------------------------
			// 测试代码：
			if(true)
			{
				run(HotRubyFlash.src);
			}
		}
		
		/**
		 * Run the script.
		 * 运行脚本
		 * @param {Array} opcode
		 */
		public function run(opcode:Array):void
		{
			//try 
			{
				this.runOpcode(opcode, this.classes.Object, null, HotRubyGlobal.topObject, [], null, false, null);
			} 
			//catch (e:Error) 
			{
				//alert(e);
			}
		}
		
		/**
		 * Run the opcode.
		 * 运行操作码
		 * @param {Array} opcode
		 * @param {Object} classObj
		 * @param {String} methodName
		 * @param {Object} self
		 * @param {Array} args
		 * @param {HotRuby.StackFrame} parentSF Parent StackFrame
		 * @param {boolean} isProc
		 * @param {Object} cbaseObj
		 * @private
		 */
		private function runOpcode(opcode:Object, classObj:Object, methodName:String, 
			self:Object, args:Array, parentSF:StackFrame, isProc:Boolean, cbaseObj:Object):void 
		{
			if(args.length < opcode[4].arg_size)
				throw "[runOpcode] Wrong number of arguments (" + args.length + " for " + opcode[4].arg_size + ")";
			
			// Create Stack Frame
			var sf:StackFrame = new StackFrame();
			sf.localVars = new Array(opcode[4].local_size + 1);
			sf.stack = new Array(opcode[4].stack_max);
			sf.fileName = opcode[6];
			sf.classObj = classObj;
			sf.methodName = methodName;
			sf.self = self;
			sf.parentStackFrame = parentSF;
			sf.isProc = isProc;
			sf.cbaseObj = cbaseObj;
			
			if (this.topSF == null) 
				this.topSF = sf;
			
			var i:int
			// Copy args to localVars. Fill from last.
			for (i = 0; i < opcode[4].arg_size; i++) 
			{
				sf.localVars[sf.localVars.length - 1 - i] = args[i];
			}
			
			// Run the mainLoop
			this.mainLoop(opcode[11], sf);
			
			// Copy the stack to the parent stack frame
			if (parentSF != null) 
			{
				for (i; i < sf.sp; i++) 
				{
					parentSF.stack[parentSF.sp++] = sf.stack[i];
				}
			} 
			else 
			{
				// Run END blocks
				if (this.endBlocks.length > 0) 
				{
					this.run(this.endBlocks.pop());
				}
			}
		}
		
		/**
		 * Main loop for opcodes.
		 * 操作码主循环
		 * @param {Array} opcode
		 * @param {HotRuby.StackFrame} sf
		 * @private
		 */
		private function mainLoop (opcode:Array, sf:StackFrame):void 
		{
			var ip:int = 0;
			
			// Create label to ip
			if (!("label2ip" in opcode)) 
			{
				opcode.label2ip = {};
				for (ip; ip < opcode.length; ip++) 
				{
					// If "cmd is a String then it is a jump label
					var cmd:Object = opcode[ip];
					if (typeof(cmd) == "string") 
					{
						opcode.label2ip[cmd] = ip;
						opcode[ip] = null;
					}
				}
			}
			
			for (ip = 0; ip < opcode.length; ip++) 
			{
				// Get the next command
				cmd = opcode[ip];
				if (cmd == null)
					continue;

				// If "cmd" is a Number then it is the line number.
				if (typeof(cmd) == "number") 
				{
					sf.lineNo = cmd as Number;
					continue;
				}
				// "cmd" must be an Array
				if (!(cmd is Array))
					continue;
				
				//trace("cmd = " + cmd[0] + ", sp = " + sf.sp);
				var val:Object;
				var value:Object;
				var i:int;
				var localSF:StackFrame;
				var lookupSF:StackFrame;
				var tmp:Object;
				var args:Array;
				var obj:Object;
				switch (cmd[0]) 
				{
					case "jump" :
						ip = opcode.label2ip[cmd[1]];
						break;
						
					case "branchif" :
						val = sf.stack[--sf.sp];
						if(val != HotRubyGlobal.nilObj && val != HotRubyGlobal.falseObj) {
							ip = opcode.label2ip[cmd[1]];
						}
						break;
					
					case "branchunless" :
						val = sf.stack[--sf.sp];
						if (val == HotRubyGlobal.nilObj || val == HotRubyGlobal.falseObj) 
						{
							ip = opcode.label2ip[cmd[1]];
						}
						break;
					
					case "opt_case_dispatch":
						var v:Object = sf.stack[--sf.sp];
						if (typeof(v) != "number") 
							v = v.__native;
						for (i = 0; i < cmd[1].length; i += 2) 
						{
							if (v === cmd[1][i]) 
							{
								ip = opcode.label2ip[cmd[1][i+1]];
								break;
							}
						}
						if (i == cmd[1].length) 
						{
							ip = opcode.label2ip[cmd[2]];
						}
						break;
					
					case "leave" :
						return;
						
					case "putnil" :
						sf.stack[sf.sp++] = HotRubyGlobal.nilObj;
						break;
					
					case "putself" :
						sf.stack[sf.sp++] = sf.self;
						break;
					
					case "putobject" :
						value = cmd[1];
						if (typeof(value) == "string") 
						{
							var arr:Array = (value as String).match(/^(\d+)\.\.(\d+)$/)
							if (arr) 
							{
								value = this.createRubyRange(
									parseInt(arr[2]), 
									parseInt(arr[1]), 
									false);
							}
						}
						sf.stack[sf.sp++] = value;
						break;
					
					case "putstring" :
						sf.stack[sf.sp++] = this.createRubyString(cmd[1]);
						break;
					
					case "concatstrings" :
						sf.stack[sf.sp++] = this.createRubyString(
							sf.stack.slice(sf.stack.length - cmd[1], sf.stack.length).join());
						break;
					
					case "newarray" :
						value = this.createRubyArray(sf.stack.slice(sf.sp - cmd[1], sf.sp));
						sf.sp -= value.__native.length;
						sf.stack[sf.sp++] = value;
						break;
					
					case "duparray" :
						sf.stack[sf.sp++] = this.createRubyArray(cmd[1]);
						break;
					
					case "expandarray" :
						var ary:Array = sf.stack[--sf.sp];
						if (typeof(ary) == "object" && ary.__className == "Array") 
						{
							for (i = 0; i < cmd[1]; i++) 
							{
								sf.stack[sf.sp++] = ary.__native[i];						
							}
							if (cmd[2] && 1) 
							{
								// TODO
							}
							if (cmd[2] && 2) 
							{
								// TODO
							}
							if (cmd[2] && 4) 
							{
								// TODO
							}
						} 
						else 
						{
							sf.stack[sf.sp++] = ary;
							for (i = 0; i < cmd[1] - 1; i++) 
							{
								sf.stack[sf.sp++] = HotRubyGlobal.nilObj;
							}
						}
						break;
					
					case "newhash" :
						var hash:Object = this.createRubyHash(sf.stack.slice(sf.sp - cmd[1], sf.sp));
						sf.sp -= cmd[1];
						sf.stack[sf.sp++] = hash;
						break;
					
					case "newrange" :
						value = this.createRubyRange(sf.stack[--sf.sp], sf.stack[--sf.sp], cmd[1]);
						sf.stack[sf.sp++] = value;
						break;
					
					case "setlocal" :
						localSF = sf;
						while (localSF.isProc) 
						{
							localSF = localSF.parentStackFrame;
						}
						localSF.localVars[cmd[1]] = sf.stack[--sf.sp];
						break;
					
					case "getlocal" :
						localSF = sf;
						while (localSF.isProc) 
						{
							localSF = localSF.parentStackFrame;
						}
						sf.stack[sf.sp++] = localSF.localVars[cmd[1]];
						break;
					
					case "setglobal" :
						this.globalVars[cmd[1]] = sf.stack[--sf.sp];
						break;
					
					case "getglobal" :
						sf.stack[sf.sp++] = this.globalVars[cmd[1]];
						break;
					
					case "setconstant" :
						this.setConstant(sf, sf.stack[--sf.sp], cmd[1], sf.stack[--sf.sp]);
						break;
					
					case "getconstant" :
						value = this.getConstant(sf, sf.stack[--sf.sp], cmd[1]);
						sf.stack[sf.sp++] = value;
						break;
					
					case "setinstancevariable" :
						sf.self.__instanceVars[cmd[1]] = sf.stack[--sf.sp];
						break;
					
					case "getinstancevariable" :
						sf.stack[sf.sp++] = sf.self.__instanceVars[cmd[1]];
						break;
					
					case "setclassvariable" :
						sf.classObj.__classVars[cmd[1]] = sf.stack[--sf.sp];
						break;
					
					case "getclassvariable" :
						var searchClass:Object = sf.classObj;
						while (true) 
						{
							if (cmd[1] in searchClass.__classVars) 
							{
								sf.stack[sf.sp++] = searchClass.__classVars[cmd[1]];
								break;
							}
							searchClass = searchClass.__parentClass;
							if (searchClass == null) 
							{
								throw "Cannot find class variable : " + cmd[1];
							}
						}
						break;
					
					case "getdynamic" :
						lookupSF = sf;
						for (i = 0; i < cmd[2]; i++) 
						{
							lookupSF = lookupSF.parentStackFrame;
						}
						sf.stack[sf.sp++] = lookupSF.localVars[cmd[1]];
						break;
					
					case "setdynamic" :
						lookupSF = sf;
						for (i = 0; i < cmd[2]; i++) 
						{
							lookupSF = lookupSF.parentStackFrame;
						}
						lookupSF.localVars[cmd[1]] = sf.stack[--sf.sp];
						break;
					
					//case "getspecial" :
					//	break;
					
					//case "setspecial" :
					//	break;
					
					case "pop" :
						sf.sp--;
						break;
					
					case "dup" :
						sf.stack[sf.sp] = sf.stack[sf.sp - 1];
						sf.sp++;
						break;
					
					case "dupn" :
						for (i = 0;i < cmd[1]; i++) {
							sf.stack[sf.sp + i] = sf.stack[sf.sp + i - cmd[1]];
						}
						sf.sp += cmd[1];
						break;
					
					case "swap" :
						tmp = sf.stack[sf.sp - 1];
						sf.stack[sf.sp - 1] = sf.stack[sf.sp - 2];
						sf.stack[sf.sp - 2] = tmp;
						break;
					
					case "topn" :
						sf.stack[sf.sp] = sf.stack[sf.sp - cmd[1]];
						sf.sp++;
						break;
					
					case "setn" :
						sf.stack[sf.sp - cmd[1]] = sf.stack[sf.sp - 1];
						break;
					
					case "emptstack" :
						sf.sp = 0;
						break;
					
					case "send" :
						args = sf.stack.slice(sf.sp - cmd[2], sf.sp);
						sf.sp -= cmd[2];
						var recver:Object = sf.stack[--sf.sp];
						if(cmd[4] & HotRuby.VM_CALL_FCALL_BIT) 
						{
							recver = sf.self;
						}
						if(cmd[3] is Array)
							cmd[3] = this.createRubyProc(cmd[3], sf);
						if(cmd[3] != null)
							args.push(cmd[3]);
						this.invokeMethod(recver, cmd[1], args, sf, cmd[4], false);
						break;
					
					case "invokesuper" :
						args = sf.stack.slice(sf.sp - cmd[1], sf.sp);
						sf.sp -= cmd[1];
						// TODO When to use this autoPassAllArgs?
						var autoPassAllArgs:Object = sf.stack[--sf.sp];
						if(cmd[2] is Array)
							cmd[2] = this.createRubyProc(cmd[1], sf);
						if(cmd[2] != null)
							args.push(cmd[2]);
						this.invokeMethod(sf.self, sf.methodName, args, sf, cmd[3], true);
						break;
					
					case "definemethod" :
						obj = sf.stack[--sf.sp];
						if(sf.cbaseObj != null)
							obj = sf.cbaseObj;
						if (obj == null || obj == HotRubyGlobal.nilObj) {
							sf.classObj[cmd[1]] = cmd[2];
						} else {
							if (!("__methods" in obj))
							//if(typeof(obj.__methods) == "undefined")
								obj.__methods = {};
							obj.__methods[cmd[1]] = cmd[2];
						}
						opcode[ip] = null;
						opcode[ip - 1] = null;
						break;
					
					case "defineclass" :
						var parentClass:Object = sf.stack[--sf.sp];
						var isRedefine:Boolean = (parentClass == HotRubyGlobal.falseObj);
						if(parentClass == null || parentClass == HotRubyGlobal.nilObj)
							parentClass = this.classes.Object;
						var cbaseObj:Object = sf.stack[--sf.sp];
						if(cmd[3] == 0) 
						{
							// Search predefined class
							var newClass:Object = this.getConstant(sf, sf.classObj, cmd[1]);
							if(newClass == null || isRedefine) 
							{
								// Create class object
								newClass = {
									__className : cmd[1],
									__parentClass : parentClass,
									__constantVars : {},
									__classVars : {}
								};
								this.classes[cmd[1]] = newClass;
								// Puts the className to CONSTANT
								this.setConstant(sf, sf.classObj, cmd[1], newClass);
							}
							// Run the class definition
							this.runOpcode(cmd[2], newClass, null, sf.self, [], sf, false, null);
						} else if(cmd[3] == 1) {
							// Object-Specific Classes
							if(cbaseObj == null || typeof(cbaseObj) != "object")
								throw "Not supported Object-Specific Classes on Primitive Object"
							// Run the class definition
							this.runOpcode(cmd[2], cbaseObj.__className, null, sf.self, [], sf, false, cbaseObj);
						} else 	if(cmd[3] == 2) {
							// TODO 
							throw "Not implemented";
						}
						break;
					
					case "postexe" :
						this.endBlocks.push(cmd[1]);
						break;
					
					case "nop" :
						break;
					
					case "reput" :
						break;
					
					default :
						throw "[mainLoop] Unknown opcode : " + cmd[0];
				}
			}
		}
		
		/**
		 * Invoke the method
		 * 调用方法
		 * @param {Object} recver
		 * @param {String} methodName
		 * @param {Array} args
		 * @param {HotRuby.StackFrame} sf
		 * @param {Number} type VM_CALL_ARGS_SPLAT_BIT, ...
		 * @param {boolean} invokeSuper
		 */
		public function invokeMethod (recver:Object, methodName:String, 
			args:Array, sf:StackFrame, type:Number, invokeSuper:Boolean):void
		{
			var recverClassName:String = this.getClassName(recver);
			var invokeClassName:String = recverClassName;
			var invokeMethodName:String = methodName;
			var func:Object = null;

			// Invoke host method
			var done:Boolean = this.invokeNative(recver, methodName, args, sf, recverClassName);
			if (done) 
				return;
			
			if (invokeSuper) 
			{
				var searchClass:Object = this.classes[recverClassName];
				while (func == null) 
				{
					// Search Parent class
					if (!("__parentClass" in searchClass)) 
						break;
					searchClass = searchClass.__parentClass;
					invokeClassName = searchClass.__className;
					
					// Search method in class
					func = searchClass[methodName];
				}
			} 
			else 
			{
				// Search method in object
				//if (recver != null && recver.__methods != null) {
				if (recver != null && typeof(recver) == "object" && "__methods" in recver) 
				{
					func = recver.__methods[methodName];
				}
				if (func == null) 
				{
					//trace("recverClassName = " + recverClassName);
					searchClass = this.classes[recverClassName];
					while (true) 
					{
						//trace("methodName = " + methodName);
						// Search method in class
						func = searchClass[methodName];
						//(func as Function)(null, null, null);
						if (func != null) 
							break;
							
						if (methodName == "new") 
						{
							func = searchClass["initialize"];
							if (func != null) 
							{
								invokeMethodName = "initialize";
								break;
							}
						}
		
						// Search Parent class
						if ("__parentClass" in searchClass) 
						{
							searchClass = searchClass.__parentClass;
							//trace("searchClass = " + searchClass);
							if (searchClass == null) 
							{
								func = null;
								break;
							}
							invokeClassName = searchClass.__className;
							//trace("invokeClassName = " + invokeClassName);
							continue;
						}
						break;
					}
				}
			}
			if (func == null) 
			{
				if (invokeSuper) 
				{
					sf.stack[sf.sp++] = null;
					return;
				}
				if (methodName != "new") 
				{
					throw "[invokeMethod] Undefined function : " + methodName;
				}
			}
			
			if (methodName == "new") 
			{
				// Create instance
				var newObj:Object = {
					__className : recverClassName,
					__instanceVars : {}
				};
				sf.stack[sf.sp++] = newObj;
				if (func == null) 
					return;
				recver = newObj;
			}

			// Splat array args
			if (type & HotRuby.VM_CALL_ARGS_SPLAT_BIT) 
			{
				args = args.concat(args.pop().__native);
			}
			
			// Exec method
			switch (typeof(func)) 
			{
				case "function" :
					//???
					//sf.stack[sf.sp++] = func.call(this, recver, args, sf);
					sf.stack[sf.sp++] = func.call(null, recver, args, sf);
					break;
				
				case "object" :
					this.runOpcode(func, this.classes[invokeClassName],
							invokeMethodName, recver, args, sf, false, sf.cbaseObj);
					break;
				
				default :
					throw "[invokeMethod] Unknown function type : " + typeof(func);
			}
			
			// Returned value of initialize() is unnecessally at new()
			if (methodName == "new") 
			{
				sf.sp--;
			}
		}
		
		/**
		 * Invoke native routine
		 * 调用原生例程
		 */
		public function invokeNative(recver:Object, methodName:String,
			args:Array, sf:StackFrame, recverClassName:String):Boolean 
		{
			switch(recverClassName) 
			{
				case "NativeEnviornment":
					this.getNativeEnvVar(recver, methodName, args, sf);
					return true;
				
				case "NativeObject":
					this.invokeNativeMethod(recver, methodName, args, sf);
					return true;
				
				case "NativeClass":
					if (methodName == "new") 
					{
						this.invokeNativeNew(recver, methodName, args, sf);
					} 
					else 
					{
						this.invokeNativeMethod(recver, methodName, args, sf);
					}
					return true;
				
				default:
					return false;
			}
		}
		
		/**
		 * Get variable from NativeEnviornment
		 * 从原生环境中获得变量
		 */
		private function getNativeEnvVar(recver:Object, varName:String, args:Array, sf:StackFrame):void 
		{
			//trace(varName);
			if (this.env == "flash" && varName == "import") 
			{
				var imp:String = args[0].__native;
				if(imp.charAt(imp.length - 1) != "*")
					throw "[getNativeEnvVar] Param must ends with * : " + imp;
				this.asPackages.push(imp.substr(0, imp.length - 1));
				sf.stack[sf.sp++] = HotRubyGlobal.nilObj;
				return;
			}
			
			if (varName in recver.__instanceVars) 
			{
				sf.stack[sf.sp++] = recver.__instanceVars[varName];
				return;
			}
			
			if (this.env == "browser" || this.env == "rhino") 
			{
				// Get native global variable
				var v:Object = _eval("(" + varName + ")");
				if (typeof(v) != "undefined") 
				{
					if (typeof(v) == "function") 
					{
						var convArgs:Array = this.rubyObjectAryToNativeAry(args);
						var ret:Object = (v as Function).apply(null, convArgs);
						sf.stack[sf.sp++] = this.nativeToRubyObject(ret);
					} 
					else 
					{
						sf.stack[sf.sp++] = 
						{
							__className: "NativeObject",
							__native: v
						}
					}
					return;
				}
			} 
			else if (this.env == "flash") 
			{
				// Get NativeClass Object
				var classObj:Object;
				if (varName in this.nativeClassObjCache) 
				{
					classObj = this.nativeClassObjCache[varName];
				} 
				else 
				{
					for (var i:int = 0; i < this.asPackages.length; i++) 
					{
						try 
						{
							classObj = getDefinitionByName(this.asPackages[i] + varName);
							break;
						} 
						catch (e:Error) 
						{
							
						}
					}
					if (classObj == null) 
					{
						throw "[getNativeEnvVar] Cannot find class: " + varName;
					}
					this.nativeClassObjCache[varName] = classObj;
				}
				sf.stack[sf.sp++] = 
				{
					__className : "NativeClass",
					__native : classObj
				}
				return;
			}
			
			throw "[getNativeEnvVar] Cannot get the native variable: " + varName;
		}
		
		/**
		 * Invoke native method or get native instance variable
		 * 调用原生方法或获得原生实例变量
		 */
		public function invokeNativeMethod(recver:Object, methodName:String, args:Array, sf:StackFrame):void
		{
			// Split methodName and operator
			var op:String = this.getOperator(methodName);
			if (op != null) 
			{
				methodName = methodName.substr(0, methodName.length - op.length);
			}
			
			var ret:Object;
			if (recver.__native[methodName] is Function) 
			{
				// Invoke native method
				if(op != null)
					throw "[invokeNativeMethod] Unsupported operator: " + op;
				var convArgs:Array = this.rubyObjectAryToNativeAry(args);
				ret = recver.__native[methodName].apply(recver.__native, convArgs);
			} 
			else 
			{
				// Get native instance variable
				if (op == null) 
				{
					ret = recver.__native[methodName];
				} 
				else 
				{
					switch(op) 
					{
						case "=": 
							ret = recver.__native[methodName] = this.rubyObjectToNative(args[0]);
							break;
						
						default:
							throw "[invokeNativeMethod] Unsupported operator: " + op;
					}
				}
			}
			sf.stack[sf.sp++] = this.nativeToRubyObject(ret);
		}
		
		/**
		 * Convert ruby object to native value
		 * 转换ruby对象为原生值
		 * @param v ruby object
		 */
		public function rubyObjectToNative(v:Object):Object
		{
			if(typeof(v) != "object") 
				return v;
			if (v.__className == "Proc") 
			{
				var func:Object = function():void {
					var hr:HotRuby = arguments.callee.hr;
					var proc:Object = arguments.callee.proc;
					hr.runOpcode(
						proc.__opcode, 
						proc.__parentStackFrame.classObj, 
						proc.__parentStackFrame.methodName, 
						proc.__parentStackFrame.self, 
						hr.nativeAryToRubyObjectAry(arguments),
						proc.__parentStackFrame,
						true,
						null);
				};
				func.hr = this;
				func.proc = v;
				return func;
			}
			return v.__native;
		}
		
		/**
		 * 
		 * @param ary
		 */
		public function rubyObjectAryToNativeAry(ary:Array):Array 
		{
			var convAry:Array = new Array(ary.length);
			for (var i:int = 0; i < ary.length; i++) 
			{
				convAry[i] = this.rubyObjectToNative(ary[i]);
			}
			return convAry;
		}
		
		/**
		 * Convert native object to ruby object
		 * 转换原生对象为ruby对象
		 * @param v native object
		 */
		public function nativeToRubyObject(v:Object):Object
		{
			if (v === null) 
			{
				return HotRubyGlobal.nilObj;
			}
			if (v === true) 
			{
				return HotRubyGlobal.trueObj;
			}
			if (v === false) 
			{
				return HotRubyGlobal.falseObj;
			}
			if (typeof(v) == "number") 
			{
				return v;	
			}
			if (typeof(v) == "string") 
			{
				return this.createRubyString(v as String) as Object;
			}
			if (typeof(v) == "object" && v is Array) 
			{
				return this.createRubyArray(v as Array) as Object;
			}
			return {
				__className: "NativeObject",
				__native: v
			};
		}
		
		/**
		 * Convert array of native object to array of ruby object
		 * 转换原生对象的数组为ruby对象的数组
		 * @param {Array} ary Array of native object
		 */
		public function nativeAryToRubyObjectAry(ary:Array):Array 
		{
			var convAry:Array = new Array(ary.length);
			for(var i:int=0; i<ary.length; i++) {
				convAry[i] = this.nativeToRubyObject(ary[i]);
			}
			return convAry;
		}
		
		/**
		 * Invoke native "new", and create native instance.
		 * 调用原生new，并且创建原生实例
		 */
		private function invokeNativeNew(recver:Object, methodName:String, args:Array, sf:StackFrame):void
		{
			var obj:Object;
			var args:Array = this.rubyObjectAryToNativeAry(args);
			switch(args.length) 
			{
				case 0: 
					obj = new recver.__native(); 
					break;
				
				case 1: 
					obj = new recver.__native(args[0]); 
					break; 
				
				case 2: 
					obj = new recver.__native(args[0], args[1]); 
					break; 
					
				case 3: 
					obj = new recver.__native(args[0], args[1], args[2]); 
					break; 
				
				case 4: 
					obj = new recver.__native(args[0], args[1], args[2], args[3]); 
					break;
					
				case 5: 
					obj = new recver.__native(args[0], args[1], args[2], args[3], args[4]); 
					break; 
				
				case 6: 
					obj = new recver.__native(args[0], args[1], args[2], args[3], args[4], args[5]); 
					break;
				
				case 7: 
					obj = new recver.__native(args[0], args[1], args[2], args[3], args[4], args[5], args[6]); 
					break;
				
				case 8: 
					obj = new recver.__native(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]); 
					break;
				
				case 9: 
					obj = new recver.__native(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8]); 
					break;
				
				default: 
					throw "[invokeNativeNew] Too much arguments: " + args.length;
			}
			sf.stack[sf.sp++] = 
			{
				__className : "NativeObject",
				__native : obj
			};
		}
		
		/**
		 * Set the Constant
		 * 设置常数
		 * @param {HotRuby.StackFrame} sf
		 * @param {Object} classObj
		 * @param {String} constName
		 * @param constValue
		 * @private
		 */
		private function setConstant(sf:StackFrame, classObj:Object, constName:String, constValue:Object):void
		{
			if (classObj == null || classObj == HotRubyGlobal.nilObj) 
			{
				classObj = sf.classObj;
			} 
			else if (classObj == false || classObj == HotRubyGlobal.falseObj) 
			{
				// TODO
				throw "[setConstant] Not implemented";
			}
			classObj.__constantVars[constName] = constValue;
		}
		
		/**
		 * Get the constant
		 * 获得常数
		 * @param {HotRuby.StackFrame} sf
		 * @param {Object} classObj
		 * @param {String} constName
		 * @return constant value
		 * @private
		 */
		private function getConstant(sf:StackFrame, classObj:Object, constName:String):Object 
		{
			if (classObj == null || classObj == HotRubyGlobal.nilObj) 
			{
				var isFound:Boolean = false;
				// Search outer(parentStackFrame)
				for (var checkSF:StackFrame = sf; !isFound; checkSF = checkSF.parentStackFrame) 
				{
					if (checkSF == this.topSF) 
					{
						break;
					}
					if (constName in checkSF.classObj.__constantVars) 
					{
						classObj = checkSF.classObj;
						isFound = true;
					}
				}
				// Search parent class
				if (!isFound) 
				{
					for (classObj = sf.classObj; classObj != this.classes.Object; ) 
					{
						if (constName in classObj.__constantVars) 
						{
							isFound = true;
							break;
						}
						classObj = classObj.__parentClass;
					}
				}
				// Search in Object class
				if (!isFound) 
				{
					classObj = this.classes.Object;
				}
			} 
			else if (classObj == false || classObj == HotRubyGlobal.falseObj) 
			{
				// TODO
				throw "[setConstant] Not implemented";
			}
			if (classObj == null || classObj == HotRubyGlobal.nilObj)
				throw "[getConstant] Cannot find constant : " + constName;
			return classObj.__constantVars[constName];
		}
		
		/**
		 * Returns class name from object.
		 * 返回对象的类名
		 * @param obj
		 * @return {String}
		 */
		private function getClassName(obj:Object):String
		{
			if (obj == null)
				return "Object";
			switch (typeof(obj)) 
			{
				case "object" :
					return obj.__className;
				
				case "number" :
					return "Float";
				
				default :
					throw "[getClassName] unknown type : " + typeof(obj);
			}
		}
		
		/**
		 * JavaScript String -> Ruby String
		 * JavaScript字符串转为Ruby字符串
		 * @param {String} str
		 * @return {String}
		 */
		private function createRubyString(str:String):Object 
		{
			return {
				__native : str,
				__className : "String"
			};
		}
		
		/**
		 * opcode -> Ruby Proc
		 * 操作码转为Ruby过程
		 * @param {Array} opcode
		 * @param {HotRuby.StackFrame} sf
		 * @return {Object} Proc
		 */
		private function createRubyProc(opcode:Array, sf:StackFrame):Object 
		{
			return {
				__opcode : opcode,
				__className : "Proc",
				__parentStackFrame : sf
			};
		}
		
		/**
		 * JavaScript Array -> Ruby Array
		 * JavaScript数组转为Ruby数组
		 * @param {Array} ary
		 * @return {Array}
		 */
		private function createRubyArray(ary:Array):Object 
		{
			return {
				__native : ary,
				__className : "Array"
			};
		}
		
		/**
		 * JavaScript Array -> Ruby Hash
		 * JavaScript数组转为Ruby哈希表
		 * @param {Array} ary
		 * @return {Object}
		 */
		private function createRubyHash(ary:Array):Object 
		{
			var hash:Object = {
				__className : "Hash",
				__instanceVars : {
					length : ary.length / 2
				},
				__native : {}
			};
			for (var i:int = 0; i < ary.length; i += 2) 
			{
				if (typeof(ary[i]) == "object" && ary[i].__className == "String") 
				{
					hash.__native[ary[i].__native] = ary[i + 1];
				} 
				else 
				{
					throw "[createRubyHash] Unsupported. Cannot put this object to Hash";
				}
			}
			return hash;
		}
		
		/**
		 * Creates Ruby Range
		 * 创建Ruby范围
		 * @param {Number} last
		 * @param {Number} first
		 * @param {boolean} exclude_end
		 */
		private function createRubyRange(last:Number, first:Number, exclude_end:Boolean):Object 
		{
			return {
				__className : "Range",
				__instanceVars : {
					first : first,
					last : last,
					exclude_end : exclude_end ? HotRubyGlobal.trueObj : HotRubyGlobal.falseObj
				}
			};
		}
		
		/**
		 * Print to debug dom.
		 * 打印调试dom
		 * @param {String} str
		 */
		public static function printDebug(str:String):void 
		{
			trace(str);
			HotRuby.debugTextField.appendText(str + "\n");
		}

		/**
		 * Search <script type="text/ruby"></script> and run.
		 * 搜索<script type="text/ruby"></script>并且运行
		 * @param {String} url Ruby compiler url
		 */
		private function runFromScriptTag(url:String):void
		{
			var ary:Array = document.getElementsByTagName("script");
			for (var i:int = 0; i < ary.length; i++) 
			{
				var hoge:String = ary[i].type;
				if (ary[i].type == "text/ruby") 
				{
					this.compileAndRun(url, ary[i].text);
					break;
				}
			}
		}
		
		/**
		 * Send the source to server and run.
		 * 发送源代码到服务器并且运行
		 * @param {String} url Ruby compiler url
		 * @param {src} Ruby source
		 */
		private function compileAndRun(url:String, src:String):void 
		{
			Ext.lib.Ajax.request(
				"POST",
				url,
				{
					success: function(response:Object):void {
						if(response.responseText.length == 0) {
							alert("Compile failed");
						} else {
							this.run(_eval("(" + response.responseText + ")"));
						}
					},
					failure: function(response:Object):void {
						alert("Compile failed");
					},
					scope: this
				},
				"src=" + encodeURIComponent(src)
			);
		}
		
		/**
		 * Check whether the environment is Flash, Browser or Rhino.
		 * 检查环境是Flash，浏览器还是Rhino
		 */
		private function checkEnv():void
		{
			if (typeof(_root) != "undefined") 
			{
				this.env = "flash";
				// Create debug text field
				HotRuby.debugTextField = new TextField();
				HotRuby.debugTextField.autoSize = TextFieldAutoSize.LEFT;
				_root.addChild(HotRuby.debugTextField);
				// Define alert
				alert = function(str:String):void {
					trace(str + "\n");
					HotRuby.debugTextField.appendText(str + "\n");
				}
				this.nativeClassObjCache = {};
				this.asPackages = [""];
				// Create _root NativeObject
				this.globalVars.$native.__instanceVars._root = {
					__className : "NativeObject",
					__native : _root
				}
			} 
			else if (typeof(alert) == "undefined") 
			{
				this.env = "rhino";
				// Define alert
				alert = function(str:String):void {
					_print(str);
				}
			} 
			else 
			{
				this.env = "browser";
				// Get debug DOM
				this.debugDom = document.getElementById("debug");
				if (this.debugDom == null) 
				{
					this.debugDom = document.body;
				}
			}
		}
		
		private function getOperator(str:String):String
		{
			var result:Array = str.match(/[^\+\-\*\/%=]+([\+\-\*\/%]?=)/);
			if (result == null || result == false) 
			{
				return null;
			}
			if (result is Array) 
			{
				return result[1];
			} 
			else 
			{
				return result[1];
			}
		}
		
		
		//-----------------------------------------------------
		//内置方法
		
		// The license of this source is "Ruby License"
		// 这段代码的许可证为"Ruby许可证"
		
		/*
		private var classes:Object = {
			"Object" : {
				"==" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver == args[0] ? this.trueObj : this.falseObj;	
				},
				
				"to_s" : function(recver:Object, args:Array, sf:StackFrame):Object {
					if(typeof(recver) == "number")
						return this.createRubyString(recver.toString());
					else
						return this.createRubyString(recver.__native.toString());
				},
				
				"puts" : function(recver:Object, args:Array, sf:StackFrame):void {
					if(args.length == 0) {
						HotRuby.printDebug("");
						return;
					}
					for (var i:int = 0; i < args.length; i++) 
					{
						var obj:Object = args[i];
						if (obj == null || obj == this.nilObj) 
						{
							HotRuby.printDebug("nil");
							continue;
						}
						if (typeof(obj) == "number") 
						{
							HotRuby.printDebug(obj);
							continue;
						}
						if (obj.__className == "String") 
						{
							HotRuby.printDebug(obj.__native);
							continue;
						}
						if (obj.__className == "Array") 
						{
							for (var j:int = 0; j < obj.__native.length; j++) 
							{
								HotRuby.printDebug(obj.__native[j]);
							}
							continue;
						}
						
						var origSP:int = sf.sp;
						try {
							this.invokeMethod(obj, "to_ary", [], sf, 0, false);
							obj = sf.stack[--sf.sp];
							for (j = 0; j < obj.__native.length; j++) 
							{
								HotRuby.printDebug(obj.__native[j]);
							}
							continue;
						} 
						catch (e:Error) 
						{
							
						}
						sf.sp = origSP;

						this.invokeMethod(obj, "to_s", [], sf, 0, false);
						obj = sf.stack[--sf.sp];
						HotRuby.printDebug(obj.__native);
					}
				}
			},

			"TrueClass" : {
				"&" : function(recver:Object, args:Array, sf:StackFrame):Boolean {
					return args[0] ? true : false;
				},
				
				"|" : function(recver:Object, args:Array, sf:StackFrame):Boolean {
					return true;
				},

				"^" : function(recver:Object, args:Array, sf:StackFrame):Boolean {
					return args[0] ? false : true;
				}
			},

			"FalseClass" : {
				"&" : function(recver:Object, args:Array, sf:StackFrame):Boolean {
					return false;
				},
				
				"|" : function(recver:Object, args:Array, sf:StackFrame):Boolean {
					return args[0] ? true : false;
				},

				"^" : function(recver:Object, args:Array, sf:StackFrame):Boolean {
					return args[0] ? true : false;
				}
			},

			"NilClass" : {
			},

			"NativeEnviornment" : {
			},
			"NativeObject" : {
			},
			"NativeClass" : {
			},
			
			"Proc" : {
				"initialize" : function(recver:Object, args:Array, sf:StackFrame):void {
					recver.__opcode = args[0].__opcode;
					recver.__parentStackFrame = args[0].__parentStackFrame;
				},
				
				"yield" : function(recver:Object, args:Array, sf:StackFrame):Object {
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
			},

			"Float" : {
				"+" : function(recver:Object, args:Array, sf:StackFrame):Number {
					return Number(recver) + Number(args[0]);
				},

				"-" : function(recver:Object, args:Array, sf:StackFrame):Number {
					return Number(recver) - Number(args[0]);
				},

				"*" : function(recver:Object, args:Array, sf:StackFrame):Number {
					return Number(recver) * Number(args[0]);
				},

				"/" : function(recver:Object, args:Array, sf:StackFrame):Number {
					return Number(recver) / Number(args[0]);
				},
				
				"%" : function(recver:Object, args:Array, sf:StackFrame):Number {
					return Number(recver) % Number(args[0]);
				},
				
				"<=>" : function(recver:Object, args:Array, sf:StackFrame):int {
					if(recver > args[0])
						return 1;
					else if(recver == args[0])
						return 0;
					if(recver < args[0])
						return -1;
					//not reachable
					return -2;
				},
				
				"<" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver < args[0] ? this.trueObj :  this.falseObj;
				},

				">" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver > args[0] ? this.trueObj :  this.falseObj;
				},
				
				"<=" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver <= args[0] ? this.trueObj :  this.falseObj;
				},

				">=" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver >= args[0] ? this.trueObj :  this.falseObj;
				},
				
				"==" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver == args[0] ? this.trueObj :  this.falseObj;
				},
				
				"times" : function(recver:Object, args:Array, sf:StackFrame):void {
					for (var i:int = 0;i < recver; i++) {
						this.invokeMethod(args[0], "yield", [i], sf, 0, false);
						sf.sp--;
					}
				},
				
				"to_s" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return this.createRubyString(recver.toString());	
				}
			},

			"Integer" : {
				"+" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver + args[0];
				},

				"-" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return Number(recver) - Number(args[0]);
				},

				"*" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return Number(recver) * Number(args[0]);
				},

				"/" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return Math.floor(Number(recver) / args[0]);
				},
				
				"%" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return Number(recver) % Number(args[0]);
				},
				
				"<=>" : function(recver:Object, args:Array, sf:StackFrame):int {
					if(recver > args[0])
						return 1;
					else if(recver == args[0])
						return 0;
					if(recver < args[0])
						return -1;
					//not reachable
					return -2;
				},
				
				"<" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver < args[0] ? this.trueObj :  this.falseObj;
				},

				">" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver > args[0] ? this.trueObj :  this.falseObj;
				},
				
				"<=" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver <= args[0] ? this.trueObj :  this.falseObj;
				},

				">=" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver >= args[0] ? this.trueObj :  this.falseObj;
				},
				
				"==" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver == args[0] ? this.trueObj :  this.falseObj;
				}
			},

			"String" : {
				"+" : function(recver:Object, args:Array, sf:StackFrame):Object {
					if(typeof(args[0]) == "object")
						return this.createRubyString(recver.__native + args[0].__native);
					else
						return this.createRubyString(recver.__native + args[0]);
				},
				
				"*" : function(recver:Object, args:Array, sf:StackFrame):Object {
					var ary:Array = new Array(args[0]);
					for (var i:int = 0; i < args[0]; i++) 
					{
						ary[i] = recver.__native;
					}
					return this.createRubyString(ary.join(""));
				},
				
				"==" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver.__native == args[0].__native ? this.trueObj : this.falseObj;
				},
				
				"[]" : function(recver:Object, args:Array, sf:StackFrame):Object {
					if(args.length == 1 && typeof(args[0]) == "number") {
						var no:int = args[0];
						if(no < 0) 
							no = recver.__native.length + no;
						if(no < 0 || no >= recver.__native.length)
							return null;
						return recver.__native.charCodeAt(no);
					} else if(args.length == 2 && typeof(args[0]) == "number" && typeof(args[1]) == "number") {
						var start:int = args[0];
						if(start < 0) 
							start = recver.__native.length + start;
						if(start < 0 || start >= recver.__native.length)
							return null;
						if(args[1] < 0 || start + args[1] > recver.__native.length)
							return null;
						return this.createRubyString(recver.__native.substr(start, args[1]));
					} else {
						throw "Unsupported String[]";
					}
				}
			},
			
			"Array" : {
				"length" : function(recver:Object, args:Array, sf:StackFrame):int {
					return recver.__native.length;
				},
				
				"size" : function(recver:Object, args:Array, sf:StackFrame):int {
					return recver.__native.length;
				},
				
				"[]" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver.__native[args[0]];
				},
				
				"[]=" : function(recver:Object, args:Array, sf:StackFrame):void {
					recver.__native[args[0]] = args[1];
				},
				
				"join" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return this.createRubyString(recver.__native.join(args[0]));
				},
				
				"to_s" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return this.createRubyString(recver.__native.join(args[0]));
				}
			},
			
			"Hash" : {
				"[]" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver.__native[args[0].__native];
				},
				
				"[]=" : function(recver:Object, args:Array, sf:StackFrame):Object {
					if(!(args[0].__native in recver.__native)) {
						recver.__instanceVars.length++;
					}
					return (recver.__native[args[0].__native] = args[1]);
				},
				
				"length" : function(recver:Object, args:Array, sf:StackFrame):int {
					return recver.__instanceVars.length;
				},
				
				"size" : function(recver:Object, args:Array, sf:StackFrame):int {
					return recver.__instanceVars.length++;
				}
			},
			
			"Range" : {
				"each" : function(recver:Object, args:Array, sf:StackFrame):void {
					if(recver.__instanceVars.exclude_end == this.trueObj) {
						for (var i:int = recver.__instanceVars.first;i < recver.__instanceVars.last; i++) {
							this.invokeMethod(args[0], "yield", [i], sf, 0, false);
							sf.sp--;
						}
					} else {
						for (i = recver.__instanceVars.first;i <= recver.__instanceVars.last; i++) {
							this.invokeMethod(args[0], "yield", [i], sf, 0, false);
							sf.sp--;
						}
					}
				},
				
				"begin" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver.__instanceVars.first;
				},
				
				"first" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver.__instanceVars.first;
				},
				
				"end" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver.__instanceVars.last;
				},
				
				"last" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return recver.__instanceVars.last;
				},
				
				"exclude_end?" : function(recver:Object, args:Array, sf:StackFrame):int {
					return recver.__instanceVars.exclude_end;
				},
				
				"length" : function(recver:Object, args:Array, sf:StackFrame):int {
					with(recver.__instanceVars) {
						return (last - first + (exclude_end == this.trueObj ? 0 : 1));
					}
				},
				
				"size" : function(recver:Object, args:Array, sf:StackFrame):int {
					with(recver.__instanceVars) {
						return (last - first + (exclude_end == this.trueObj ? 0 : 1));
					}
				},
				
				"step" : function(recver:Object, args:Array, sf:StackFrame):void {
					var step:int;
					var proc:Object;
					if(args.length == 1) { 
						step = 1;
						proc = args[0];
					} else {
						step = args[0];
						proc = args[1];
					}
					
					if(recver.__instanceVars.exclude_end == this.trueObj) {
						for (var i:int = recver.__instanceVars.first;i < recver.__instanceVars.last; i += step) {
							this.invokeMethod(proc, "yield", [i], sf, 0, false);
							sf.sp--;
						}
					} else {
						for (i = recver.__instanceVars.first;i <= recver.__instanceVars.last; i += step) {
							this.invokeMethod(proc, "yield", [i], sf, 0, false);
							sf.sp--;
						}
					}
				}
			},
			
			"Time" : {
				"initialize" : function(recver:Object, args:Array, sf:StackFrame):void {
					recver.__instanceVars.date = new Date(); 
				},
				
				"to_s" : function(recver:Object, args:Array, sf:StackFrame):Object {
					return this.createRubyString(recver.__instanceVars.date.toString());
				},
				
				"to_f" : function(recver:Object, args:Array, sf:StackFrame):Number {
					return recver.__instanceVars.date.getTime() / 1000;
				}
			}
		};
		*/
	}
}