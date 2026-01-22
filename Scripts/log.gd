extends Node
# logv helper function to assist in debugging
# It's essentially a very fancy print statement that auto adds
# several common debugging needs
# You can call it from anywhere with Log.logv

# Set to false to disable all logv function calls
var enabled: bool = true
# Set to true to print what line of code the log is calling from
var show_location: bool = true
# Set to true to print a timestamp at the end of the line
var add_timestamp: bool = true
# Global verbosity level (suggestions):
# 0 = silent
# 1 = errors
# 2 = warnings
# 3 = info
# 4 = debug
# If the verbosity level provided to the logv function is more than
# this number, it will not print.
var verbosity: int = 4

# Usage: logv(verbosity level, args)
func logv(level: int, ...args):
	# Only print if allowed by verbosity
	if level > verbosity:
		return
	_log_internal(args)

# Internal, you only need to call logv
func _log_internal(args: Array):
	if not enabled:
		return

	var msg := ""

	for i in args.size():
		msg += str(args[i])
		if i < args.size() - 1:
			msg += " "

	if add_timestamp:
		msg += " [%d]" % Time.get_ticks_msec()

	if show_location:
		var info := _get_caller_info()
		print("[%s:%d %s()] %s" % [info.source, info.line, info.function, msg])
	else:
		print(msg)

func _get_caller_info() -> Dictionary:
	# Stack:
	# 0 = _get_caller_info
	# 1 = _log_internal
	# 2 = log / logv
	# 3 = actual caller
	var stack := get_stack()
	if stack.size() > 3:
		return stack[3]
	return {}
