#import "MMKVStorage.h"
#import "YeetJSIUtils.h"

#import "SecureStorage.h"
#import <MMKV/MMKV.h>
#import <jsi/jsi.h>

#import <React/RCTBridge+Private.h>
#import <React/RCTUtils.h>


using namespace facebook;
using namespace jsi;
using namespace std;

template <typename Lambda>
void CreateFunction(jsi::Runtime &rt, const char* name, int count, Lambda &&callback) {
    auto fn = Function::createFromHostFunction(rt, jsi::PropNameID::forAscii(rt, name), count, callback);
    rt.global().setProperty(rt, name, move(fn));
}

#define CREATE_FUNCTION(name, argumentsCount, body) \
CreateFunction(jsiRuntime, name, argumentsCount, [](Runtime &runtime, const Value &thisValue, const Value *arguments, size_t count) -> Value {    \
body    \
})

#define nsstring(arg) \
convertJSIStringToNSString(runtime, arg.getString(runtime))

@implementation MMKVStorage
@synthesize bridge = _bridge;
@synthesize methodQueue = _methodQueue;
NSString *rPath = @"";
NSMutableDictionary *mmkvInstances;
NSMutableDictionary *serviceNames;
SecureStorage *_secureStorage;
NSString *appGroupId;
NSMutableDictionary *indexes;
NSMutableDictionary *indexingEnabled;

RCT_EXPORT_MODULE(MMKVStorage)

+ (BOOL)requiresMainQueueSetup {

    return YES;
}

- (instancetype)init
{
    self = [super init];
    indexingEnabled = [NSMutableDictionary dictionary];
    indexes = [NSMutableDictionary dictionary];

    RCTExecuteOnMainQueue(^{

        NSString *rootDir;

        appGroupId = [[NSBundle mainBundle].infoDictionary valueForKey:@"appGroupId"];
        NSString *disableMMKVBackup = [[NSBundle mainBundle].infoDictionary valueForKey:@"disableMMKVBackup"];

        if (appGroupId != nil) {
            NSURL *appGroup = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:appGroupId];
            rootDir = [appGroup.path stringByAppendingPathComponent:@"mmkv"];
            rPath = rootDir;
            [MMKV initializeMMKV:nil groupDir:rootDir logLevel:MMKVLogInfo];
        } else {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                                 NSUserDomainMask, YES);
            NSString *libraryPath = (NSString *)[paths firstObject];
            rootDir = [libraryPath stringByAppendingPathComponent:@"mmkv"];
            rPath = rootDir;
            [MMKV initializeMMKV:rootDir];
        }

        if (disableMMKVBackup) {
            NSError *error = nil;
            NSURL *url = [NSURL fileURLWithPath:rootDir isDirectory:YES];
            [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
        }

        _secureStorage = [[SecureStorage alloc] init];
    });

    return self;
}

MMKV *getInstance(NSString *ID) {
    if ([[mmkvInstances allKeys] containsObject:ID]) {
        MMKV *kv = [mmkvInstances objectForKey:ID];

        return kv;
    } else {
        return NULL;
    }
}

NSString *getServiceName(NSString *alias) {
    if ([[serviceNames allKeys] containsObject:alias]) {
        NSString *serviceName = [serviceNames objectForKey:alias];
        return serviceName;
    } else {
        return nil;
    }
}

void setServiceName(NSString *alias, NSString *serviceName) {
    [serviceNames setObject:serviceName forKey: alias];
}

// Installing JSI Bindings as done by
// https://github.com/mrousavy/react-native-mmkv

#ifdef RCT_NEW_ARCH_ENABLED

- (NSNumber *)install {
    RCTCxxBridge* cxxBridge = (RCTCxxBridge*)_bridge;
    if (cxxBridge == nil) {
        return @NO;
    }

    auto jsiRuntime = (jsi::Runtime*) cxxBridge.runtime;
    if (jsiRuntime == nil) {
        return @NO;
    }

    mmkvInstances = [NSMutableDictionary dictionary];
    serviceNames = [NSMutableDictionary dictionary];

    [self migrate];

    RCTBridge *bridge = [RCTBridge currentBridge];

    install(*(jsi::Runtime *)jsiRuntime);
    return @YES;
}

#else
RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(install) {
    RCTCxxBridge* cxxBridge = (RCTCxxBridge*)_bridge;
    if (cxxBridge == nil) {
        return @false;
    }

    auto jsiRuntime = (jsi::Runtime*) cxxBridge.runtime;
    if (jsiRuntime == nil) {
        return @false;
    }

    mmkvInstances = [NSMutableDictionary dictionary];
    serviceNames = [NSMutableDictionary dictionary];

    [self migrate];

    RCTBridge *bridge = [RCTBridge currentBridge];

    install(*(jsi::Runtime *)jsiRuntime);
    return @true;
}
#endif

MMKV *createInstance(NSString *ID, MMKVMode mode, NSString *key,
                     NSString *path) {

    MMKV *kv;

    if (![key isEqual:@""] && [path isEqual:@""]) {
        NSData *cryptKey = [key dataUsingEncoding:NSUTF8StringEncoding];
        kv = [MMKV mmkvWithID:ID cryptKey:cryptKey mode:mode];
    } else if (![path isEqual:@""] && [key isEqual:@""]) {
        kv = [MMKV mmkvWithID:ID mode:mode];
    } else if (![path isEqual:@""] && ![key isEqual:@""]) {
        NSData *cryptKey = [key dataUsingEncoding:NSUTF8StringEncoding];
        kv = [MMKV mmkvWithID:ID cryptKey:cryptKey mode:mode];
    } else {
        kv = [MMKV mmkvWithID:ID mode:mode];
    }
    [mmkvInstances setObject:kv forKey:ID];

    return kv;
}

void setIndex(MMKV *kv, NSString *type, NSString *key) {
    if (!indexingEnabled[[kv mmapID]]) return;
    NSMutableDictionary *index = getIndex(kv, type);

    if (!index[key]) {
        index[key] = @1;

        [kv setObject:index forKey:type];
    }
}

void setIndexes(MMKV *kv, NSString *type, NSArray *keys) {
    if (!indexingEnabled[[kv mmapID]]) return;
    NSMutableDictionary *index = getIndex(kv, type);

    for (int i=0;i < keys.count; i++) {
        index[keys[i]] = @1;
    }

    [kv setObject:index forKey:type];
}

NSMutableDictionary *getIndex(MMKV *kv, NSString *type) {
    @try {
        if (!indexingEnabled[[kv mmapID]]) return [NSMutableDictionary dictionary];

        NSMutableDictionary *kvIndexes = indexes[[kv mmapID]];
        if (!kvIndexes[type]) {
            if (![kv containsKey:type]) {
                kvIndexes[type] = [NSMutableDictionary dictionary];
            } else {
                id object = [kv getObjectOfClass:NSMutableDictionary.class forKey:type];
                if ([object isKindOfClass:NSMutableDictionary.class]) {
                    kvIndexes[type] = object;
                } else if ([object isKindOfClass:NSMutableArray.class]) {
                    upgradeIndex(kv, type);
                    kvIndexes[type] = [kv getObjectOfClass:NSMutableDictionary.class forKey:type];
                }
            }
        }
        return kvIndexes[type];
    } @catch(NSException *e) {

        return [NSMutableDictionary dictionary];
    }
}

void removeKeysFromIndexer(MMKV *kv, NSArray *keys) {
    if (!indexingEnabled[[kv mmapID]]) return;

    bool strings = false;
    bool objects = false;
    bool arrays = false;
    bool numbers = false;
    bool booleans = false;

    for (int i=0;i < keys.count; i++) {
        NSString *key = keys[i];
        NSMutableDictionary *index = getIndex(kv, @"stringIndex");

        if (index[key]) {
            [index removeObjectForKey:key];
            strings = true;
            continue;
        }

        index = getIndex(kv, @"mapIndex");

        if (index[key]) {
            [index removeObjectForKey:key];
            objects = true;
            continue;
        }

        index = getIndex(kv, @"arrayIndex");

        if (index[key]) {
            [index removeObjectForKey:key];
            arrays = true;
            continue;
        }

        index = getIndex(kv, @"numberIndex");

        if (index[key]) {
            [index removeObjectForKey:key];
            numbers = true;
            continue;
        }

        index = getIndex(kv, @"boolIndex");

        if (index[key]) {
            [index removeObjectForKey:key];
            booleans = true;
            continue;
        }
    }


    if (strings) [kv setObject:getIndex(kv, @"stringIndex") forKey:@"stringIndex"];
    if (objects) [kv setObject:getIndex(kv, @"mapIndex") forKey:@"mapIndex"];
    if (arrays) [kv setObject:getIndex(kv, @"arrayIndex") forKey:@"arrayIndex"];
    if (numbers) [kv setObject:getIndex(kv, @"numberIndex") forKey:@"numberIndex"];
    if (booleans) [kv setObject:getIndex(kv, @"boolIndex") forKey:@"boolIndex"];

}

void upgradeIndex(MMKV *kv, NSString *type) {
    @try {
        if (![kv containsKey:type]) return;
        id object = [kv getObjectOfClass:NSMutableArray.class forKey:type];
        if ([object isKindOfClass:NSMutableArray.class]) {
            NSMutableArray *array = (NSMutableArray*) object;
            if (array.count) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                for (int i=0;i < array.count;i++) {
                    [dic setValue:@1 forKey:array[i]];
                }
                [kv removeValueForKey:type];
                [kv setObject:dic forKey:type];
            }
        }
    } @catch(NSException *e) {
        NSLog(@"%@", e.reason);
    }
}

static void install(jsi::Runtime &jsiRuntime) {

    CREATE_FUNCTION("initializeMMKV", 0, {
        [MMKV initializeMMKV:rPath];
        return Value::undefined();
    });


    CREATE_FUNCTION("setupMMKVInstance", 5, {
        NSString *ID = nsstring(arguments[0]);

        MMKVMode mode = (MMKVMode)(int)arguments[1].getNumber();
        NSString *cryptKey = nsstring(arguments[2]);
        NSString *path = nsstring(arguments[3]);

        createInstance(ID, mode, cryptKey, path);

        auto *kv = getInstance(ID);

        indexingEnabled[ID] = arguments[4].getBool() ? @YES : @NO;
        indexes[ID] = [NSMutableDictionary dictionary];

        return Value(true);
    });

    CREATE_FUNCTION("setMMKVServiceName", 2, {
        NSString *alias = nsstring(arguments[0]);
        NSString *serviceName = nsstring(arguments[1]);
        setServiceName(alias, serviceName);
        return Value::undefined();
    });


    CREATE_FUNCTION("setStringMMKV", 3, {
        MMKV *kv = getInstance(nsstring(arguments[2]));

        if (!kv) {
            return Value::undefined();
        }

        NSString *key = nsstring(arguments[0]);
        setIndex(kv, @"stringIndex", key);
        [kv setString:nsstring(arguments[1]) forKey:key];

        return Value(true);
    });

    #define std_string(arg) \
    arg.getString(runtime).utf8(runtime)

    #define HOSTFN(name, basecount) \
    jsi::Function::createFromHostFunction( \
    runtime, \
    jsi::PropNameID::forAscii(runtime, name), \
    basecount, \
    [=](jsi::Runtime &runtime, const jsi::Value &thisValue, const jsi::Value *args, size_t count) -> jsi::Value


    CreateFunction(jsiRuntime, "setMultiMMKV", 4, [=](Runtime &runtime, const Value &thisValue, const Value *arguments, size_t count) -> Value {
        auto keys =  arguments[0].getObject(runtime).asArray(runtime);
        auto values =  arguments[1].getObject(runtime).asArray(runtime);
        auto dataType = nsstring(arguments[2]);
        auto kvName = nsstring(arguments[3]);
        auto kv = getInstance(kvName);
        auto size = keys.length(runtime);

        NSMutableArray *keysToRemove = [NSMutableArray array];

        for (int i=0;i < size;i++) {
            NSString *key = nsstring(keys.getValueAtIndex(runtime, i));

            if (values.getValueAtIndex(runtime, i).isString()) {
                NSString *value = nsstring(values.getValueAtIndex(runtime, i));
                [kv setString:value forKey:key];
            } else {
                if ([kv containsKey:key]) {
                    [keysToRemove addObject:key];
                }
            }
        }

        [kv removeValuesForKeys:keysToRemove];
        removeKeysFromIndexer(kv, keysToRemove);
        setIndexes(kv, dataType, convertJSIArrayToNSArray(runtime, keys));
        return jsi::Value(true);

    });

    CreateFunction(jsiRuntime, "getMultiMMKV", 2, [=](Runtime &runtime, const Value &thisValue, const Value *arguments, size_t count) -> Value {
        auto keys =  arguments[0].getObject(runtime).asArray(runtime);
        auto kvName = nsstring(arguments[1]);
        auto size = keys.length(runtime);
        MMKV *kv = getInstance(kvName);

        jsi::Array values = jsi::Array(runtime, size);

        for (int i=0;i < size;i++) {
            NSString *key =  convertJSIStringToNSString(runtime, keys.getValueAtIndex(runtime, i).asString(runtime));
            if ([kv containsKey:key]) {
                values.setValueAtIndex(runtime, i, convertNSStringToJSIString(runtime, [kv getStringForKey:key]));
            } else {
                values.setValueAtIndex(runtime, i,  jsi::Value::undefined());
            }
        }


        return values;

    });

    CREATE_FUNCTION("getStringMMKV", 2, {
        MMKV *kv = getInstance(nsstring(arguments[1]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        if ([kv containsKey:key]) {
            return Value(convertNSStringToJSIString(runtime, [kv getStringForKey:key]));
        } else {
            return Value::null();
        }
    });


    CREATE_FUNCTION("setMapMMKV", 3, {
        MMKV *kv = getInstance(nsstring(arguments[2]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        setIndex(kv, @"mapIndex", key);

        [kv setString:nsstring(arguments[1]) forKey:key];

        return Value(true);
    });

    CREATE_FUNCTION("setObjectMMKV", 3, {
        MMKV *kv = getInstance(nsstring(arguments[2]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        setIndex(kv, @"mapIndex", key);

        // Convert the JavaScript object to JSON
        auto objectValue = arguments[1].asObject(runtime);
        auto stringifyFunc = runtime.global().getPropertyAsFunction(runtime, "JSON").getPropertyAsFunction(runtime, "stringify");
        auto jsonString = stringifyFunc.call(runtime, objectValue).asString(runtime);

        [kv setString:nsstring(jsonString) forKey:key];

        return Value(true);
    });

    CREATE_FUNCTION("getMapMMKV", 2, {
        MMKV *kv = getInstance(nsstring(arguments[1]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        if ([kv containsKey:key]) {
            return Value(convertNSStringToJSIString(runtime, [kv getStringForKey:key]));
        } else {
            return Value::null();
        }
    });

    CREATE_FUNCTION("getObjectMMKV", 2, {
        MMKV *kv = getInstance(nsstring(arguments[1]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        if ([kv containsKey:key]) {
            NSString *jsonString = [kv getStringForKey:key];
            if (jsonString) {
                // Parse the JSON string
                auto parseFunc = runtime.global().getPropertyAsFunction(runtime, "JSON").getPropertyAsFunction(runtime, "parse");
                auto jsonValue = parseFunc.call(runtime, convertNSStringToJSIString(runtime, jsonString));
                return jsonValue;
            }
        }
        return Value::null();
    });

    CREATE_FUNCTION("setArrayMMKV", 3, {
        MMKV *kv = getInstance(nsstring(arguments[2]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        setIndex(kv, @"arrayIndex", key);

        [kv setString:nsstring(arguments[1]) forKey:key];

        return Value(true);
    });

    CREATE_FUNCTION("setArrayObjectMMKV", 3, {
        MMKV *kv = getInstance(nsstring(arguments[2]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        setIndex(kv, @"arrayIndex", key);

        // Convert the JavaScript array to JSON
        auto arrayValue = arguments[1].asObject(runtime).asArray(runtime);
        auto stringifyFunc = runtime.global().getPropertyAsFunction(runtime, "JSON").getPropertyAsFunction(runtime, "stringify");
        auto jsonString = stringifyFunc.call(runtime, arrayValue).asString(runtime);

        [kv setString:nsstring(jsonString) forKey:key];

        return Value(true);
    });

    CREATE_FUNCTION("getArrayMMKV", 2, {
        MMKV *kv = getInstance(nsstring(arguments[1]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        if ([kv containsKey:key]) {
            return Value(convertNSStringToJSIString(runtime, [kv getStringForKey:key]));
        } else {
            return Value::null();
        }
    });


    CREATE_FUNCTION("setNumberMMKV", 3, {
        MMKV *kv = getInstance(nsstring(arguments[2]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        setIndex(kv, @"numberIndex", key);

        [kv setDouble:arguments[1].getNumber() forKey:key];

        return Value(true);
    });


    CREATE_FUNCTION("getNumberMMKV", 2, {
        MMKV *kv = getInstance(nsstring(arguments[1]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        if ([kv containsKey:key]) {
            return Value([kv getDoubleForKey:key]);
        } else {
            return Value::null();
        }
    });

    CREATE_FUNCTION("setBoolMMKV", 3, {
        MMKV *kv = getInstance(nsstring(arguments[2]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        setIndex(kv, @"boolIndex", key);

        [kv setBool:arguments[1].getBool() forKey:key];

        return Value(true);
    });


    CREATE_FUNCTION("getBoolMMKV", 2, {
        MMKV *kv = getInstance(nsstring(arguments[1]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        if ([kv containsKey:key]) {
            return Value([kv getBoolForKey:key]);
        } else {
            return Value::null();
        }
    });


    CREATE_FUNCTION("removeValueMMKV", 2, {
        MMKV *kv = getInstance(nsstring(arguments[1]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        removeKeysFromIndexer(kv, [NSArray arrayWithObject:key]);
        [kv removeValueForKey:key];

        return Value(true);
    });

    CREATE_FUNCTION("removeValuesMMKV", 2, {
        MMKV *kv = getInstance(nsstring(arguments[1]));

        if (!kv) return Value::undefined();

        auto keys =  convertJSIArrayToNSArray(runtime, arguments[0].getObject(runtime).asArray(runtime));
        [kv removeValuesForKeys:keys];
        removeKeysFromIndexer(kv, keys);

        return Value(true);
    });

    CREATE_FUNCTION("getAllKeysMMKV", 1, {
        MMKV *kv = getInstance(nsstring(arguments[0]));

        if (!kv) return Value::undefined();

        NSArray *keys = [kv allKeys];

        return Value(convertNSArrayToJSIArray(runtime, keys));
    });

    CREATE_FUNCTION("getIndexMMKV", 2, {
        MMKV *kv = getInstance(nsstring(arguments[1]));

        if (!kv) return Value::undefined();

        NSMutableDictionary *keys = getIndex(kv, nsstring(arguments[0]));

        return Value(convertNSArrayToJSIArray(runtime, [keys allKeys]));
    });

    CREATE_FUNCTION("containsKeyMMKV", 2, {
        MMKV *kv = getInstance(nsstring(arguments[1]));

        if (!kv) return Value::undefined();

        return Value([kv containsKey:nsstring(arguments[0])]);
    });

    CREATE_FUNCTION("clearMMKV", 1, {
        MMKV *kv = getInstance(nsstring(arguments[0]));

        if (!kv) return Value::undefined();

        [kv clearAll];
        indexes[[kv mmapID]] = [NSMutableDictionary dictionary];

        return Value(true);

    });


    CREATE_FUNCTION("clearMemoryCache", 1, {
        MMKV *kv = getInstance(nsstring(arguments[0]));

        if (!kv) return Value::undefined();

        [kv clearMemoryCache];

        return Value(true);

    });

    CREATE_FUNCTION("encryptMMKV", 2, {
        MMKV *kv = getInstance(nsstring(arguments[1]));

        if (!kv) return Value::undefined();

        NSString *key = nsstring(arguments[0]);

        NSData *cryptKey = [key dataUsingEncoding:NSUTF8StringEncoding];
        [kv reKey:cryptKey];

        return Value(true);

    });

    CREATE_FUNCTION("decryptMMKV", 1, {
        MMKV *kv = getInstance(nsstring(arguments[0]));

        if (!kv) return Value::undefined();

        [kv reKey:NULL];

        return Value(true);

    });


    // Secure Store


    CREATE_FUNCTION("setSecureKey", 3, {
        NSString *alias = nsstring(arguments[0]);
        NSString *key = nsstring(arguments[1]);
        NSString *accValue = nsstring(arguments[2]);

        [_secureStorage setServiceName: getServiceName(alias)];
        [_secureStorage setSecureKey:alias value:key options:@{@"accessible" : accValue}];

        return Value(true);

    });

    CREATE_FUNCTION("getSecureKey", 1, {
        NSString *alias = nsstring(arguments[0]);

        [_secureStorage setServiceName: getServiceName(alias)];
        return Value(convertNSStringToJSIString(runtime, [_secureStorage getSecureKey:alias]));

    });


    CREATE_FUNCTION("secureKeyExists", 1, {
        NSString *alias = nsstring(arguments[0]);

        [_secureStorage setServiceName: getServiceName(alias)];
        return Value([_secureStorage secureKeyExists:alias]);

    });

    CREATE_FUNCTION("removeSecureKey", 1, {
        NSString *alias = nsstring(arguments[0]);

        [_secureStorage setServiceName: getServiceName(alias)];
        [_secureStorage removeSecureKey:alias];
        return Value(true);

    });

    // Secure Store End
}

- (void)migrate {
    MMKV *kv;

    if (appGroupId != nil) {
        kv = [MMKV mmkvWithID:@"mmkvIdStore" mode:MMKVMultiProcess];
    } else {
        kv = [MMKV mmkvWithID:@"mmkvIdStore" mode:MMKVSingleProcess];
    }

    [mmkvInstances setObject:kv forKey:@"mmkvIdStore"];
    if ([kv containsKey:@"mmkvIdData"]) {
        NSMutableDictionary *oldStore =
        [kv getObjectOfClass:NSMutableDictionary.class forKey:@"mmkvIdData"];
        NSArray *keys = [oldStore allKeys];

        for (int i = 0; i < keys.count; i++) {
            NSString *storageKey = keys[i];
            NSMutableDictionary *entry = [oldStore objectForKey:storageKey];
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:entry
                                                               options:0
                                                                 error:&error];
            NSString *jsonString =
            [[NSString alloc] initWithData:jsonData
                                  encoding:NSUTF8StringEncoding];
            [kv setString:jsonString forKey:storageKey];

            if ([[entry valueForKey:@"encrypted"] boolValue]) {
                NSString *alias = [entry valueForKey:@"alias"];
                [_secureStorage setServiceName: getServiceName(alias)];
                if ([_secureStorage searchKeychainCopyMatchingExists:alias]) {
                    NSString *key = [_secureStorage searchKeychainCopyMatching:alias];
                    if (key != nil) {
                        NSData *cryptKey = [key dataUsingEncoding:NSUTF8StringEncoding];
                        MMKV *kvv = [MMKV mmkvWithID:storageKey
                                            cryptKey:cryptKey
                                                mode:MMKVSingleProcess];

                        [self writeToJson:kvv];
                    }
                };
            } else {
                MMKV *kvv = [MMKV mmkvWithID:storageKey mode:MMKVSingleProcess];
                [self writeToJson:kvv];
            }
        }

        [kv removeValueForKey:@"mmkvIdData"];
    }
}

- (void)writeToJson:(MMKV *)kv {
    upgradeIndex(kv, @"mapIndex");
    NSDictionary *mapIndex = getIndex(kv, @"mapIndex");
    if (mapIndex != nil) {
        for (NSString *key in [mapIndex allKeys]) {
            NSDictionary *data = [kv getObjectOfClass:NSDictionary.class forKey:key];
            if (data != nil) {
                NSError *error;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                                   options:0
                                                                     error:&error];
                NSString *jsonString =
                [[NSString alloc] initWithData:jsonData
                                      encoding:NSUTF8StringEncoding];
                [kv setString:jsonString forKey:key];
            }
        }
    }
    upgradeIndex(kv, @"arrayIndex");
    NSDictionary *arrayIndex = getIndex(kv, @"arrayIndex");
    if (arrayIndex != nil) {
        for (NSString *key in [arrayIndex allKeys]) {
            NSDictionary *data =
            [kv getObjectOfClass:NSDictionary.class forKey:key];

            if (data != nil) {
                NSMutableArray *array = [data objectForKey:key];
                if (array != nil) {
                    NSError *error;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array
                                                                       options:0
                                                                         error:&error];
                    NSString *jsonString =
                    [[NSString alloc] initWithData:jsonData
                                          encoding:NSUTF8StringEncoding];
                    [kv setString:jsonString forKey:key];
                }
            }
        }
    }

    NSMutableArray *intIndex = [kv getObjectOfClass:NSMutableArray.class forKey:@"intIndex"];
    if (intIndex != nil) {
        for (NSString *key in intIndex) {
            int64_t intVal = [kv getInt64ForKey:key];
            [kv setDouble:double(intVal) forKey:key];
        }
        [kv setObject:intIndex forKey:@"numberIndex"];
        upgradeIndex(kv, @"numberIndex");
        [kv removeValueForKey:@"intIndex"];
    }
}



// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMMKVStorageSpecJSI>(params);
}
#endif

@end
