export type StorageOptions = {
    /**
     * The id of the instance to be created. Default id is "default".
     */
    instanceID: string;
    /**
     * Specifies if the storage instance should be encrypted
     */
    initWithEncryption: boolean;
    /**
     * Specifies if the password be stored in Keychain
     *
     * Default: true
     */
    secureKeyStorage: boolean;
    /**
     * Set the AccessibleMode for iOS
     * Import IOSAccessibleStates from library to use it.
     */
    accessibleMode: string;
    /**
     * Multi Process or Single Process.
     *
     * Use Multi Process if your app needs to share storage between app widgets/extensions etc
     */
    processingMode: number;
    aliasPrefix: string;
    /**
     * The alias which is used to store the password in Keychain
     */
    alias: string | null;
    /**
     * Password for encrypted storage
     */
    key: string | null;
    /**
     * Specify the service name to use if using react-native-keychain library.
     */
    serviceName: string | null;
    /**
     * Is the storage ready?
     */
    initialized: boolean;
    /**
     * Persist default values in hooks
     */
    persistDefaults: boolean;
    /**
     * Toggle indexing of values by type.
     *
     * @default true
     */
    enableIndexing: boolean;
};
export type DataType = 'string' | 'number' | 'object' | 'array' | 'boolean';
export type GenericReturnType<T> = [key: string, value: T | null | undefined];
export type IndexType = 'stringIndex' | 'boolIndex' | 'numberIndex' | 'mapIndex' | 'arrayIndex';
export interface Indexer {
    [key: string]: any;
}
export interface MMKVJsiModule {
    getMultiObjectMMKV: (keys: any, instanceID: string) => any;
    clearMMKV: (instanceID: string) => any;
    indexer: Indexer;
    removeValuesMMKV: (keys: any, instanceID: string) => boolean;
    setArrayMMKV: (key: string, value: string, instanceID: string) => boolean;
    setArrayObjectMMKV: (key: string, value: any[], instanceID: string) => boolean;
    getArrayMMKV: (key: string, instanceID: string) => string;
    setMapMMKV: (key: string, value: string, instanceID: string) => boolean;
    setObjectMMKV: (key: string, value: object, instanceID: string) => boolean;
    getMapMMKV: (key: string, instanceID: string) => string;
    getObjectMMKV: (key: string, instanceID: string) => any;
    setStringMMKV: (key: string, value: string, instanceID: string) => boolean;
    getStringMMKV: (key: string, instanceID: string) => string;
    setMultiMMKV: (keys: any, values: any, dataType: string, instanceID: string) => boolean;
    getMultiMMKV: (keys: any, instanceID: string) => any;
    setNumberMMKV: (key: string, value: number, instanceID: string) => boolean;
    getNumberMMKV: (key: string, instanceID: string) => number;
    setBoolMMKV: (key: string, value: boolean, instanceID: string) => boolean;
    getBoolMMKV: (key: string, instanceID: string) => boolean;
    containsKeyMMKV: (key: string, instanceID: string) => boolean;
    removeValueMMKV: (key: string, instanceID: string) => boolean;
    initializeMMKV: () => undefined;
    setupMMKVInstance: (id: string, mode: number, cryptKey: string, path: string, accessibleOnly: boolean) => boolean;
    clearMemoryCache: (instanceID: string) => any;
    getAllKeysMMKV: (instanceID: string) => any;
    getIndexMMKV: (index: string, instanceID: string) => string[];
    getSecureKey: (alias: string) => string;
    setSecureKey: (alias: string, key: string, accessibleMode?: string) => any;
    setMMKVServiceName?: (alias: string, serviceName: string) => any;
    secureKeyExists: (alias: string) => boolean;
    removeSecureKey: (alias: string) => boolean;
    encryptMMKV: (cryptkey: string, instanceID: string) => boolean;
    decryptMMKV: (instanceID: string) => boolean;
}
//# sourceMappingURL=index.d.ts.map