package hxenv;

using StringTools;

class Utils {
	public static var valChar:Map<Int, Bool> = populateValChars();

	static function populateValChars():Map<Int, Bool> {
		var valChar = new Map<Int, Bool>();

		// populate value chars with bools at ascii positions
		for (i in 'A'.code...'Z'.code + 1) {
			valChar[i] = true;
		}

		for (i in 'a'.code...'z'.code + 1) {
			valChar[i] = true;
		}

		for (i in '0'.code...'9'.code + 1) {
			valChar[i] = true;
		}

		valChar["_".code] = true;
		valChar[".".code] = true;
		valChar["-".code] = true;
		valChar["/".code] = true;
		valChar[":".code] = true;
		valChar["@".code] = true;
		valChar["#".code] = true;
		valChar["%".code] = true;
		valChar["~".code] = true;
		valChar["+".code] = true;
		valChar[",".code] = true;
		valChar["=".code] = true;
		return valChar;
	}

	public static var idChar:Map<Int, Bool> = populateIdChars();

	static function populateIdChars():Map<Int, Bool> {
		var idChar = new Map<Int, Bool>();

		// populate identifier chars with bools at ascii positions
		for (i in 'A'.code...'Z'.code + 1) {
			idChar[i] = true;
		}

		for (i in 'a'.code...'z'.code + 1) {
			idChar[i] = true;
		}

		for (i in '0'.code...'9'.code + 1) {
			idChar[i] = true;
		}

		idChar["_".code] = true;
		return idChar;
	}

	public static function normaliseNewLine(value:String):String return StringTools.replace(value, "\n", "\\n");

	public static function validateKey(key:String):Void {
		for (char in key) {
			if(char == '\n'.code) throw 'Unexpected char `\\n` in value of key: `${normaliseNewLine(key)}`!';
			if (!idChar[char]) throw 'Unexpected char `${String.fromCharCode(char)}` in key: "${key}"!';
		}
	}

	public static function validateRawValue(value:String, key:String):Void {
		for (char in value) {
			if(char == '\n'.code) throw 'Unexpected char `\\n` in value of key: `${key}`!';
			if (!valChar[char]) throw 'Unexpected char `${String.fromCharCode(char)}` in value of key: `${key}`!';
		}
	}

	public static function validateSingleQuotedValue(value:String, key:String):Void {
		for (char in value) {
			if(char == '\n'.code) throw 'Unexpected char `\\n` in value of key: `${key}`!';
			if (char == "'".code) throw 'Unexpected char `${String.fromCharCode(char)}` in value of key: `${key}`!';
		}
	}

	public static function validateComment(value:String):Void {
		for (char in value) {
			if(char == '\n'.code) throw 'Unexpected char `\\n` in value of comment: `${normaliseNewLine(value)}`!';
		}
	}
}
