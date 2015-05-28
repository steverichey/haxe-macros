package util;

import sys.FileSystem;
import sys.FileStat;
import haxe.crypto.Md5;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;

/**
 * Some helpful macro utils.
 *
 * @see https://github.com/jasononeil/compiletime
 * @see http://notes.underscorediscovery.com/haxe-compile-time-macros/
 * @see https://github.com/MarcWeber/haxe-macro-examples
 * @see http://haxe.org/manual/macro.html
 */
class Macro
{
    macro public static function BUILD_TIME():Expr {
        return toExpr(Date.now().toString());
    }

    macro public static function BUILD_NUMBER():Expr {
        var xml = Xml.parse(getContent("Project.xml"));
        var build_number = 0;

        for (el in xml.elements()) {
            for (sub in el.elementsNamed("app")) {
                for (att in sub.attributes()) {
                    if (att == "build-number") {
                        build_number = Std.parseInt(sub.get(att));
                        build_number++;
                        sub.set(att, Std.string(build_number));
                        File.saveContent("Project.xml", xml.toString());
                        break;
                    }
                }
            }
        }

        return toExpr(build_number);
    }

    macro public static function BUILD_VERSION():Expr {
        var version = getXml("Project.xml", "app", "version");
        return toExpr(version);
    }

    macro public static function BUILD_ID():Expr {
        var stats = FileSystem.stat("./");
        return toExpr(Md5.encode(Std.string(stats)));
    }

    macro public static function APP_NAME():Expr {
        var name = getXml("Project.xml", "app", "title");
        return toExpr(name);
    }

    macro public static function USER_NAME():Expr {
        var success = true;

        var username = getContent(USER_PATH, function() {
            success = false;
        });

        if (!success) {
            username = "unknown";
        }

        return toExpr(username);
    }

    macro public static function OPENFL_VERSION():Expr {
        return toExpr(getContent("/usr/lib/haxe/lib/openfl/.current"));
    }

    macro public static function LIME_VERSION():Expr {
        return toExpr(getContent("/usr/lib/haxe/lib/lime/.current"));
    }

    macro public static function FLIXEL_VERSION():Expr {
        return toExpr(getContent("/usr/lib/haxe/lib/flixel/.current"));
    }

    #if macro
    static function toExpr(v:Dynamic) {
        return Context.makeExpr(v, Context.currentPos());
    }

    static function getContent(path:String, ?error:Void->Void) {
        var result = "";

        try {
            result = File.getContent(path);
        } catch (e:Dynamic) {
            if (error != null) {
                error();
                return result;
            } else {
                return Context.error('Failed to load file: $e', Context.currentPos());
            }
        }

        return result;
    }

    static function getXml(path:String, elementName:String, attributeName: String) {
        var xml = Xml.parse(getContent(path));
        var result = "";

        for (el in xml.elements()) {
            for (sub in el.elementsNamed(elementName)) {
                for (att in sub.attributes()) {
                    if (att == attributeName) {
                        result = sub.get(att);
                        break;
                    }
                }
            }
        }

        return result;
    }

    static inline var USER_PATH  = ".user";
    #end
}
