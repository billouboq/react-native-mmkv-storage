import encryption from './encryption';
import EventManager from './eventmanager';
import indexer from './indexer/indexer';
import transactions from './transactions';
import { DataType, StorageOptions } from './types';
export default class MMKVInstance {
    transactions: transactions;
    instanceID: string;
    encryption: encryption;
    indexer: indexer;
    ev: EventManager;
    options: StorageOptions;
    constructor(id: string);
    isRegisterd(key: string): Function[];
    handleNullOrUndefined(key: string, value: any): boolean;
    /**
     * Set a string value to storage for the given key.
     * This method is added for redux-persist/zustand support.
     *
     */
    setItem(key: string, value: string, callback?: (err?: Error | null) => void): Promise<unknown>;
    /**
     * Get the string value for the given key.
     * This method is added for redux-persist/zustand support.
     */
    getItem(key: string, callback?: (error?: Error | null, result?: string | null) => void): Promise<unknown>;
    /**
     * Set a string value to storage for the given key.
     */
    setString: (key: string, value: string) => boolean | undefined;
    /**
     * Set a string value to storage for the given key asynchronously.
     */
    setStringAsync(key: string, value: string): Promise<boolean | null | undefined>;
    /**
     * Get the string value for the given key.
     */
    getString: (key: string, callback?: (error: any, value: string | undefined | null) => void) => string | null | undefined;
    /**
     * Get the string value for the given key asynchronously.
     */
    getStringAsync(key: string): Promise<string | null | undefined>;
    /**
     * Set a number value to storage for the given key.
     */
    setInt: (key: string, value: number) => boolean | undefined;
    /**
     * Set a number value to storage for the given key asynchronously.
     */
    setIntAsync(key: string, value: number): Promise<boolean | null | undefined>;
    /**
     * Get the number value for the given key
     */
    getInt: (key: string, callback?: (error: any, value: number | undefined | null) => void) => number | null | undefined;
    /**
     * Get the number value for the given key asynchronously.
     */
    getIntAsync(key: string): Promise<number | null | undefined>;
    /**
     * Set a boolean value to storage for the given key
     */
    setBool: (key: string, value: boolean) => boolean | undefined;
    /**
     * Set a boolean value to storage for the given key asynchronously.
     */
    setBoolAsync(key: string, value: boolean): Promise<boolean | null | undefined>;
    /**
     * Get the boolean value for the given key.
     */
    getBool: (key: string, callback?: (error: any, value: boolean | undefined | null) => void) => boolean | null | undefined;
    /**
     * Get the boolean value for the given key asynchronously.
     */
    getBoolAsync(key: string): Promise<boolean | null | undefined>;
    /**
     * Set an Object to storage for a given key.
     *
     * Note that this function does **not** work with the Map data type
     */
    setMap: (key: string, value: object) => boolean | undefined;
    /**
     * Set an Object to storage for a given key asynchronously.
     */
    setMapAsync(key: string, value: object): Promise<boolean | null | undefined>;
    /**
     * Get an Object from storage for a given key.
     */
    getMap: <T>(key: string, callback?: (error: any, value: T | undefined | null) => void) => T | null | undefined;
    /**
     * Get an Object from storage for a given key asynchronously.
     */
    getMapAsync<T>(key: string): Promise<T | null | undefined>;
    /**
     * Set items in bulk of same type at once
     *
     * If a value against a key is null/undefined, it will be
     * set as null.
     *
     * @param keys Array of keys
     * @param values Array of values
     * @param type
     */
    setMultipleItemsAsync(items: [string, any][], type: DataType | 'map'): Promise<boolean>;
    /**
     * Retrieve multiple items for the given array of keys
     */
    getMultipleItemsAsync<T>(keys: string[], type: DataType | 'map'): Promise<[string, T][]>;
    /**
     * Set an array to storage for the given key.
     */
    setArray: (key: string, value: any[]) => boolean | undefined;
    /**
     * get an array from the storage for give key.
     */
    getArray: <T>(key: string, callback?: (error: any, value: T[] | undefined | null) => void) => T[] | null | undefined;
    /**
     * Retrieve multiple items for the given array of keys.
     *
     */
    getMultipleItems: <T>(keys: string[], type: DataType | "map") => [string, T][];
    /**
     *
     * Get all Storage Instance IDs that are currently loaded.
     *
     */
    getCurrentMMKVInstanceIDs(): {
        [x: string]: boolean;
    };
    /**
     *
     * Get all Storage Instance IDs.
     *
     */
    getAllMMKVInstanceIDs(): string[];
    /**
     * Remove an item from storage for a given key.
     *
     * If you are removing large number of keys, use `removeItems` instead.
     */
    removeItem(key: string): boolean;
    /**
     * Remove multiple items from storage for given keys
     *
     */
    removeItems(keys: string[]): boolean;
    /**
     * Remove all keys and values from storage.
     */
    clearStore(): any;
    /**
     * Get the key and alias for the encrypted storage
     */
    getKey(): {
        alias: string;
        key: string;
    };
    /**
     * Clear memory cache of the current MMKV instance
     */
    clearMemoryCache(): any;
    /**
     * Set an Object to storage for the given key.
     *
     * This method stringifies the object on the JS side and stores it.
     * Functionally equivalent to setMap but with a more intuitive name.
     */
    setObject: (key: string, value: object) => boolean | undefined;
    /**
     * Get an Object from storage for a given key.
     * Uses native JSON parsing for better performance.
     */
    getObject: <T>(key: string, callback?: (error: any, value: T | undefined | null) => void) => T | null | undefined;
    /**
     * Set an Object to storage for the given key asynchronously.
     *
     * This method stringifies the object on the JS side and stores it.
     * Functionally equivalent to setMapAsync but with a more intuitive name.
     */
    setObjectAsync(key: string, value: object): Promise<boolean | null | undefined>;
    /**
     * Get an Object from storage for the given key asynchronously.
     * Functionally equivalent to getMapAsync but with a more intuitive name.
     */
    getObjectAsync<T>(key: string): Promise<T | null | undefined>;
    /**
     * Universal method to store any JavaScript object (including arrays)
     * Uses native JSON stringification
     *
     * @param key The key to store the value under
     * @param value Any JavaScript value (object or array)
     * @returns Operation success
     */
    setUniversalObject: (key: string, value: any) => boolean | undefined;
    /**
     * Universal method to retrieve any stored JavaScript object (including arrays)
     * Uses native JSON parsing for better performance
     *
     * @param key The key to retrieve
     * @returns The stored value (object or array)
     */
    getUniversalObject: <T>(key: string, callback?: (error: any, value: T | undefined | null) => void) => T | null | undefined;
    /**
     * Async version of setUniversalObject
     */
    setUniversalObjectAsync(key: string, value: any): Promise<boolean | null | undefined>;
    /**
     * Async version of getUniversalObject
     */
    getUniversalObjectAsync<T>(key: string): Promise<T | null | undefined>;
    /**
     * Retrieve multiple items for the given array of keys with native JSON parsing.
     * This method uses native code for JSON parsing which is more efficient.
     */
    getMultipleItemsNative: <T>(keys: string[], type: DataType | "map") => [string, T][];
    /**
     * Retrieve multiple items for the given array of keys with native JSON parsing asynchronously.
     * This method uses native code for JSON parsing which is more efficient.
     */
    getMultipleItemsNativeAsync: <T>(keys: string[], type: DataType | "map") => Promise<[string, T][]>;
}
//# sourceMappingURL=mmkvinstance.d.ts.map